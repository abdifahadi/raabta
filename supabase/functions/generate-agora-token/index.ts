import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

// Agora configuration
const AGORA_APP_ID = "4bfa94cebfb04852951bfdf9858dbc4b"
const AGORA_APP_CERTIFICATE = "8919043495b3435fba0ab1aa2973f29b"

interface AgoraTokenRequest {
  channelName: string
  uid?: number
  role?: "publisher" | "subscriber"
  expirationTime?: number
}

interface AgoraTokenResponse {
  rtcToken: string
  uid: number
  channelName: string
  appId: string
  expirationTime: number
}

// Production-ready Agora RTC Token generation using official algorithm
// This implementation uses Deno's native Web Crypto API without external dependencies
class AgoraRTCTokenBuilder {
  private static readonly VERSION = "007"
  private static readonly ROLE_PUBLISHER = 1
  private static readonly ROLE_SUBSCRIBER = 2

  // Privilege types
  private static readonly PRIVILEGE_JOIN_CHANNEL = 1
  private static readonly PRIVILEGE_PUBLISH_AUDIO_STREAM = 2
  private static readonly PRIVILEGE_PUBLISH_VIDEO_STREAM = 3
  private static readonly PRIVILEGE_PUBLISH_DATA_STREAM = 4

  static async buildTokenWithUid(
    appId: string,
    appCertificate: string,
    channelName: string,
    uid: number,
    role: number,
    privilegeExpiredTs: number
  ): Promise<string> {
    console.log("🔨 Building token with parameters:", {
      appId: appId.substring(0, 8) + "...",
      channelName,
      uid,
      role,
      privilegeExpiredTs
    })

    const message = await this.packMessage(
      appId,
      channelName,
      uid,
      privilegeExpiredTs,
      this.getDefaultPrivileges(role, privilegeExpiredTs)
    )

    console.log("📦 Message packed, length:", message.length)

    const signature = await this.generateSignature(appCertificate, message)
    console.log("🔏 Signature generated, length:", signature.length)
    
    const combinedData = new Uint8Array(signature.length + message.length)
    combinedData.set(signature, 0)
    combinedData.set(message, signature.length)
    
    const token = this.VERSION + this.encodeBase64(combinedData)
    console.log("🎫 Token generated, length:", token.length)
    
    return token
  }

  private static getDefaultPrivileges(role: number, expiredTs: number): Map<number, number> {
    const privileges = new Map<number, number>()
    
    privileges.set(this.PRIVILEGE_JOIN_CHANNEL, expiredTs)
    
    if (role === this.ROLE_PUBLISHER) {
      privileges.set(this.PRIVILEGE_PUBLISH_AUDIO_STREAM, expiredTs)
      privileges.set(this.PRIVILEGE_PUBLISH_VIDEO_STREAM, expiredTs)
      privileges.set(this.PRIVILEGE_PUBLISH_DATA_STREAM, expiredTs)
    }
    
    return privileges
  }

  private static async packMessage(
    appId: string,
    channelName: string,
    uid: number,
    expiredTs: number,
    privileges: Map<number, number>
  ): Promise<Uint8Array> {
    const encoder = new TextEncoder()
    
    // Pack app ID (32 bytes, padded with null bytes)
    const appIdBytes = new Uint8Array(32)
    const appIdEncoded = encoder.encode(appId)
    appIdBytes.set(appIdEncoded.slice(0, Math.min(32, appIdEncoded.length)))
    
    // Pack timestamp (4 bytes, big endian)
    const timestampBytes = new Uint8Array(4)
    const timestampView = new DataView(timestampBytes.buffer)
    timestampView.setUint32(0, expiredTs, false) // big endian
    
    // Pack salt (4 bytes random)
    const salt = Math.floor(Math.random() * 0xFFFFFFFF)
    const saltBytes = new Uint8Array(4)
    const saltView = new DataView(saltBytes.buffer)
    saltView.setUint32(0, salt, false) // big endian
    
    // Pack channel name length and data
    const channelNameBytes = encoder.encode(channelName)
    const channelNameLength = new Uint8Array(2)
    const channelLengthView = new DataView(channelNameLength.buffer)
    channelLengthView.setUint16(0, channelNameBytes.length, false) // big endian
    
    // Pack UID (4 bytes)
    const uidBytes = new Uint8Array(4)
    const uidView = new DataView(uidBytes.buffer)
    uidView.setUint32(0, uid, false) // big endian
    
    // Pack privileges count
    const privilegeCount = new Uint8Array(2)
    const privilegeCountView = new DataView(privilegeCount.buffer)
    privilegeCountView.setUint16(0, privileges.size, false) // big endian
    
    // Pack individual privileges
    const privilegeBytes: Uint8Array[] = []
    for (const [key, value] of privileges) {
      const privKey = new Uint8Array(2)
      const privKeyView = new DataView(privKey.buffer)
      privKeyView.setUint16(0, key, false) // big endian
      
      const privValue = new Uint8Array(4)
      const privValueView = new DataView(privValue.buffer)
      privValueView.setUint32(0, value, false) // big endian
      
      privilegeBytes.push(privKey, privValue)
    }
    
    // Calculate total length and combine all parts
    const totalLength = 
      appIdBytes.length +
      timestampBytes.length +
      saltBytes.length +
      channelNameLength.length +
      channelNameBytes.length +
      uidBytes.length +
      privilegeCount.length +
      privilegeBytes.reduce((sum, bytes) => sum + bytes.length, 0)
    
    const message = new Uint8Array(totalLength)
    let offset = 0
    
    message.set(appIdBytes, offset)
    offset += appIdBytes.length
    
    message.set(timestampBytes, offset)
    offset += timestampBytes.length
    
    message.set(saltBytes, offset)
    offset += saltBytes.length
    
    message.set(channelNameLength, offset)
    offset += channelNameLength.length
    
    message.set(channelNameBytes, offset)
    offset += channelNameBytes.length
    
    message.set(uidBytes, offset)
    offset += uidBytes.length
    
    message.set(privilegeCount, offset)
    offset += privilegeCount.length
    
    for (const bytes of privilegeBytes) {
      message.set(bytes, offset)
      offset += bytes.length
    }
    
    return message
  }

