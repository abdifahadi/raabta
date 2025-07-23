# Raabta App: Firebase to Supabase Migration Guide

## Overview

This guide documents the migration from Firebase Cloud Functions to Supabase Edge Functions for Agora RTC token generation in the Raabta Flutter app.

## What Changed

### Backend (Server-side)
- **Removed**: Firebase Cloud Functions (`functions/src/index.ts`)
- **Added**: Supabase Edge Function (`supabase/functions/generate-agora-token/index.ts`)
- **New URL**: `https://qrtutnrcynfceshsngph.supabase.co/functions/v1/generate-agora-token`

### Frontend (Flutter App)
- **Removed**: `cloud_functions` dependency from `pubspec.yaml`
- **Updated**: `AgoraTokenService` to use HTTP requests instead of Firebase callable functions
- **Added**: Direct HTTP POST requests using the `http` package
- **Improved**: Error handling and logging

## Key Benefits

1. **Better Performance**: Supabase Edge Functions run on Deno runtime with faster cold starts
2. **Reduced Dependencies**: No need for Firebase Cloud Functions package
3. **Cost Effective**: Supabase Edge Functions have generous free tier
4. **Modern Stack**: Built on Web Standards (Web Crypto API, Fetch API)
5. **Better Security**: Proper CORS handling and request validation

## Security Features

### Token Generation
- Uses HMAC-SHA256 for cryptographic signing
- Validates channel name length (1-64 characters)
- Validates UID range (1 to 2^31-1)
- Enforces maximum token expiration (24 hours)
- Proper error handling for invalid inputs

### API Security
- CORS protection for cross-origin requests
- Content-Type validation
- Rate limiting (handled by Supabase)
- Authentication via Supabase anon key

## API Specification

### Endpoint
```
POST https://qrtutnrcynfceshsngph.supabase.co/functions/v1/generate-agora-token
```

### Headers
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer <SUPABASE_ANON_KEY>",
  "apikey": "<SUPABASE_ANON_KEY>"
}
```

### Request Body
```json
{
  "channelName": "string",    // Required: 1-64 characters
  "uid": "number",           // Optional: 1 to 2^31-1, auto-generated if not provided
  "role": "string",          // Optional: "publisher" or "subscriber", defaults to "publisher"
  "expirationTime": "number" // Optional: seconds, defaults to 3600 (1 hour), max 86400 (24 hours)
}
```

### Response (Success - 200)
```json
{
  "rtcToken": "string",
  "uid": "number",
  "channelName": "string",
  "appId": "string",
  "expirationTime": "number"
}
```

### Response (Error - 400/500)
```json
{
  "error": "string",
  "statusCode": "number"
}
```

## Agora Configuration

### App Credentials
- **App ID**: `4bfa94cebfb04852951bfdf9858dbc4b`
- **Primary Certificate**: `8919043495b3435fba0ab1aa2973f29b`
- **Token Expiry**: 3600 seconds (1 hour) by default

### Supported Features
- One-to-one voice/video calling
- Publisher/Subscriber roles
- Secure token generation
- Automatic UID generation
- Channel-specific tokens

## Platform Compatibility

The new implementation works across all platforms:
- ✅ Android
- ✅ iOS  
- ✅ Web
- ✅ Windows
- ✅ Linux
- ✅ macOS

## Error Handling

### Common Errors
1. **Invalid Channel Name**: Returns 400 with descriptive message
2. **Invalid UID**: Returns 400 with validation details
3. **Token Expiration Too Long**: Returns 400 for > 24 hours
4. **Network Issues**: Graceful fallback to development mode in debug builds
5. **Server Errors**: Proper error propagation with status codes

### Fallback Mechanism
In development mode (`kDebugMode = true`), the app falls back to insecure mode (empty token) if Supabase function fails. This ensures development continuity while maintaining production security.

## Deployment

### Prerequisites
1. Supabase CLI installed: `npm install -g supabase`
2. Authenticated with Supabase: `supabase login`

### Deploy Function
```bash
# Make script executable
chmod +x deploy_supabase_functions.sh

# Run deployment
./deploy_supabase_functions.sh
```

### Manual Deployment
```bash
supabase functions deploy generate-agora-token --project-ref qrtutnrcynfceshsngph
```

## Testing

### Test Function Directly
```bash
curl -X POST 'https://qrtutnrcynfceshsngph.supabase.co/functions/v1/generate-agora-token' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFydHV0bnJjeW5mY2VzaHNuZ3BoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNDA4MDMsImV4cCI6MjA2ODgxNjgwM30.TsnPqlCaTLKAVL32ygDv_sR71AEtLw1pJGHezmBeDBA' \
  -d '{"channelName": "test-channel", "uid": 12345}'
```

### Test in Flutter App
1. Run the app in debug mode
2. Initiate a call
3. Check debug logs for token generation success
4. Verify call connection works properly

## Migration Checklist

- [x] Remove Firebase Cloud Functions dependency
- [x] Remove Firebase Functions imports
- [x] Update AgoraTokenService to use HTTP requests
- [x] Create Supabase Edge Function
- [x] Implement proper token generation algorithm
- [x] Add comprehensive error handling
- [x] Add CORS support for web platform
- [x] Update token expiration to 1 hour default
- [x] Add input validation
- [x] Create deployment scripts
- [x] Update documentation

## Support

For issues related to:
- **Agora Integration**: Check token generation logs and network connectivity
- **Supabase Functions**: Verify function deployment and API keys
- **Flutter Implementation**: Check debug logs for detailed error messages

## Production Considerations

1. **Monitor Function Performance**: Use Supabase dashboard to track function execution times
2. **Rate Limiting**: Implement client-side rate limiting to prevent abuse
3. **Token Caching**: Consider caching tokens on client side until near expiration
4. **Error Monitoring**: Implement proper error tracking and alerting
5. **Backup Strategy**: Consider implementing multiple token generation endpoints for redundancy

## Security Best Practices

1. **Never expose Supabase service key** - Only use anon key on client side
2. **Validate all inputs** - Both client and server side validation
3. **Use HTTPS only** - All communication must be encrypted
4. **Rotate credentials regularly** - Update Agora and Supabase credentials periodically
5. **Monitor usage** - Track token generation patterns for anomalies