// @ts-nocheck
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';
import { formatVnd, notifyAdmins, notifyUser, statusToVi } from '../_shared/notifications.ts';

const PAYOS_API = Deno.env.get('PAYOS_API_BASE') ?? 'https://api-merchant.payos.vn';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const payosClientId = Deno.env.get('PAYOS_CLIENT_ID');
    const payosApiKey = Deno.env.get('PAYOS_API_KEY');

    if (!supabaseUrl || !anonKey || !serviceRoleKey || !payosClientId || !payosApiKey) {
      return json({ error: 'Missing environment variables' }, 500);
    }

    // ── Parse request body ───────────────────────────────────────────────
    const body = await req.json();
    const orderCode = Number(body?.orderCode ?? 0);
    const fallbackUserId = String(body?.userId ?? '').trim();

    if (!Number.isFinite(orderCode) || orderCode <= 0) {
      return json({ error: 'Invalid orderCode' }, 400);
    }

    // ── Resolve user (JWT first, fallback userId) ───────────────────────
    const authHeader = req.headers.get('Authorization');
    const userClient = createClient(supabaseUrl, anonKey, {
      global: authHeader ? { headers: { Authorization: authHeader } } : undefined,
    });

    let resolvedUserId = '';
    if (authHeader) {
      const {
        data: { user },
        error: userError,
      } = await userClient.auth.getUser();

      if (!userError && user) {
        resolvedUserId = user.id;
      }
    }

    if (!resolvedUserId && fallbackUserId) {
      resolvedUserId = fallbackUserId;
    }

    if (!resolvedUserId) {
      return json({ error: 'Unauthorized' }, 401);
    }

    // ── Find the order in our DB ─────────────────────────────────────────
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: order, error: findError } = await adminClient
      .from('subscription_orders')
      .select('id,user_id,plan_id,plan_name,amount,plan_duration_months,is_lifetime,status,order_code')
      .eq('order_code', orderCode)
      .eq('user_id', resolvedUserId)
      .maybeSingle();

    if (findError || !order) {
      return json({ error: 'Order not found' }, 404);
    }

    // ── Already processed ────────────────────────────────────────────────
    if (order.status === 'paid') {
      const { data: profile } = await adminClient
        .from('profiles')
        .select('role,premium_expires_at')
        .eq('id', resolvedUserId)
        .maybeSingle();

      return json({
        status: 'paid',
        alreadyProcessed: true,
        premiumExpiresAt: profile?.premium_expires_at ?? null,
        isLifetime: Boolean(order.is_lifetime) || order.plan_id === 'premium_lifetime',
      });
    }

    // ── Call PayOS API to verify payment status ──────────────────────────
    const payosResponse = await fetch(`${PAYOS_API}/v2/payment-requests/${orderCode}`, {
      method: 'GET',
      headers: {
        'x-client-id': payosClientId,
        'x-api-key': payosApiKey,
      },
    });

    const payosJson = await payosResponse.json();

    if (!payosResponse.ok || payosJson?.code !== '00') {
      return json({
        status: 'pending',
        message: 'Payment not confirmed by PayOS yet',
        providerCode: payosJson?.code ?? null,
      });
    }

    const paymentStatus = String(payosJson?.data?.status ?? '').toUpperCase();
    const isPaid = paymentStatus === 'PAID';

    if (!isPaid) {
      // Payment exists but not paid yet (PENDING, CANCELLED, etc.)
      const mappedStatus = paymentStatus === 'CANCELLED' ? 'cancelled' : 'pending';

      if (mappedStatus !== order.status) {
        await adminClient
          .from('subscription_orders')
          .update({ status: mappedStatus, provider_raw: payosJson })
          .eq('id', order.id);

        const { data: profile } = await adminClient
          .from('profiles')
          .select('full_name')
          .eq('id', order.user_id)
          .maybeSingle();

        const amountLabel = formatVnd(Number(order.amount ?? 0));
        const userName = String(profile?.full_name ?? `User ${order.user_id.slice(0, 8)}`);
        const statusText = statusToVi(mappedStatus);

        await Promise.all([
          notifyUser(adminClient, order.user_id, {
            type: `payment_${mappedStatus}`,
            title: statusText,
            body: `Giao dich #${order.order_code} (${order.plan_name}) dang o trang thai: ${statusText}.`,
            metadata: {
              orderCode: order.order_code,
              planId: order.plan_id,
              planName: order.plan_name,
              amount: order.amount,
              status: mappedStatus,
            },
          }),
          notifyAdmins(adminClient, {
            type: `admin_payment_${mappedStatus}`,
            title: `Cap nhat giao dich: ${statusText}`,
            body: `${userName} - ${order.plan_name} (${amountLabel}), ma #${order.order_code}.`,
            metadata: {
              userId: order.user_id,
              userName,
              orderCode: order.order_code,
              planId: order.plan_id,
              planName: order.plan_name,
              amount: order.amount,
              status: mappedStatus,
            },
          }),
        ]);
      }

      return json({
        status: mappedStatus,
        message: `Payment status: ${paymentStatus}`,
      });
    }

    // ── Payment is PAID – grant premium ──────────────────────────────────
    const isLifetimePlan = Boolean(order.is_lifetime) || order.plan_id === 'premium_lifetime';
    const durationMonths = Number(order.plan_duration_months ?? 0);

    // Ensure a profile row exists for this user before applying premium updates.
    const { error: ensureProfileError } = await adminClient.from('profiles').upsert(
      {
        id: resolvedUserId,
        role: 'user',
      },
      { onConflict: 'id', ignoreDuplicates: true },
    );
    if (ensureProfileError) {
      return json({ error: `Ensure profile failed: ${ensureProfileError.message}` }, 500);
    }

    // Read current profile expiry to stack duration
    const { data: profileExpiry } = await adminClient
      .from('profiles')
      .select('premium_expires_at')
      .eq('id', resolvedUserId)
      .maybeSingle();

    const now = new Date();
    const currentExpiresAt = profileExpiry?.premium_expires_at
      ? new Date(profileExpiry.premium_expires_at)
      : null;
    const hasFutureExpiry = currentExpiresAt != null && currentExpiresAt.getTime() > now.getTime();
    const entitlementBase = hasFutureExpiry ? currentExpiresAt : now;

    let nextExpiresAtIso: string | null = null;
    if (!isLifetimePlan && durationMonths > 0) {
      const nextExpiresAt = addMonths(entitlementBase, durationMonths);
      nextExpiresAtIso = nextExpiresAt.toISOString();
    }

    // Update subscription order
    const { error: updateOrderError } = await adminClient
      .from('subscription_orders')
      .update({
        status: 'paid',
        paid_at: now.toISOString(),
        granted_until: nextExpiresAtIso,
        provider_raw: payosJson,
      })
      .eq('id', order.id);

    if (updateOrderError) {
      return json({ error: `Update order failed: ${updateOrderError.message}` }, 500);
    }

    // Update user profile
    const { error: updateProfileError } = await adminClient
      .from('profiles')
      .update({
        role: 'premium',
        premium_expires_at: nextExpiresAtIso,
      })
      .eq('id', resolvedUserId);

    if (updateProfileError) {
      return json({ error: `Update profile failed: ${updateProfileError.message}` }, 500);
    }

    const { data: profileName } = await adminClient
      .from('profiles')
      .select('full_name')
      .eq('id', order.user_id)
      .maybeSingle();

    const amountLabel = formatVnd(Number(order.amount ?? 0));
    const userName = String(profileName?.full_name ?? `User ${order.user_id.slice(0, 8)}`);

    await Promise.all([
      notifyUser(adminClient, order.user_id, {
        type: 'payment_paid',
        title: 'Thanh toan thanh cong',
        body: `Ban da thanh toan thanh cong don ${order.plan_name} (${amountLabel}).`,
        metadata: {
          orderCode: order.order_code,
          planId: order.plan_id,
          planName: order.plan_name,
          amount: order.amount,
          status: 'paid',
          premiumExpiresAt: nextExpiresAtIso,
          isLifetime: isLifetimePlan,
        },
      }),
      notifyAdmins(adminClient, {
        type: 'admin_payment_paid',
        title: 'Giao dich thanh cong',
        body: `${userName} vua thanh toan thanh cong goi ${order.plan_name} (${amountLabel}), ma #${order.order_code}.`,
        metadata: {
          userId: order.user_id,
          userName,
          orderCode: order.order_code,
          planId: order.plan_id,
          planName: order.plan_name,
          amount: order.amount,
          status: 'paid',
          premiumExpiresAt: nextExpiresAtIso,
          isLifetime: isLifetimePlan,
        },
      }),
    ]);

    return json({
      status: 'paid',
      alreadyProcessed: false,
      premiumExpiresAt: nextExpiresAtIso,
      isLifetime: isLifetimePlan,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unexpected server error';
    return json({ error: message }, 500);
  }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function addMonths(baseDate: Date, months: number): Date {
  const result = new Date(baseDate);
  const targetMonth = result.getUTCMonth() + months;
  result.setUTCMonth(targetMonth);
  return result;
}