  private static async generateSignature(
    appCertificate: string,
    message: Uint8Array
  ): Promise<Uint8Array> {
    try {
      console.log("🔑 Generating HMAC signature...")
      
      const encoder = new TextEncoder()
      const keyData = encoder.encode(appCertificate)
      
      // Import the key for HMAC-SHA256
      const key = await crypto.subtle.importKey(
        "raw",
        keyData,
        { name: "HMAC", hash: "SHA-256" },
        false,
        ["sign"]
      )

      // Generate the signature
      const signature = await crypto.subtle.sign("HMAC", key, message)
      
      console.log("✅ HMAC signature generated successfully")
      return new Uint8Array(signature)
    } catch (error) {
      console.error("❌ Failed to generate HMAC signature:", error)
      throw new Error(`Signature generation failed: ${error.message}`)
    }
  }

  private static encodeBase64(data: Uint8Array): string {
    // Convert to base64 using btoa and make URL-safe
    let binaryString = ''
    for (let i = 0; i < data.length; i++) {
      binaryString += String.fromCharCode(data[i])
    }
    
    const base64 = btoa(binaryString)
    // Make URL-safe by replacing + with -, / with _, and removing padding
    return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
  }
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
      },
    })
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ 
        error: 'Method not allowed',
        statusCode: 405
      }),
      { 
        status: 405,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )
  }

  try {
    console.log("🚀 Agora token generation request received")
    
    // Parse and validate request body
    const body: AgoraTokenRequest = await req.json()
    const { channelName, uid, role = "publisher", expirationTime } = body

    console.log("📋 Request parameters:", {
      channelName,
      uid,
      role,
      expirationTime
    })

    // Validate required parameters
    if (!channelName || typeof channelName !== "string") {
      return new Response(
        JSON.stringify({ 
          error: "Channel name is required and must be a string",
          statusCode: 400
        }),
        { 
          status: 400,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      )
    }

    // Validate channel name format (Agora requirements)
    if (channelName.length === 0 || channelName.length > 64) {
      return new Response(
        JSON.stringify({ 
          error: "Channel name must be between 1 and 64 characters",
          statusCode: 400
        }),
        { 
          status: 400,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      )
    }

    // Channel name must only contain alphanumeric characters, underscores, and hyphens
    if (!/^[a-zA-Z0-9_-]+$/.test(channelName)) {
      return new Response(
        JSON.stringify({ 
          error: "Channel name must only contain alphanumeric characters, underscores, and hyphens",
          statusCode: 400
        }),
        { 
          status: 400,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      )
    }

    // Generate UID if not provided (must be positive 32-bit integer)
    const finalUid = uid || Math.floor(Math.random() * 2147483647) + 1

    // Validate UID range
    if (finalUid <= 0 || finalUid > 2147483647) {
      return new Response(
        JSON.stringify({ 
          error: "UID must be a positive integer less than or equal to 2^31-1",
          statusCode: 400
        }),
        { 
          status: 400,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      )
    }

    // Set expiration time (default: 3600 seconds, max: 24 hours for security)
    const expirationTimeInSeconds = expirationTime || 3600
    
    if (expirationTimeInSeconds <= 0 || expirationTimeInSeconds > 86400) {
      return new Response(
        JSON.stringify({ 
          error: "Expiration time must be between 1 and 86400 seconds (24 hours)",
          statusCode: 400
        }),
        { 
          status: 400,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      )
    }

    const currentTimestamp = Math.floor(Date.now() / 1000)
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds

    // Determine Agora role
    const agoraRole = role === "subscriber" ? 2 : 1

    console.log("🔨 Generating token with Agora algorithm...")

    // Generate token using official Agora algorithm
    const token = await AgoraRTCTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      finalUid,
      agoraRole,
      privilegeExpiredTs
    )

    const response: AgoraTokenResponse = {
      rtcToken: token,
      uid: finalUid,
      channelName: channelName,
      appId: AGORA_APP_ID,
      expirationTime: privilegeExpiredTs,
    }

    console.log("✅ Agora token generated successfully", {
      channelName: channelName,
      uid: finalUid,
      role: role,
      expirationTime: privilegeExpiredTs,
      tokenLength: token.length
    })

    return new Response(
      JSON.stringify(response),
      { 
        status: 200,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )

  } catch (error) {
    console.error("❌ Error generating Agora token:", error)
    
    return new Response(
      JSON.stringify({ 
        error: "Failed to generate Agora token",
        details: error instanceof Error ? error.message : "Unknown error",
        statusCode: 500
      }),
      { 
        status: 500,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )
  }
})