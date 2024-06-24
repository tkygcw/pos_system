import 'package:flutter/material.dart';
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../object/order.dart';
import '../../object/report_class.dart';
import '../../translation/AppLocalizations.dart';

class StaffSalesReport extends StatelessWidget {
  const StaffSalesReport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 8.0, left: 8.0),
      child: Scaffold(
        appBar: buildAppBar(),
        body: _ReportPart(),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0.0,
      titleSpacing: 0,
      shape: Border(
          bottom: BorderSide(
              color: Colors.grey,
              width: 1
          )
      ),
      title: Text("Staff Sales Report", style: TextStyle(fontSize: 25, color: Colors.black)),
    );
  }
}

class _ReportPart extends StatefulWidget {
  const _ReportPart({Key? key}) : super(key: key);

  @override
  State<_ReportPart> createState() => _ReportPartState();
}

class _ReportPartState extends State<_ReportPart> {
  List<DataRow> _dataRow = [];

  @override
  Widget build(BuildContext context) {
    context.watch<ReportModel>();
    return FutureBuilder(
        future: getStaffSales(),
        builder: (context, snapshot){
          if(snapshot.hasData){
            return SizedBox(
              child: _dataRow.isNotEmpty ?
              Container(
                  margin: EdgeInsets.all(10),
                  child: SingleChildScrollView(
                    child: DataTable(
                        border: TableBorder.symmetric(outside: BorderSide(color: Colors.black12)),
                        headingTextStyle: TextStyle(color: Colors.white),
                        headingRowColor: MaterialStateColor.resolveWith((states) {return Colors.black;},),
                        columns: <DataColumn>[
                          DataColumn(
                            label: Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.translate('user'),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.translate('quantity'),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.translate('total_sales'),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                        rows: _dataRow
                    ),
                  )
              ) :
              Center(
                heightFactor: 12,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu),
                    Text(AppLocalizations.of(context)!.translate('no_record_found')),
                  ],
                ),
              ),
            );
          } else {
            return CustomProgressBar();
          }
        });
  }

  preload() async {
    await getStaffSales();
  }

  getStaffSales() async {
    _dataRow.clear();
    List<Order> orderList = [];
    ReportModel model = ReportModel.instance;
    orderList = await ReportObject().getAllUserSales(currentStDate: model.startDateTime, currentEdDate: model.endDateTime);
    model.addOtherValue(valueList: orderList);
    for(final orders in orderList){
      _dataRow.addAll([
        DataRow(cells: [
          DataCell(Text(orders.close_by!)),
          DataCell(Text(orders.item_sum.toString())),
          DataCell(Text(orders.gross_sales!.toStringAsFixed(2)))
        ])
      ]);
    }
    return _dataRow;
  }
}

