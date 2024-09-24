import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/database/pos_firestore.dart';
import 'package:pos_system/object/branch.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncToFirebase {
  static final SyncToFirebase instance = SyncToFirebase.init();

  SyncToFirebase.init();

  syncToFirebase() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Branch? data = await PosFirestore.instance.readCurrentBranch(branch_id.toString());
    if(data == null){
      print("perform sync");
      syncBranch();
    }
  }

  syncBranch() async {
    Branch data = await PosDatabase.instance.readLocalBranch();
    PosFirestore.instance.insertBranch(data);
  }


}