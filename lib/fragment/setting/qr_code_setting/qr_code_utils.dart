import 'package:pos_system/object/dynamic_qr.dart';

class QrCodeUtils {
  static final default80mmDynamicLayout = DynamicQR(
    qr_code_size: 2,
    paper_size: '80',
    footer_text: "Powered by Optimy POS"
  );

  static final default58mmDynamicLayout = DynamicQR(
      qr_code_size: 2,
      paper_size: '58',
      footer_text: "Powered by Optimy POS"
  );
}