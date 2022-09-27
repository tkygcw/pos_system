
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/variant_group.dart';

class cartProductItem{
   String branchProduct_id = '';
   String name ='';
   String category_id = '';
   String price ='';
   int quantity = 1;
   late List<ModifierGroup> modifier ;
   late List<VariantGroup> variant ;
   String remark='';

   cartProductItem(String branchProduct_id, String name, String category_id, String price, int quantity, List<ModifierGroup> modifier, List<VariantGroup> variant, String remark){
       this.branchProduct_id = branchProduct_id;
       this.name = name;
       this.category_id = category_id;
       this.price = price;
       this.quantity = quantity;
       this.modifier = modifier;
       this.variant = variant;
       this.remark = remark;
   }

}