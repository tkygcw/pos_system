import 'package:flutter/material.dart';
import 'package:pos_system/fragment/category/category_dialog.dart';
import 'package:pos_system/object/colorCode.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/categories.dart';
import '../../page/progress_bar.dart';

class CategorySetting extends StatefulWidget {
  const CategorySetting({Key? key}) : super(key: key);

  @override
  _CategorySettingState createState() => _CategorySettingState();
}

class _CategorySettingState extends State<CategorySetting> {
  List<Categories> categoryList = [];
  bool isLoading = true;

  @override
  void initState() {
    readAllCategories();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return isLoading
          ? CustomProgressBar()
          : Scaffold(
              body: Container(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 0, 0),
                            child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    primary: color.backgroundColor),
                                onPressed: () async {
                                  openEditCategoryDialog(Categories());
                                },
                                icon: Icon(Icons.add),
                                label: Text(AppLocalizations.of(context)!.translate('category'))),
                          ),
                          SizedBox(width: MediaQuery.of(context).size.height > 500 ? 544 : 150),
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                searchCategories(value);
                              },
                              decoration: InputDecoration(
                                contentPadding:
                                    EdgeInsets.fromLTRB(10, 10, 10, 10),
                                isDense: true,
                                border: InputBorder.none,
                                labelText: AppLocalizations.of(context)!.translate('search'),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.grey, width: 2.0),
                                  borderRadius: BorderRadius.circular(25.0),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      Expanded(
                          child: categoryList.length != 0
                              ? ListView.builder(
                                  padding: const EdgeInsets.all(10),
                                  shrinkWrap: true,
                                  itemCount: categoryList.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return ListTile(
                                        onTap: () {
                                          openEditCategoryDialog(
                                              categoryList[index]);
                                        },
                                        leading: CircleAvatar(
                                          backgroundColor: HexColor(
                                              categoryList[index].color!),
                                        ),
                                        trailing: Text(
                                          (categoryList[index].item_sum)
                                                  .toString() +
                                              ' Items',
                                          style: TextStyle(
                                              color: Colors.grey, fontSize: 18),
                                        ),
                                        title: Text(
                                          categoryList[index].name!,
                                          style: TextStyle(fontSize: 18),
                                        ));
                                  })
                              : Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 100),
                                  child: Center(
                                      child: Text(
                                    'No Category Found',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey),
                                  )),
                                )),
                    ],
                  ),
                ),
              ),
            );
    });
  }
  Future<Future<Object?>> openEditCategoryDialog(Categories categories) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: CategoryDialog(
                  callBack: () => readAllCategories(),
                  category: categories,
                )),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          return null!;
        });
  }

  readAllCategories() async {
    List<Categories> data = await PosDatabase.instance.readCategories();
    setState(() {
      categoryList = data;
      isLoading = false;
    });
  }

  searchCategories(String name) async {
    List<Categories> data = await PosDatabase.instance.searchCategories(name);
    setState(() {
      categoryList = data;
    });
  }
}
