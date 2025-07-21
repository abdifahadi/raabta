"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateAgoraToken = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const agora_token_1 = require("agora-token");
// Initialize Firebase Admin
if (!admin.apps.length) {
    admin.initializeApp();
}
// Agora configuration
const AGORA_APP_ID = "4bfa94cebfb04852951bfdf9858dbc4b";
const AGORA_APP_CERTIFICATE = "8919043495b3435fba0ab1aa2973f29b";
exports.generateAgoraToken = functions.https.onCall(async (data, context) => {
    var _a;
    // Check if user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated to generate Agora token");
    }
    try {
        const { channelName, uid, role = "publisher", expirationTime } = data;
        // Validate input
        if (!channelName || typeof channelName !== "string") {
            throw new functions.https.HttpsError("invalid-argument", "Channel name is required and must be a string");
        }
        // Generate UID if not provided
        const finalUid = uid || Math.floor(Math.random() * 2147483647);
        // Set expiration time (default: 24 hours)
        const expirationTimeInSeconds = expirationTime || 24 * 3600;
        const currentTimestamp = Math.floor(Date.now() / 1000);
        const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;
        // Determine role
        const agoraRole = role === "subscriber" ? agora_token_1.RtcRole.SUBSCRIBER : agora_token_1.RtcRole.PUBLISHER;
        // Generate token
        const token = agora_token_1.RtcTokenBuilder.buildTokenWithUid(AGORA_APP_ID, AGORA_APP_CERTIFICATE, channelName, finalUid, agoraRole, privilegeExpiredTs, privilegeExpiredTs);
        const response = {
            rtcToken: token,
            uid: finalUid,
            channelName: channelName,
            appId: AGORA_APP_ID,
            expirationTime: privilegeExpiredTs,
        };
        functions.logger.info("Agora token generated successfully", {
            userId: context.auth.uid,
            channelName: channelName,
            uid: finalUid,
        });
        return response;
    }
    catch (error) {
        functions.logger.error("Error generating Agora token", {
            error: error,
            userId: (_a = context.auth) === null || _a === void 0 ? void 0 : _a.uid,
            data: data,
        });
        throw new functions.https.HttpsError("internal", "Failed to generate Agora token");
    }
});
//# sourceMappingURL=index.js.map