#!/bin/bash

# Deploy Supabase Edge Functions for Raabta Agora Token Service
# This script deploys the generate-agora-token function to Supabase

echo "🚀 Starting Supabase Edge Function deployment..."

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI is not installed. Please install it first:"
    echo "   npm install -g supabase"
    echo "   or visit: https://supabase.com/docs/guides/cli"
    exit 1
fi

# Check if we're logged in to Supabase
if ! supabase projects list &> /dev/null; then
    echo "❌ Not logged in to Supabase. Please login first:"
    echo "   supabase login"
    exit 1
fi

# Deploy the function
echo "📦 Deploying generate-agora-token function..."
supabase functions deploy generate-agora-token --project-ref qrtutnrcynfceshsngph

if [ $? -eq 0 ]; then
    echo "✅ Function deployed successfully!"
    echo ""
    echo "🔗 Function URL: https://qrtutnrcynfceshsngph.supabase.co/functions/v1/generate-agora-token"
    echo ""
    echo "📝 Test the function with:"
    echo "curl -X POST 'https://qrtutnrcynfceshsngph.supabase.co/functions/v1/generate-agora-token' \\"
    echo "  -H 'Content-Type: application/json' \\"
    echo "  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFydHV0bnJjeW5mY2VzaHNuZ3BoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNDA4MDMsImV4cCI6MjA2ODgxNjgwM30.TsnPqlCaTLKAVL32ygDv_sR71AEtLw1pJGHezmBeDBA' \\"
    echo "  -d '{\"channelName\": \"test-channel\", \"uid\": 12345}'"
else
    echo "❌ Function deployment failed!"
    exit 1
fi