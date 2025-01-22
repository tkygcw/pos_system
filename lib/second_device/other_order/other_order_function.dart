import '../../database/pos_database.dart';
import '../../object/dining_option.dart';

class OtherOrderFunction {
  final PosDatabase _posDatabase = PosDatabase.instance;

  Future<List<DiningOption>> getDiningList() async{
    try{
      return await _posDatabase.readAllDiningOption();
    }catch(e){
      return [];
    }
  }
}