
// TODO: Run 'flutterfire configure' to generate the real file.
// Placeholder for Firebase options
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyATKiKTsqndw9xjj505XBhoUUrr72iEpFc',
    appId: '1:673116156977:web:9b7332e67245de747a9110',
    messagingSenderId: '673116156977',
    projectId: 'project1-ea755',
    authDomain: 'project1-ea755.firebaseapp.com',
    storageBucket: 'project1-ea755.firebasestorage.app',
    measurementId: 'G-088PTQFZYD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCGR9p12PgANW-7CUwUwyWPV11uEuk_K4I',
    appId: '1:673116156977:android:50010e74ee2e58017a9110',
    messagingSenderId: '673116156977',
    projectId: 'project1-ea755',
    storageBucket: 'project1-ea755.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBcXJq9ODIs3FAMBLA1OMcScWo_GGYBMIo',
    appId: '1:673116156977:ios:a8357e930bafe80a7a9110',
    messagingSenderId: '673116156977',
    projectId: 'project1-ea755',
    storageBucket: 'project1-ea755.firebasestorage.app',
    iosBundleId: 'com.mycompany.CounterApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'placeholder',
    appId: 'placeholder',
    messagingSenderId: 'placeholder',
    projectId: 'placeholder',
    storageBucket: 'placeholder.appspot.com',
    iosBundleId: 'com.example.insightquill',
  );
} 