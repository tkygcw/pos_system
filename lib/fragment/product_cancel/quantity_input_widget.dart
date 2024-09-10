import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../object/cart_product.dart';
import '../../translation/AppLocalizations.dart';
import '../custom_toastification.dart';

class QuantityInputWidget extends StatefulWidget {
  final List<cartProductItem> cartItemList;
  final Function({bool? restock, num? qty}) callback;
  const QuantityInputWidget({Key? key, required this.cartItemList, required this.callback}) : super(key: key);

  @override
  State<QuantityInputWidget> createState() => _QuantityInputWidgetState();
}

class _QuantityInputWidgetState extends State<QuantityInputWidget> {
  // late final num maxQuantity;
  num simpleIntInput = 0;
  TextEditingController quantityController = TextEditingController();
  bool restock = false;

  @override
  void initState() {
    super.initState();
    simpleIntInput = 1;
    quantityController = TextEditingController(text: '${simpleIntInput}');
  }

  @override
  Widget build(BuildContext context) {
    ThemeColor color = context.watch<ThemeColor>();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // quantity input
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Cancel quantity", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                Spacer(),
                Text("Restock"),
                Checkbox(
                    value: restock,
                    onChanged: (value){
                      setState(() {
                        restock = value!;
                        widget.callback(restock: restock);
                      });
                    },
                )
              ],
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height / 2
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: widget.cartItemList.length,
              itemBuilder: (context, i){
                num maxQty = widget.cartItemList[i].unit! != 'each' && widget.cartItemList[i].unit! != 'each_c' ? 1 : widget.cartItemList[i].quantity!;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(widget.cartItemList[i].product_name!),
                  subtitle: Text('Max: $maxQty', style: TextStyle(color: Colors.redAccent)),
                  trailing: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // quantity input remove button
                            Container(
                              decoration: BoxDecoration(
                                color: color.backgroundColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.remove, color: Colors.white),
                                onPressed: () {
                                  if(simpleIntInput >= 1){
                                    setState(() {
                                      simpleIntInput -= 1;
                                      quantityController.text = simpleIntInput.toString();
                                    });
                                  } else{
                                    setState(() {
                                      simpleIntInput = 0;
                                      quantityController.text =  simpleIntInput.toString();
                                    });
                                  }
                                  widget.callback(qty: simpleIntInput);
                                },
                              ),
                            ),
                            SizedBox(width: 10),
                            // quantity input text field
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: color.backgroundColor),
                                  ),
                                ),
                                onSubmitted: (value){
                                  if((widget.cartItemList[i].unit! != 'each' && widget.cartItemList[i].unit! != 'each_c') && simpleIntInput > 1){
                                    simpleIntInput = 1;
                                    quantityController.text = simpleIntInput.toString();
                                    CustomToastification.showToastification(context: context, title: "Max $simpleIntInput");
                                  } else if (simpleIntInput > maxQty) {
                                    simpleIntInput = widget.cartItemList[i].quantity!;
                                    quantityController.text = simpleIntInput.toString();
                                    CustomToastification.showToastification(context: context, title: "Max $simpleIntInput");
                                  }
                                  widget.callback(qty: simpleIntInput);
                                },
                                onChanged: (value) => setState(() {
                                  try {
                                    simpleIntInput = int.parse(value.replaceAll(',', ''));
                                  } catch (e) {
                                    simpleIntInput = 0;
                                  }
                                  widget.callback(qty: simpleIntInput);
                                }),
                              ),
                            ),
                            SizedBox(width: 10),
                            // quantity input add button
                            Container(
                              decoration: BoxDecoration(
                                color: color.backgroundColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.add, color: Colors.white), // Set the icon color to white.
                                onPressed: () {
                                  if(simpleIntInput+1 < maxQty){
                                    setState(() {
                                      simpleIntInput += 1;
                                      quantityController.text = simpleIntInput.toString();
                                    });
                                  } else {
                                    setState(() {
                                      simpleIntInput = maxQty;
                                      quantityController.text = simpleIntInput.toString();
                                    });
                                  }
                                  widget.callback(qty: simpleIntInput);
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
