// @ts-nocheck
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

const PLAN_ALLOWLIST = new Set([
  'premium_6_months',
  'premium_1_year',
  'premium_lifetime',
]);

function getPlanDuration(planId: string): { months: number | null; isLifetime: boolean } {
  switch (planId) {
    case 'premium_6_months':
      return { months: 6, isLifetime: false };
    case 'premium_1_year':
      return { months: 12, isLifetime: false };
    case 'premium_lifetime':
      return { months: null, isLifetime: true };
    default:
      return { months: null, isLifetime: false };
  }
}

const PAYOS_API = Deno.env.get('PAYOS_API_BASE') ?? 'https://api-merchant.payos.vn';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: 'Missing Supabase environment variables' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      );
    }

    const authHeader = req.headers.get('Authorization');
    console.log('Got Authorization header:', authHeader ? authHeader.substring(0, 30) + '...' : 'NONE');

    const userClient = createClient(supabaseUrl, anonKey, {
      global: authHeader ? { headers: { Authorization: authHeader } } : undefined,
    });
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json();
    const token = authHeader?.replace(/^Bearer\s+/i, '').trim() ?? '';
    const explicitUserId = String(body?.userId ?? '').trim();

    const isServiceRoleToken = token ? isRoleInJwt(token, 'service_role') : false;
    let user: { id: string; email?: string | null; user_metadata?: Record<string, unknown> } | null = null;

    if (isServiceRoleToken) {
      const userId = String(body?.userId ?? '').trim();
      if (!userId) {
        return new Response(
          JSON.stringify({ error: 'userId is required when using service_role token' }),
          {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          },
        );
      }

      const { data: authUser, error: authUserError } = await adminClient.auth.admin.getUserById(userId);
      if (authUserError || !authUser?.user) {
        return new Response(
          JSON.stringify({ error: 'Invalid userId for payment', details: authUserError }),
          {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          },
        );
      }

      user = {
        id: authUser.user.id,
        email: authUser.user.email,
        user_metadata: authUser.user.user_metadata ?? {},
      };
    } else {
      let authedUser: { id: string; email?: string | null; user_metadata?: Record<string, unknown> } | null = null;

      if (authHeader) {
        const {
          data: { user: apiUser },
          error: userError,
        } = await userClient.auth.getUser();

        if (!userError && apiUser) {
          authedUser = {
            id: apiUser.id,
            email: apiUser.email,
            user_metadata: apiUser.user_metadata ?? {},
          };
        } else {
          console.error('Failed to verify JWT user, fallback to userId:', userError);
        }
      }

      if (!authedUser && explicitUserId) {
        const { data: authUser, error: authUserError } = await adminClient.auth.admin.getUserById(explicitUserId);
        if (!authUserError && authUser?.user) {
          authedUser = {
            id: authUser.user.id,
            email: authUser.user.email,
            user_metadata: authUser.user.user_metadata ?? {},
          };
        }
      }

      if (!authedUser) {
        return new Response(JSON.stringify({ error: 'Unauthorized', details: 'Missing valid JWT and userId fallback' }), {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      user = authedUser;
    }

    console.log('Successfully authenticated user:', user.id);

    const planId = String(body?.planId ?? '');
    const planName = String(body?.planName ?? '');
    const description = String(body?.description ?? 'Lexii Premium');
    const amount = Number(body?.amount ?? 0);

    if (!PLAN_ALLOWLIST.has(planId) || !planName || !Number.isFinite(amount) || amount <= 0) {
      return new Response(JSON.stringify({ error: 'Invalid payment payload' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const payosClientId = Deno.env.get('PAYOS_CLIENT_ID');
    const payosApiKey = Deno.env.get('PAYOS_API_KEY');
    const payosChecksumKey = Deno.env.get('PAYOS_CHECKSUM_KEY');
    const returnUrlFromRequest = String(body?.returnUrl ?? '').trim();
    const cancelUrlFromRequest = String(body?.cancelUrl ?? '').trim();
    const returnUrlBase = resolveCallbackUrl(returnUrlFromRequest, Deno.env.get('PAYOS_RETURN_URL'));
    const cancelUrlBase = resolveCallbackUrl(cancelUrlFromRequest, Deno.env.get('PAYOS_CANCEL_URL'));

    if (!payosClientId || !payosApiKey || !payosChecksumKey || !returnUrlBase || !cancelUrlBase) {
      return new Response(JSON.stringify({ error: 'Missing PayOS environment variables' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const now = Date.now();
    const orderCode = Number(String(now).slice(-9));
    const planDuration = getPlanDuration(planId);
    const returnUrl = withQueryParams(returnUrlBase, {
      status: 'success',
      orderCode: String(orderCode),
    });
    const cancelUrl = withQueryParams(cancelUrlBase, {
      status: 'cancel',
      orderCode: String(orderCode),
    });

    const signaturePayload =
      `amount=${amount}&cancelUrl=${cancelUrl}&description=${description}&orderCode=${orderCode}&returnUrl=${returnUrl}`;
    const signature = await hmacSha256(signaturePayload, payosChecksumKey);

    const payosBody = {
      orderCode,
      amount,
      description,
      returnUrl,
      cancelUrl,
      signature,
      buyerName: user.user_metadata?.full_name ?? user.email ?? 'Lexii User',
      buyerEmail: user.email ?? undefined,
      items: [
        {
          name: planName,
          quantity: 1,
          price: amount,
        },
      ],
    };

    const payosResponse = await fetch(`${PAYOS_API}/v2/payment-requests`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-client-id': payosClientId,
        'x-api-key': payosApiKey,
      },
      body: JSON.stringify(payosBody),
    });

    const payosJson = await payosResponse.json();

    if (!payosResponse.ok || payosJson?.code !== '00') {
      return new Response(
        JSON.stringify({
          error: payosJson?.desc ?? 'PayOS create payment failed',
          provider: payosJson,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      );
    }

    const data = payosJson.data ?? {};

    const { error: insertError } = await adminClient.from('subscription_orders').insert({
      user_id: user.id,
      plan_id: planId,
      plan_name: planName,
      amount,
      currency: 'VND',
      provider: 'payos',
      order_code: orderCode,
      payment_link_id: data.paymentLinkId ?? null,
      checkout_url: data.checkoutUrl ?? null,
      status: 'pending',
      plan_duration_months: planDuration.months,
      is_lifetime: planDuration.isLifetime,
      provider_raw: payosJson,
    });

    if (insertError) {
      return new Response(
        JSON.stringify({ error: `Cannot save order: ${insertError.message}` }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      );
    }

    return new Response(
      JSON.stringify({
        checkoutUrl: data.checkoutUrl,
        paymentLinkId: data.paymentLinkId,
        qrCode: data.qrCode ?? data.qr_code ?? null,
        vietQrData: data.vietQrData ?? data.viet_qr_data ?? null,
        orderCode,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unexpected server error';
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

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

function isRoleInJwt(token: string, role: string): boolean {
  try {
    const payloadRaw = token.split('.')[1];
    if (!payloadRaw) return false;

    const normalized = payloadRaw.replace(/-/g, '+').replace(/_/g, '/');
    const pad = normalized.length % 4 === 0 ? '' : '='.repeat(4 - (normalized.length % 4));
    const payloadJson = atob(normalized + pad);
    const payload = JSON.parse(payloadJson) as { role?: string };
    return payload.role === role;
  } catch (_) {
    return false;
  }
}

function withQueryParams(url: string, query: Record<string, string>): string {
  const parsed = new URL(url);
  for (const [key, value] of Object.entries(query)) {
    parsed.searchParams.set(key, value);
  }
  return parsed.toString();
}

function resolveCallbackUrl(candidate: string, fallback?: string | null): string | null {
  const fallbackValue = String(fallback ?? '').trim();

  if (candidate) {
    const parsed = safeParseUrl(candidate);
    if (parsed && isAllowedCallbackProtocol(parsed)) {
      return parsed.toString();
    }
  }

  if (!fallbackValue) {
    return null;
  }

  const parsedFallback = safeParseUrl(fallbackValue);
  if (!parsedFallback || !isAllowedCallbackProtocol(parsedFallback)) {
    return null;
  }

  return parsedFallback.toString();
}

function safeParseUrl(value: string): URL | null {
  try {
    return new URL(value);
  } catch (_) {
    return null;
  }
}

function isAllowedCallbackProtocol(url: URL): boolean {
  if (url.protocol === 'https:') {
    return true;
  }

  if (url.protocol === 'lexii:') {
    return true;
  }

  if (url.protocol === 'http:') {
    return url.hostname === 'localhost' || url.hostname === '127.0.0.1';
  }

  return false;
}
