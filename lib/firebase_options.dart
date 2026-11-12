// File generated for Easy Queue Business using google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbwQTOa765nI25T9GR2xf86hi14PmtDXI',
    appId: '1:274807226246:android:9974ccb628dcd23cbc3607',
    messagingSenderId: '274807226246',
    projectId: 'easyqueue-prod',
    storageBucket: 'easyqueue-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCbwQTOa765nI25T9GR2xf86hi14PmtDXI',
    appId: '1:274807226246:ios:9974ccb628dcd23cbc3607',
    messagingSenderId: '274807226246',
    projectId: 'easyqueue-prod',
    storageBucket: 'easyqueue-prod.firebasestorage.app',
    iosBundleId: 'in.mahato.easyqueue.business',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCbwQTOa765nI25T9GR2xf86hi14PmtDXI',
    appId: '1:274807226246:ios:9974ccb628dcd23cbc3607',
    messagingSenderId: '274807226246',
    projectId: 'easyqueue-prod',
    storageBucket: 'easyqueue-prod.firebasestorage.app',
    iosBundleId: 'in.mahato.easyqueue.business',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCbwQTOa765nI25T9GR2xf86hi14PmtDXI',
    appId: '1:274807226246:web:9974ccb628dcd23cbc3607',
    messagingSenderId: '274807226246',
    projectId: 'easyqueue-prod',
    storageBucket: 'easyqueue-prod.firebasestorage.app',
  );
}
