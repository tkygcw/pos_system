import 'package:collection/collection.dart';

import '../database/pos_database.dart';
import '../object/order_cache.dart';
import '../object/table.dart';
import '../object/table_use_detail.dart';

class TableFunction {
  List<PosTable> tableList = [];
  List<PosTable> initialTableList = [];

  readAllTable() async {
    tableList = await PosDatabase.instance.readAllTable();
    //for compare purpose
    initialTableList = await PosDatabase.instance.readAllTable();

    //table number sorting
    sortTable();

    await readAllTableGroup();
  }

  sortTable(){
    tableList.sort((a, b) {
      final aNumber = a.number!;
      final bNumber = b.number!;

      bool isANumeric = int.tryParse(aNumber) != null;
      bool isBNumeric = int.tryParse(bNumber) != null;

      if (isANumeric && isBNumeric) {
        return int.parse(aNumber).compareTo(int.parse(bNumber));
      } else if (isANumeric) {
        return -1; // Numeric before alphanumeric
      } else if (isBNumeric) {
        return 1; // Alphanumeric before numeric
      } else {
        // Custom alphanumeric sorting logic
        return compareNatural(aNumber, bNumber);
      }
    });
  }

  readAllTableGroup() async {
    double tableAmount = 0.0;
    bool hasTableInUse = tableList.any((item) => item.status == 1);
    if(hasTableInUse){
      for (int i = 0; i < tableList.length; i++) {
        if(tableList[i].status == 1){
          List<TableUseDetail> tableUseDetailData = await PosDatabase.instance.readSpecificInUsedTableUseDetail(tableList[i].table_sqlite_id!);
          if (tableUseDetailData.isNotEmpty) {
            List<OrderCache> data = await PosDatabase.instance.readTableOrderCache(tableUseDetailData[0].table_use_key!);
            if(data.isNotEmpty){
              tableList[i].group = data[0].table_use_sqlite_id;
              tableList[i].card_color = data[0].card_color;
              for(int j = 0; j < data.length; j++){
                tableAmount += double.parse(data[j].total_amount!);
              }
              tableList[i].total_amount = tableAmount.toStringAsFixed(2);
            }
          }
        }
      }
    }
  }
}