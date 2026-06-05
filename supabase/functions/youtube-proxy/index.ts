import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': '*',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Verify Anon Key (Authorization: Bearer <anon_key>)
  const authHeader = req.headers.get('Authorization')
  if (authHeader !== `Bearer ${Deno.env.get('SUPABASE_ANON_KEY')}`) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const url = new URL(req.url)
    const targetUrlStr = url.searchParams.get('url')

    if (!targetUrlStr) {
      return new Response(JSON.stringify({ error: 'Missing "url" parameter' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const targetUrl = new URL(targetUrlStr)
    
    if (!targetUrl.hostname.endsWith('youtube.com') && !targetUrl.hostname.endsWith('youtu.be') && !targetUrl.hostname.endsWith('googlevideo.com')) {
      return new Response(JSON.stringify({ error: 'Only YouTube URLs are allowed' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Prepare headers for YouTube
    const requestHeaders = new Headers(req.headers)
    requestHeaders.delete('host')
    requestHeaders.delete('origin')
    requestHeaders.delete('referer')
    requestHeaders.delete('authorization')
    
    // Browsers strip the Cookie header, so we MUST inject it manually on the server
    // This bypasses the YouTube consent screen which causes "Unexpected null value"
    requestHeaders.set('Cookie', 'CONSENT=YES+cb')
    
    if (!requestHeaders.has('User-Agent')) {
      requestHeaders.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
    }

    // Forward the request to YouTube
    const fetchOptions: RequestInit = {
      method: req.method,
      headers: requestHeaders,
    }
    
    // IMPORTANT: Forward the POST body (youtube_explode uses POST for stream extraction)
    if (req.method !== 'GET' && req.method !== 'HEAD') {
      fetchOptions.body = req.body
    }

    const response = await fetch(targetUrl.toString(), fetchOptions)

    // Forward the response back to the client
    const headers = new Headers(response.headers)
    for (const [key, value] of Object.entries(corsHeaders)) {
      headers.set(key, value)
    }

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
