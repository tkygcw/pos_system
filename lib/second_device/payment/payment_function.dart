import 'package:pos_system/database/pos_database.dart';


class PaymentFunction {
  PosDatabase _posDatabase = PosDatabase.instance;
  PaymentFunction();

  getCompanyPaymentMethod() async {
    return await _posDatabase.readPaymentMethods();
  }
}