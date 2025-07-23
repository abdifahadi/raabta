import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {RtcTokenBuilder, RtcRole} from "agora-token";

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

// Agora configuration
const AGORA_APP_ID = "4bfa94cebfb04852951bfdf9858dbc4b";
const AGORA_APP_CERTIFICATE = "8919043495b3435fba0ab1aa2973f29b";

interface AgoraTokenRequest {
  channelName: string;
  uid?: number;
  role?: "publisher" | "subscriber";
  expirationTime?: number;
}

interface AgoraTokenResponse {
  rtcToken: string;
  uid: number;
  channelName: string;
  appId: string;
  expirationTime: number;
}

export const generateAgoraToken = functions.https.onCall(
  async (data: AgoraTokenRequest, context) => {
    try {
      const {channelName, uid, role = "publisher", expirationTime} = data;

      // Validate input
      if (!channelName || typeof channelName !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Channel name is required and must be a string"
        );
      }

      // Validate channel name format (Agora requirements)
      if (channelName.length === 0 || channelName.length > 64) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Channel name must be between 1 and 64 characters"
        );
      }

      // Channel name must only contain alphanumeric characters, underscores, and hyphens
      if (!/^[a-zA-Z0-9_-]+$/.test(channelName)) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Channel name must only contain alphanumeric characters, underscores, and hyphens"
        );
      }

      // Generate UID if not provided (must be positive 32-bit integer)
      const finalUid = uid || Math.floor(Math.random() * 2147483647) + 1;

      // Validate UID range
      if (finalUid <= 0 || finalUid > 2147483647) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "UID must be a positive integer less than or equal to 2^31-1"
        );
      }

      // Set expiration time (default: 3600 seconds, max: 24 hours for security)
      const expirationTimeInSeconds = expirationTime || 3600;
      
      if (expirationTimeInSeconds <= 0 || expirationTimeInSeconds > 86400) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Expiration time must be between 1 and 86400 seconds (24 hours)"
        );
      }

      const currentTimestamp = Math.floor(Date.now() / 1000);
      const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

      // Determine role
      const agoraRole = role === "subscriber" ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER;

      // Generate token using the agora-token library
      const token = RtcTokenBuilder.buildTokenWithUid(
        AGORA_APP_ID,
        AGORA_APP_CERTIFICATE,
        channelName,
        finalUid,
        agoraRole,
        privilegeExpiredTs,
        privilegeExpiredTs
      );

      const response: AgoraTokenResponse = {
        rtcToken: token,
        uid: finalUid,
        channelName: channelName,
        appId: AGORA_APP_ID,
        expirationTime: privilegeExpiredTs,
      };

      functions.logger.info("Agora token generated successfully", {
        userId: context.auth?.uid,
        channelName: channelName,
        uid: finalUid,
        role: role,
        expirationTime: privilegeExpiredTs,
        tokenLength: token.length
      });

      return response;
    } catch (error) {
      functions.logger.error("Error generating Agora token", {
        error: error,
        userId: context.auth?.uid,
        data: data,
      });

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate Agora token",
        { originalError: error instanceof Error ? error.message : "Unknown error" }
      );
    }
  }
);

/**
 * HTTP endpoint version for direct REST API calls
 */
export const generateAgoraTokenHttp = functions.https.onRequest(async (req, res) => {
  // Handle CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const data: AgoraTokenRequest = req.body;
    
    // Call the same logic as the callable function
    const result = await generateAgoraToken.run(data, {
      auth: null,
      rawRequest: req
    } as any);
    
    res.status(200).json(result);
  } catch (error) {
    functions.logger.error('HTTP endpoint error:', error);
    
    if (error instanceof functions.https.HttpsError) {
      res.status(400).json({
        error: error.message,
        code: error.code
      });
    } else {
      res.status(500).json({
        error: 'Internal server error'
      });
    }
  }
});