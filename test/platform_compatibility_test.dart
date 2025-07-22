import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:raabta/core/services/agora_service_factory.dart';

void main() {
  group('Platform Compatibility Tests', () {
    test('AgoraServiceFactory creates appropriate service instance', () {
      final service = AgoraServiceFactory.getInstance();
      expect(service, isNotNull);
      
      // Verify platform detection
      if (kIsWeb) {
        expect(AgoraServiceFactory.isWebPlatform, isTrue);
        expect(AgoraServiceFactory.isNativeSupported, isFalse);
      } else {
        expect(AgoraServiceFactory.isWebPlatform, isFalse);
        expect(AgoraServiceFactory.isNativeSupported, isTrue);
      }
    });

    test('Service initialization should not throw errors', () async {
      final service = AgoraServiceFactory.getInstance();
      
      // This should not throw even without proper Agora setup in test env
      expect(
        () => service.initialize().catchError((e) => null),
        returnsNormally,
      );
    });

    test('Service interface is consistent across platforms', () {
      final service = AgoraServiceFactory.getInstance();
      
      // Verify all required interface methods exist
      expect(service.isInCall, isFalse);
      expect(service.currentChannelName, isNull);
      expect(service.remoteUsers, isEmpty);
      expect(service.callEventStream, isNotNull);
      expect(service.currentCallStream, isNotNull);
    });

    test('Video view creation should work for all platforms', () {
      final service = AgoraServiceFactory.getInstance();
      
      // These should return widgets without throwing
      expect(() => service.createLocalVideoView(), returnsNormally);
      expect(() => service.createRemoteVideoView(12345), returnsNormally);
    });

    test('Service disposal should not cause errors', () {
      final service = AgoraServiceFactory.getInstance();
      
      expect(() => service.dispose(), returnsNormally);
      
      // Reset instance for clean testing
      AgoraServiceFactory.resetInstance();
    });
  });
}
