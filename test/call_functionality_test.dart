import 'package:flutter_test/flutter_test.dart';
import 'package:raabta/core/services/agora_service_factory.dart';
import 'package:raabta/features/call/domain/models/call_model.dart';

void main() {
  group('Raabta Call System Tests', () {
    test('AgoraServiceFactory should create appropriate service instance', () {
      final agoraService = AgoraServiceFactory.getInstance();
      expect(agoraService, isNotNull);
    });

    test('Platform detection should work correctly', () {
      // Test platform detection methods
      final isWeb = AgoraServiceFactory.isWebPlatform;
      final isNative = AgoraServiceFactory.isNativeSupported;
      
      // One should be true, the other false
      expect(isWeb || isNative, isTrue);
      expect(isWeb && isNative, isFalse);
    });

    test('Service should initialize without errors', () async {
      final agoraService = AgoraServiceFactory.getInstance();
      
      // Should not throw an exception
      await expectLater(
        () async => await agoraService.initialize(),
        returnsNormally,
      );
    });

    test('Initial state should be correct', () {
      final agoraService = AgoraServiceFactory.getInstance();
      
      expect(agoraService.isInCall, isFalse);
      expect(agoraService.currentChannelName, isNull);
      expect(agoraService.remoteUsers, isEmpty);
    });

    test('Should create video views without errors', () {
      final agoraService = AgoraServiceFactory.getInstance();
      
      expect(() => agoraService.createLocalVideoView(), returnsNormally);
      expect(() => agoraService.createRemoteVideoView(12345), returnsNormally);
    });

    test('Should handle cleanup properly', () {
      final agoraService = AgoraServiceFactory.getInstance();
      
      expect(() => agoraService.dispose(), returnsNormally);
      expect(() => AgoraServiceFactory.resetInstance(), returnsNormally);
    });
  });
}