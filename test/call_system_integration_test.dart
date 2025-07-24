import 'package:flutter_test/flutter_test.dart';
import 'package:raabta/core/services/call_manager.dart';
import 'package:raabta/core/services/call_service.dart';
import 'package:raabta/core/services/agora_token_service.dart';
import 'package:raabta/features/call/domain/models/call_model.dart';

void main() {
  group('Call System Integration Tests', () {
    late CallManager callManager;
    late CallService callService;
    late AgoraTokenService tokenService;

    setUp(() {
      callManager = CallManager();
      callService = CallService();
      tokenService = AgoraTokenService();
    });

    tearDown(() {
      // Clean up after each test
      try {
        callManager.dispose();
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });

    test('should initialize call manager', () {
      expect(callManager, isNotNull);
      expect(callService, isNotNull);
      expect(tokenService, isNotNull);
    });

    test('should handle call lifecycle', () async {
      // Test basic call lifecycle without external dependencies
      expect(callManager.currentCall, isNull);
      
             // Test that the service can be accessed
       expect(callManager, isNotNull);
    });

    test('should validate call models', () {
      // Test call model creation and validation
      final now = DateTime.now();
      
      // Create a simple call model for testing
      expect(() {
        final call = CallModel(
          callId: 'test-call',
          callerId: 'caller-123', 
          receiverId: 'receiver-456',
          callType: CallType.video,
          status: CallStatus.ringing,
          channelName: 'test-channel',
          callerName: 'Test Caller',
          receiverName: 'Test Receiver',
          callerPhotoUrl: '',
          receiverPhotoUrl: '',
          createdAt: now,
        );
        
        expect(call.callId, equals('test-call'));
        expect(call.callType, equals(CallType.video));
        expect(call.status, equals(CallStatus.ringing));
      }, returnsNormally);
    });

    test('should handle service disposal', () async {
      // Test service cleanup
      expect(() => callManager.dispose(), returnsNormally);
    });

    test('should validate token service', () async {
      // Basic token service validation
      expect(tokenService, isNotNull);
      expect(() => tokenService.generateToken(
        channelName: 'test-channel',
        uid: 12345,
      ), returnsNormally);
    });
  });
}