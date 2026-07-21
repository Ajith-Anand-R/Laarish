// File generated for Firebase configuration matching battery-iot-67338
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
        return ios;
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.linux:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyALM8k2feW_J27N3w22ragVE5X_-8AhE-o',
    appId: '1:186388879740:web:422c4b711e6ea7e82f6cf9',
    messagingSenderId: '186388879740',
    projectId: 'battery-iot-67338',
    authDomain: 'battery-iot-67338.firebaseapp.com',
    databaseURL: 'https://battery-iot-67338-default-rtdb.firebaseio.com',
    storageBucket: 'battery-iot-67338.firebasestorage.app',
    measurementId: 'G-YQ4ZKHM025',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDF_o5O-YsL_FnHynBTjDSwWsqDs2YPsZg',
    appId: '1:186388879740:android:5d8e5dc7232db4072f6cf9',
    messagingSenderId: '186388879740',
    projectId: 'battery-iot-67338',
    databaseURL: 'https://battery-iot-67338-default-rtdb.firebaseio.com',
    storageBucket: 'battery-iot-67338.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDF_o5O-YsL_FnHynBTjDSwWsqDs2YPsZg',
    appId: '1:186388879740:ios:hb76cndbfb8sjm7lkdve1nflib3vaatj',
    messagingSenderId: '186388879740',
    projectId: 'battery-iot-67338',
    databaseURL: 'https://battery-iot-67338-default-rtdb.firebaseio.com',
    storageBucket: 'battery-iot-67338.firebasestorage.app',
    iosBundleId: 'com.laarish.laarishapp',
  );
}
