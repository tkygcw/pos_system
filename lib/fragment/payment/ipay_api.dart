import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';


class Api {
  final myTransformer = Xml2Json();

  static var domain = 'https://payment.ipay88.com.my/';
  static Uri gateway = Uri.parse(domain + 'ePayment/WebService/MHGatewayService/GatewayService.svc?WSDL');

  /*
  * create user
  * */
  sendPayment(String merchantCode, String merchantKey, int paymentId, String refNo, String amount, String currency, String prodDesc, String username, String userEmail,
      String userContact, String remark, String barcodeNo, String terminalId, String x_Field1, String x_Field2, String backendUrl, String signature) async {
    var MerchantCode = merchantCode;
    var MerchantKey  = merchantKey;
    var PaymentId = paymentId;
    var RefNo = refNo;
    var Amount = amount;
    var Currency = currency;
    var ProdDesc = prodDesc;
    var UserName = username;
    var UserEmail = userEmail;
    var UserContact = userContact;
    var Remark = remark;
    var BarcodeNo = barcodeNo;
    var TerminalID = terminalId;
    var xField1 = x_Field1;
    var xField2 = x_Field2;
    var BackendURL = backendUrl;
    var SignatureType = 'SHA256';
    var Signature = signature;
    print('MerchantCode api: ${MerchantCode}');
    print('MerchantKey api: ${MerchantKey}');
    print('Payment id code : ${PaymentId}');
    print('RefNo : ${RefNo}');
    print('Amount : ${Amount}');
    print('Currency : ${Currency}');
    print('ProdDesc : ${ProdDesc}');
    print('UserName : ${UserName}');
    print('UserEmail : ${UserEmail}');
    print('UserContact : ${UserContact}');
    print('Remark : ${Remark}');
    print('BarcodeNo : ${BarcodeNo}');
    print('TerminalID: ${TerminalID}');
    print('xField1: ${xField1}');
    print('xField2: ${xField2}');
    print('BackendURL: ${BackendURL}');
    print('SignatureType: ${SignatureType}');
    print('Signature: ${Signature}');



    // var xmlstring = '<?xml version="1.0" encoding="utf-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:mob="https://www.mobile88.com" xmlns:mhp="http://schemas.datacontract.org/2004/07/MHPHGatewayService.Model"><soapenv:Header/><soapenv:Body><mob:EntryPageFunctionality><mob:requestModelObj><mhp:Amount>1.00</mhp:Amount><mhp:BackendURL></mhp:BackendURL><mhp:BarcodeNo></mhp:BarcodeNo><mhp:Currency>MYR</mhp:Currency><mhp:MerchantCode>M15137</mhp:MerchantCode><mhp:PaymentId>336</mhp:PaymentId><mhp:ProdDesc>cool product</mhp:ProdDesc><mhp:RefNo>abc1</mhp:RefNo><mhp:Remark>testing</mhp:Remark><mhp:Signature>7dc95d825028af2379d3d2fd04b7707bbe123571a57810e243841302a50b3c24</mhp:Signature><mhp:SignatureType>SHA256</mhp:SignatureType><mhp:TerminalID></mhp:TerminalID><mhp:UserContact>01110956891</mhp:UserContact><mhp:UserEmail>yong9746@hotmail.com</mhp:UserEmail><mhp:UserName>yong</mhp:UserName><mhp:xfield1></mhp:xfield1><mhp:xfield2></mhp:xfield2></mob:requestModelObj></mob:EntryPageFunctionality></soapenv:Body></soapenv:Envelope>';

    var xmlstring = '<?xml version="1.0" encoding="utf-8"?>'
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:mob="https://www.mobile88.com" xmlns:mhp="http://schemas.datacontract.org/2004/07/MHPHGatewayService.Model">'
        '<soapenv:Header/>'
        '<soapenv:Body>'
        '<mob:EntryPageFunctionality>'
        '<mob:requestModelObj>'
        '<mhp:Amount>$Amount</mhp:Amount>'
        '<mhp:BackendURL>$BackendURL</mhp:BackendURL>'
        '<mhp:BarcodeNo>$BarcodeNo</mhp:BarcodeNo>'
        '<mhp:Currency>$Currency</mhp:Currency>'
        '<mhp:MerchantCode>$MerchantCode</mhp:MerchantCode>'
        '<mhp:PaymentId>$PaymentId</mhp:PaymentId>'
        '<mhp:ProdDesc>$ProdDesc</mhp:ProdDesc>'
        '<mhp:RefNo>$RefNo</mhp:RefNo>'
        '<mhp:Remark>$Remark</mhp:Remark>'
        ' <mhp:Signature>$Signature</mhp:Signature>'
        '<mhp:SignatureType>$SignatureType</mhp:SignatureType>'
        '<mhp:TerminalID>$TerminalID</mhp:TerminalID>'
        '<mhp:UserContact>$UserContact</mhp:UserContact>'
        '<mhp:UserEmail>$UserEmail</mhp:UserEmail>'
        '<mhp:UserName>$UserName</mhp:UserName>'
        '<mhp:xfield1>$xField1</mhp:xfield1>'
        '<mhp:xfield2>$xField2</mhp:xfield2>'
        '</mob:requestModelObj>'
        '</mob:EntryPageFunctionality>'
        ' </soapenv:Body>'
        '</soapenv:Envelope>';

    http.Response response = await http.post(
        gateway,
        headers: {
          "Accept-Encoding": "gzip,deflate",
          "Content-Type": "text/xml;charset=UTF-8",
          "SOAPAction": "https://www.mobile88.com/IGatewayService/EntryPageFunctionality",
          "Host": "payment.ipay88.com.my",


          //"Accept": "text/xml"
        },
        body: xmlstring);

    var rawXmlResponse = response.body;
    myTransformer.parse(rawXmlResponse);
    var jsonXml = myTransformer.toBadgerfish(useLocalNameForNodes: true);
    Map xmlObject = jsonDecode(jsonXml);
    var errorDesc = xmlObject['Envelope']['Body']['EntryPageFunctionalityResponse']['EntryPageFunctionalityResult']['ErrDesc']['\$'];




// Use the xml package's 'parse' method to parse the response.
//     xml.XmlDocument parsedXml = xml.parse(rawXmlResponse);
//     Fluttertoast.showToast(msg: 'result');
    print("DATAResult: " + response.body);
    print('json format xml: ${jsonXml}');
    print('json in body: ${xmlObject['Envelope']['Body']['EntryPageFunctionalityResponse']['EntryPageFunctionalityResult']['ErrDesc']['\$']}');

    return errorDesc;
  }

}
