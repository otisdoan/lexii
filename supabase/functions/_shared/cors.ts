// @ts-nocheck
/**
 * Must include every header the browser may send on preflight.
 * Lexii web client sets global `Cache-Control: no-cache` on Supabase — if missing here,
 * Chrome reports a generic "CORS error" for Edge Functions.
 * @see https://github.com/supabase/supabase-js/blob/master/src/cors.ts
 */
const ALLOW_HEADERS = [
  'authorization',
  'x-client-info',
  'apikey',
  'content-type',
  'cache-control',
  'pragma',
  'x-region',
  'prefer',
  'accept',
  'accept-profile',
  'content-profile',
  'x-payos-signature',
].join(', ');

export const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': ALLOW_HEADERS,
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Max-Age': '86400',
};
