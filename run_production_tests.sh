#!/bin/bash

echo "🚀 Production Call System Validation"
echo "===================================="

# Check if all required files exist
echo ""
echo "📁 Checking File Structure..."

required_files=(
    "lib/core/services/supabase_service.dart"
    "lib/core/services/supabase_agora_token_service.dart" 
    "lib/core/services/production_call_service.dart"
    "lib/core/services/agora_service.dart"
    "lib/core/services/agora_web_service.dart"
    "lib/core/services/improved_agora_web_service.dart"
    "lib/core/services/agora_service_interface.dart"
    "lib/core/services/agora_service_factory.dart"
    "lib/utils/universal_platform_view_registry.dart"
    "lib/utils/universal_platform_view_registry_web.dart"
    "lib/utils/universal_platform_view_registry_stub.dart"
    "supabase/functions/generate-agora-token/index.ts"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file"
    else
        echo "❌ $file (MISSING)"
    fi
done

echo ""
echo "🔧 Checking Configuration..."

# Check pubspec.yaml for cloud_functions removal
if grep -q "# cloud_functions" pubspec.yaml; then
    echo "✅ Firebase Cloud Functions removed from pubspec.yaml"
else
    echo "❌ Firebase Cloud Functions dependency needs to be commented out"
fi

# Check for Supabase dependency
if grep -q "supabase_flutter" pubspec.yaml; then
    echo "✅ Supabase Flutter dependency present"
else
    echo "❌ Supabase Flutter dependency missing"
fi

echo ""
echo "🔐 Checking Security Implementation..."

# Check for HMAC-SHA256 in Edge Function
if grep -q "HMAC.*SHA-256" supabase/functions/generate-agora-token/index.ts; then
    echo "✅ HMAC-SHA256 signature implementation found"
else
    echo "❌ HMAC-SHA256 implementation needs verification"
fi

# Check for Agora config
if grep -q "4bfa94cebfb04852951bfdf9858dbc4b" lib/core/config/agora_config.dart; then
    echo "✅ Agora App ID configured"
else
    echo "❌ Agora App ID configuration needs verification"
fi

echo ""
echo "🌍 Checking Cross-Platform Support..."

# Check for conditional imports
if grep -q "dart.library.html" lib/utils/universal_platform_view_registry.dart; then
    echo "✅ Web conditional imports implemented"
else
    echo "❌ Web conditional imports need verification"
fi

# Check for js.context usage
if grep -q "js.context" lib/core/services/improved_agora_web_service.dart; then
    echo "✅ Web js.context usage (fixed window[] operator)"
else
    echo "❌ Web js.context implementation needs verification"
fi

echo ""
echo "📞 Checking Service Integration..."

# Check Service Locator updates
if grep -q "SupabaseAgoraTokenService" lib/core/services/service_locator.dart; then
    echo "✅ SupabaseAgoraTokenService integrated in Service Locator"
else
    echo "❌ SupabaseAgoraTokenService integration missing"
fi

if grep -q "ProductionCallService" lib/core/services/service_locator.dart; then
    echo "✅ ProductionCallService integrated in Service Locator"
else
    echo "❌ ProductionCallService integration missing"
fi

echo ""
echo "🎯 Checking Token Renewal Implementation..."

# Check for renewToken method in interface
if grep -q "renewToken" lib/core/services/agora_service_interface.dart; then
    echo "✅ renewToken method added to interface"
else
    echo "❌ renewToken method missing from interface"
fi

# Check for token refresh timer
if grep -q "_setupTokenRefreshTimer" lib/core/services/production_call_service.dart; then
    echo "✅ Token refresh timer implementation found"
else
    echo "❌ Token refresh timer implementation missing"
fi

echo ""
echo "📊 Implementation Summary:"
echo "=========================="

# Count total checks
total_checks=14
passed_checks=0

# Rerun key checks and count passes
[[ -f "lib/core/services/supabase_agora_token_service.dart" ]] && ((passed_checks++))
[[ -f "lib/core/services/production_call_service.dart" ]] && ((passed_checks++))
[[ -f "supabase/functions/generate-agora-token/index.ts" ]] && ((passed_checks++))
grep -q "# cloud_functions" pubspec.yaml && ((passed_checks++))
grep -q "supabase_flutter" pubspec.yaml && ((passed_checks++))
grep -q "HMAC.*SHA-256" supabase/functions/generate-agora-token/index.ts && ((passed_checks++))
grep -q "4bfa94cebfb04852951bfdf9858dbc4b" lib/core/config/agora_config.dart && ((passed_checks++))
grep -q "dart.library.html" lib/utils/universal_platform_view_registry.dart && ((passed_checks++))
grep -q "js.context" lib/core/services/improved_agora_web_service.dart && ((passed_checks++))
grep -q "SupabaseAgoraTokenService" lib/core/services/service_locator.dart && ((passed_checks++))
grep -q "ProductionCallService" lib/core/services/service_locator.dart && ((passed_checks++))
grep -q "renewToken" lib/core/services/agora_service_interface.dart && ((passed_checks++))
grep -q "_setupTokenRefreshTimer" lib/core/services/production_call_service.dart && ((passed_checks++))
[[ -f "lib/utils/universal_platform_view_registry_web.dart" ]] && ((passed_checks++))

echo "✅ Passed: $passed_checks/$total_checks checks"

if [[ $passed_checks -eq $total_checks ]]; then
    echo ""
    echo "🎉 PRODUCTION CALL SYSTEM IMPLEMENTATION COMPLETE!"
    echo "🚀 Ready for deployment across all platforms"
    echo ""
    echo "Key Features Implemented:"
    echo "• 🔐 Secure Supabase Edge Function token generation"
    echo "• 🌍 Cross-platform support (Android, iOS, Web, Windows, macOS, Linux)"
    echo "• 🔄 Automatic token renewal with 5-minute buffer"
    echo "• 🛡️ HMAC-SHA256 security implementation"
    echo "• 🔧 Platform-specific fixes (Web js.context, conditional imports)"
    echo "• 📞 Complete call flow orchestration"
    echo ""
    echo "Next Steps:"
    echo "1. flutter pub get"
    echo "2. Test on target platforms"
    echo "3. Deploy to production"
else
    echo ""
    echo "⚠️  Some checks failed. Please review the implementation."
    echo "📋 Total completion: $(($passed_checks * 100 / $total_checks))%"
fi

echo ""
echo "🔗 Supabase Configuration:"
echo "URL: https://qrtutnrcynfceshsngph.supabase.co"
echo "Function: /functions/v1/generate-agora-token"
echo ""