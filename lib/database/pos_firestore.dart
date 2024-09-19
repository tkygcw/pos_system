import 'package:cloud_firestore/cloud_firestore.dart';

class PosFirestore{
  static final PosFirestore instance = PosFirestore.init();
  static FirebaseFirestore _db = FirebaseFirestore.instance;

  PosFirestore.init();

  FirebaseFirestore get database => _db;

  readDataFromCloud() async {
    await database.collection("tb_product").get().then((event) {
      for (var doc in event.docs) {
        print("${doc.id} => ${doc.data()}");
      }
    });
  }
}