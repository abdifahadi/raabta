import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Agora imports for token generation
import { RtcTokenBuilder, RtcRole } from 'https://esm.sh/agora-access-token@2.0.4'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface TokenRequest {
  channelName: string
  uid?: number
  role?: string
  expirationTime?: number
}

interface TokenResponse {
  rtcToken: string
  uid: number
  channelName: string
  appId: string
  expirationTime: number
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify authentication
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    // Create Supabase client for auth verification
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Verify user is authenticated
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) {
      throw new Error('Unauthorized')
    }

    // Parse request body
    const requestData: TokenRequest = await req.json()
    const { channelName, uid, role = 'publisher', expirationTime = 3600 } = requestData

    // Validate required parameters
    if (!channelName) {
      throw new Error('Channel name is required')
    }

    // Get Agora credentials from environment
    const appId = Deno.env.get('AGORA_APP_ID')
    const appCertificate = Deno.env.get('AGORA_APP_CERTIFICATE')

    if (!appId || !appCertificate) {
      throw new Error('Agora credentials not configured')
    }

    // Generate UID if not provided
    const finalUid = uid || Math.floor(Math.random() * 2147483647) + 1

    // Calculate expiration timestamp
    const currentTimestamp = Math.floor(Date.now() / 1000)
    const expireTimestamp = currentTimestamp + expirationTime

    // Determine Agora role
    const agoraRole = role === 'audience' ? RtcRole.AUDIENCE : RtcRole.PUBLISHER

    // Generate Agora RTC token
    const rtcToken = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      finalUid,
      agoraRole,
      expireTimestamp
    )

    // Log successful token generation (for debugging)
    console.log(`Token generated for user ${user.id}, channel: ${channelName}, uid: ${finalUid}`)

    // Prepare response
    const response: TokenResponse = {
      rtcToken,
      uid: finalUid,
      channelName,
      appId,
      expirationTime: expireTimestamp,
    }

    return new Response(
      JSON.stringify(response),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
        status: 200,
      }
    )

  } catch (error) {
    console.error('Error generating token:', error)
    
    return new Response(
      JSON.stringify({
        error: error.message || 'Internal server error',
        details: 'Failed to generate Agora token'
      }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
        status: error.message === 'Unauthorized' ? 401 : 500,
      }
    )
  }
})

/* 
Environment Variables Required:
- AGORA_APP_ID: Your Agora App ID
- AGORA_APP_CERTIFICATE: Your Agora App Certificate  
- SUPABASE_URL: Your Supabase project URL
- SUPABASE_ANON_KEY: Your Supabase anonymous key

Deploy Command:
supabase functions deploy generate-agora-token

Test Command:
curl -i --location --request POST 'https://your-project.supabase.co/functions/v1/generate-agora-token' \
  --header 'Authorization: Bearer YOUR_USER_JWT_TOKEN' \
  --header 'Content-Type: application/json' \
  --data '{
    "channelName": "test-channel",
    "role": "publisher",
    "expirationTime": 3600
  }'
*/