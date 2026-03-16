// @ts-nocheck
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const checksumKey = Deno.env.get('PAYOS_CHECKSUM_KEY');

    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: 'Missing Supabase environment variables' }, 500);
    }

    // ── Signature verification ───────────────────────────────────────────
    const rawBody = await req.text();
    const incomingSignature = (req.headers.get('x-payos-signature') ?? '').trim();

    // Webhook must be verified by signature because verify_jwt is disabled
    // for this endpoint so that PayOS can call it directly.
    if (checksumKey) {
      if (!incomingSignature) {
        return json({ error: 'Missing signature' }, 401);
      }

      const expectedSignature = await hmacSha256(rawBody, checksumKey);
      if (incomingSignature !== expectedSignature) {
        return json({ error: 'Invalid signature' }, 403);
      }
    }

    const payload = JSON.parse(rawBody);
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const eventData = payload?.data ?? {};
    const orderCode = Number(eventData.orderCode ?? 0);
    const status = String(eventData.status ?? '').toUpperCase();

    if (!Number.isFinite(orderCode) || orderCode <= 0) {
      return json({ error: 'Invalid order code' }, 400);
    }

    const isPaid = status === 'PAID';

    const { data: order, error: findError } = await adminClient
      .from('subscription_orders')
      .select('id,user_id,plan_id,plan_duration_months,is_lifetime')
      .eq('order_code', orderCode)
      .maybeSingle();

    if (findError || !order) {
      return json({ error: 'Order not found' }, 404);
    }

    const { error: updateOrderError } = await adminClient
      .from('subscription_orders')
      .update({
        status: isPaid ? 'paid' : 'failed',
        paid_at: isPaid ? new Date().toISOString() : null,
        provider_raw: payload,
      })
      .eq('id', order.id);

    if (updateOrderError) {
      return json({ error: `Update order failed: ${updateOrderError.message}` }, 500);
    }

    if (isPaid) {
      // Ensure a profile row exists for this user before applying premium updates.
      const { error: ensureProfileError } = await adminClient.from('profiles').upsert(
        {
          id: order.user_id,
          role: 'user',
        },
        { onConflict: 'id', ignoreDuplicates: true },
      );

      if (ensureProfileError) {
        return json({ error: `Ensure profile failed: ${ensureProfileError.message}` }, 500);
      }

      const { data: profile, error: profileError } = await adminClient
        .from('profiles')
        .select('premium_expires_at')
        .eq('id', order.user_id)
        .maybeSingle();

      if (profileError) {
        return json({ error: `Load profile failed: ${profileError.message}` }, 500);
      }

      const now = new Date();
      const currentExpiresAt = profile?.premium_expires_at
        ? new Date(profile.premium_expires_at)
        : null;

      const hasFutureExpiry = currentExpiresAt != null && currentExpiresAt.getTime() > now.getTime();
      const entitlementBase = hasFutureExpiry ? currentExpiresAt : now;

      const isLifetimePlan = Boolean(order.is_lifetime) || order.plan_id === 'premium_lifetime';
      const durationMonths = Number(order.plan_duration_months ?? 0);

      let nextExpiresAtIso: string | null = null;
      if (!isLifetimePlan && durationMonths > 0) {
        const nextExpiresAt = addMonths(entitlementBase, durationMonths);
        nextExpiresAtIso = nextExpiresAt.toISOString();
      }

      const { error: updateProfileError } = await adminClient
        .from('profiles')
        .update({
          role: 'premium',
          premium_expires_at: nextExpiresAtIso,
        })
        .eq('id', order.user_id);

      if (updateProfileError) {
        return json({ error: `Update profile failed: ${updateProfileError.message}` }, 500);
      }

      const { error: updateGrantedUntilError } = await adminClient
        .from('subscription_orders')
        .update({ granted_until: nextExpiresAtIso })
        .eq('id', order.id);

      if (updateGrantedUntilError) {
        return json({ error: `Update granted_until failed: ${updateGrantedUntilError.message}` }, 500);
      }
    }

    return json({ ok: true });
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

async function hmacSha256(message: string, secret: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(message));
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}
