import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve((req) => {
  const url = new URL(req.url);

  // The confirmation link from Supabase appends auth parameters (?code=... for PKCE or ?access_token=... for implicit)
  // We MUST preserve these when redirecting to the app so the Supabase SDK can log the user in.
  const authParams = url.search;

  const redirectUrl = `io.supabase.flutter://callback${authParams}`;

  return new Response(null, {
    status: 302,
    headers: {
      "Location": redirectUrl,
    },
  })
})
