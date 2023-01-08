import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../provider/global_color.dart';
import '../../provider/global_language.dart';

/// Shows a modal material design bottom sheet.
Future<String?> showModalFitBottomSheet(BuildContext context, {required List<SheetItem> list, bool showCancel = true,}) async {
  return await showMaterialModalBottomSheet<String>(
    backgroundColor:Colors.transparent,
    context: context,
    builder: (context){
      return ModalFit(items:list, showCancel:showCancel);
    },
  );
}

class SheetItem{
  /// icon ?
  String title;
  String key;
  SheetItem({required this.title, required this.key});
}

class ModalFit extends StatelessWidget {

  final List<SheetItem> items;
  final bool showCancel;

  const ModalFit({Key? key, required this.items, this.showCancel = true}) : super(key: key);

  Widget itemWidget({required BuildContext context, required SheetItem item, Function()? onTap, bool showLine = true}){
    var colors =  C.current(context,listen: false);
    // var language = L.current(context,listen: false);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: colors.bgOnBody_1,
        child: Container(
          padding: const EdgeInsets.only(top: 10,bottom: 10),
          width: double.infinity,
          decoration: showLine ? BoxDecoration(border:Border(bottom:BorderSide(width: 0.5,color: colors.tintSeparator_2))) : null,
          child: Center(
            child: Text(item.title, style: TextStyle(fontSize: F.f18,color: colors.tintPrimary),),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context,listen: false);
    var language = L.current(context,listen: false);
    return ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),//circular(10),
        child: Material(
      // color: Colors.transparent,
      color:colors.bgOnBody_1,
      child: SafeArea(
        top: false,
        child: Container(
            color: colors.bgOnBody_2,
            child:Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ...items.map((e){
                  return itemWidget(context:context, item:e, onTap:(){
                    Navigator.of(context).pop(e.key);
                  }, showLine: e.key != items.last.key);
                }),
                if(showCancel)
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  child: itemWidget(context:context, item:SheetItem(title: language.cancel, key: 'cancel'), showLine: false, onTap:(){
                    Navigator.of(context).pop();
                  }),
                )
              ],
            )
          )
        ),
      )
    );
  }
}
