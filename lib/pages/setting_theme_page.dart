import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/provider/setting_model.dart';
import 'package:provider/provider.dart';

import '../provider/global_color.dart';
import '../provider/global_language.dart';
import 'package:dropdown_search/dropdown_search.dart';

class SettingThemePage extends StatefulWidget {

  const SettingThemePage({Key? key}) : super(key: key);

  @override
  _SettingThemePageState createState() => _SettingThemePageState();
}

class _SettingThemePageState extends State<SettingThemePage> with WidgetsBindingObserver{

  List<L> allLanguage = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  dispose(){
    super.dispose();
  }

  Widget themeItem(String type){
    var language = L.current(context);
    var colors =  C.current(context);
    var typeName = type == 'light' ? language.theme_light : type == 'dark' ? language.theme_dark : language.theme_auto;
    var checkImage = type == 'dark' ? 'static/images/theme_check_light.svg' : 'static/images/theme_check_dark.svg';
    String imagePath = type == 'light' ? 'static/images/theme_light.svg' : type == 'dark' ? 'static/images/theme_dark.svg' : 'static/images/theme_all.svg';
    bool isSelect = Provider.of<SettingModel>(context, listen:true).theme == type;
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: (){ Provider.of<SettingModel>(context, listen:false).switchTheme(type); },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              border: Border.all(color: colors.tintSeparator_2, width: isSelect ? 2 : 0),),
            child: Stack(
              children: [
                SvgPicture.asset(imagePath),
                if(isSelect)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: SvgPicture.asset(checkImage)
                  )
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 10),
          child: Text(typeName, style: TextStyle(fontSize: F.f16, color: colors.tintPrimary)),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    return Scaffold(
      appBar: AppBar( //导航栏
        titleSpacing:0,
        title: Text(language.display_and_language, style: TextStyle(fontSize: F.f20,color: colors.tintPrimary,fontWeight: FontWeight.w500),),
        leading: IconButton(
          onPressed: () { Navigator.pop(context); },
          icon: SvgPicture.asset('static/images/back_arrow.svg',color: colors.tintPrimary,),
        ),
        backgroundColor: colors.bgBodyBase_1,
        elevation: 0.5,
      ),
      backgroundColor: colors.bgBodyBase_1,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 10, top: 15),
                  child: Text(language.appearance, style: TextStyle(fontSize: F.f16, color: colors.tintPrimary),),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    themeItem('light'),
                    themeItem('dark'),
                    themeItem('auto'),
                  ],
                ),
                const SizedBox(height: 10,),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 10, top: 15),
                  child: Text(language.language, style: TextStyle(fontSize: F.f16, color: colors.tintPrimary),),
                ),
                DropdownSearch<L>(
                  asyncItems: (String? filter) => getData(filter, context),

                  popupProps: PopupPropsMultiSelection.dialog(
                    fit: FlexFit.loose,
                    showSelectedItems: true,
                    itemBuilder: _customLanguageItemBuilder,
                    constraints: const BoxConstraints(minWidth: 500, maxWidth: 500, maxHeight: 500,),
                    containerBuilder:(context, popupWidget){ return Container(color: colors.bgOnBody_1, child: popupWidget,); }
                  ),
                  compareFn: (item, sItem) => item.exPath == sItem.exPath,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(filled: true, fillColor: colors.bgOnBody_2, border:InputBorder.none,),
                  ),
                  dropdownBuilder:(context, selectedItem){ //
                    return Text(selectedItem?.exPath == 'auto' ? language.language_auto : selectedItem?.exName ?? '', style: TextStyle(fontSize: F.f16, color: colors.tintPrimary),);
                  },
                  dropdownButtonProps: DropdownButtonProps(color:colors.tintSecondary),
                  selectedItem: language,
                  onChanged: (value){
                    if(value != null){
                      Provider.of<SettingModel>(context, listen:false).switchLanguage(value);
                    }else{
                      Provider.of<SettingModel>(context, listen:false).switchLanguage(L.autoEmpty());
                    }
                  },
                ),
              ],
            )
          )
        )
      )
    );
  }

  Widget _customLanguageItemBuilder(BuildContext context, L? item, bool isSelected,) {
    if(item == null){ return Container(); }
    var colors =  C.current(context);
    var language = L.current(context);
    var name = item.exPath == 'auto' ? language.language_auto : item.exName ?? '';
    return Container(
      color: !isSelected ? colors.bgOnBody_1 : null,
      decoration: !isSelected ? null : BoxDecoration(border: Border.all(color: colors.tintPicBorder), color: colors.bgOnBody_2,),
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          ListTile(
            selected: isSelected,
            title: Text(name, style: TextStyle(color: colors.tintPrimary, fontSize: F.f16),),
          ),
          if(isSelected)
          Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 15),
            child: SvgPicture.asset('static/images/theme_check_dark.svg', color: colors.tintPrimary,),
          )
        ],
      ),
    );
  }

  Future<List<L>> getData(filter,BuildContext context) async {
    if(allLanguage.isNotEmpty){ return allLanguage; }
    allLanguage = await L.loadAll(context);
    return allLanguage;
  }
}
