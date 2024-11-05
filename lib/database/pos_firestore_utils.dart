import 'package:pos_system/firebase_sync/sync_to_firebase.dart';

class PosFirestoreUtils {
  static SyncToFirebase _syncToFirebase = SyncToFirebase.instance;

  static void onUpgrade (int firestoreVersion, int localVersion) async {
    print("fire db version: ${firestoreVersion}");
    if (firestoreVersion < localVersion) {
      print("perform onUpgrade");
      for (int version = firestoreVersion; version <= localVersion; version++) {
        switch (version) {
          case 30: {
            //
          }break;
        }
      }
    }
  }
}