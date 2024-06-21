import 'package:flutter/material.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/translation/AppLocalizations.dart';

class AdvancedTableView extends StatefulWidget {
  final int position;
  final PosTable table;
  final int tableLength;
  final List<PosTable> tableList;
  final CartModel cart;
  final Function(String, bool) callBack;
  final bool editingMode;

  const AdvancedTableView(
      {Key? key,
        required this.position,
        required this.table,
        required int this.tableLength,
        required List<PosTable> this.tableList,
        required this.callBack,
        required this.cart,
        required this.editingMode,
      })
      : super(key: key);

  @override
  State<AdvancedTableView> createState() => _AdvancedTableViewState();
}

class _AdvancedTableViewState extends State<AdvancedTableView> {
  late Offset _position = getPosition();
  double sizeCard = 120;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: () {
          widget.callBack('on_tap', !widget.table.isSelected);
        },

        onDoubleTap: () {
          if(!widget.editingMode){
            if (widget.table.status == 1)
              widget.callBack('on_double_tap', true);
          }
        },

        onPanUpdate: (details) {
          if (widget.editingMode) {
            setState(() {
              _position += details.delta;
              if (_position.dy <= 0) {
                _position = Offset(_position.dx, 0);
              }
              if (_position.dx <= 0) {
                _position = Offset(0, _position.dy);
              }
              // container width
              if(MediaQuery.of(context).size.width >= 1390) {
                if (_position.dx >= 845) {
                  _position = Offset(845, _position.dy);
                }
              }
              else {
                if (_position.dx >= 767) {
                  _position = Offset(767, _position.dy);
                }
              }
              // container scroll height
              if (_position.dy >= MediaQuery.of(context).size.height*1.4) {
                _position = Offset(_position.dx, MediaQuery.of(context).size.height*1.4);
              }

              widget.table.dx = _position.dx.toString();
              widget.table.dy = _position.dy.toString();
            });
          }
        },
        child: Card(
          color: widget.table.status == 1 && widget.table.order_key != '' && widget.table.order_key != null ? Color(0xFFFE8080)
            :widget.table.isSelected ? Colors.grey[300] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          elevation: 4,
          child: Stack(
            alignment: Alignment.center,

            children: [
              Visibility(
                visible: widget.table.group != null && MediaQuery.of(context).size.height > 500 && !widget.editingMode,
                child: Positioned(
                  top: 5,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: widget.table.group != null && MediaQuery.of(context).size.height > 500 ? toColor(widget.table.card_color!) : Colors.white,
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.translate('group') + ": ${widget.table.group}",
                      style: TextStyle(
                        fontSize: 18,
                        color: fontColor(posTable: widget.table),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: sizeCard,
                height: sizeCard,
                child: Center(child: Text(widget.table.number!)),
              ),
              Visibility(
                visible: MediaQuery.of(context).size.height > 500 && !widget.editingMode,
                child: Positioned(
                  bottom: 5,
                  child: Container(
                    child: Text(
                      "RM ${widget.table.total_amount ?? '0.00'} ",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Offset getPosition() {
    if (widget.table.dx != '' && widget.table.dy != '') {
      double parsedDx = double.tryParse(widget.table.dx!) ?? 0.0;
      double parsedDy = double.tryParse(widget.table.dy!) ?? 0.0;
      _position = Offset(parsedDx, parsedDy);
    } else {
      double dx = MediaQuery.of(context).size.width >= 1390 ? 845 : 767;
      double dy = 0;
      _position = Offset(dx, dy);
    }
    return _position;
  }

  toColor(String hex) {
    var hexColor = hex.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  }

  fontColor({required PosTable posTable}) {
    if (posTable.status == 1) {
      Color fontColor = Colors.black;
      Color backgroundColor = toColor(posTable.card_color!);
      if (backgroundColor.computeLuminance() > 0.5) {
        fontColor = Colors.black;
      } else {
        fontColor = Colors.white;
      }
      return fontColor;
    }
  }
}
