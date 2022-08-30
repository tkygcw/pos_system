
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/variant_group.dart';

class cartProductItem{
   String name ='';
   String price ='';
   int quantity = 1;
   late List<ModifierGroup> modifier ;
   late List<VariantGroup> variant ;
   String remark='';

   cartProductItem(String name, String price, int quantity, List<ModifierGroup> modifier, List<VariantGroup> variant, String remark){
       this.name = name;
       this.price = price;
       this.quantity = quantity;
       this.modifier = modifier;
       this.variant = variant;
       this.remark = remark;
   }

}