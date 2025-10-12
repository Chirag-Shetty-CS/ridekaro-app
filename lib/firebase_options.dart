// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // --- Android Values from your google-services.json ---
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDwUG4zJNeU0K4_An8zHL9rJvt2rSjK0gU',
    appId: '1:475431868127:android:ee57cdccaaf7f48248bb6a',
    messagingSenderId: '475431868127',
    projectId: 'ridekaro-1d786',
    storageBucket: 'ridekaro-1d786.firebasestorage.app',
  );
}