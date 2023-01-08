
import 'package:flutter/material.dart';
import 'package:treediary/provider/setting_model.dart';
import 'package:provider/provider.dart';

class C{
  bool isLight = true;
  // 填充颜色
  Color tintGitYellow = const Color(0xFF12A152); //#FFFFD001  // 12A152
  Color tintGitBlue = const Color(0xFF009BE0);
  Color tintSuccess = const Color(0xFF12A152);
  Color tintError = const Color(0xFFD0472F);
  Color tintWarming = const Color(0xFFFF8A01); // 搜索结果高亮
  Color tintPrimary = const Color(0xFF333333); // 1级染色：tab icon、重要文字
  Color tintSecondary = const Color(0xFF808080); // 2级染色：动态搜索icon、次要文字
  Color tintTertiary = const Color(0xFFBFBFBF); // 3级染色：列表的向右箭头、辅助文字
  Color tintSeparator = const Color(0xFFDBDBDB); // body上分割线
  Color tintSeparator_2 = const Color(0xFFDBDBDB); // on_body上分割线
  Color tintPlaceholder = const Color(0xFFDBDBDB); // placeholder
  Color tintPicBorder = const Color(0x0D000000); // 图片的描边色
  Color tintIconGray = const Color(0xFF999999);  //

  // 背景色
  Color bgGitYellow = const Color(0xFF12A152); // 按钮背景
  Color bgGitBlue = const Color(0xFF009BE0); // 按钮背景
  Color bgError = const Color(0xFFD0472F); // 警告、突出的背景色
  Color bgSelectedBlue = const Color(0x1A03A9F4); // 选中蓝
  Color bgBodyBase_1 = const Color(0xFFFFFFFF); // 最底层背景1号色
  Color bgBodyBase_2 = const Color(0xFFF0F3F5); // 最底层背景2号色
  Color bgBody_1 = const Color(0xFFFFFFFF); // 主体层1号色
  Color bgBody_2 = const Color(0xFFFAFAFA); // 主体层2号色
  Color bgOnBody_1 = const Color(0xFFFFFFFF); // 主体层之上的1号色：个人主页卡片背景
  Color bgOnBody_2 = const Color(0xFFF0F3F5); // 主体层之上的2号色：输入框、圈子、信息流卡片链接等背景
  Color bgOnBody_3 = const Color(0xFFFAFAFA); // 主体层之上的3号色：toast提示背景色
  Color bgPopover = const Color(0xD91A1A1A); // 主体层之上的3号色：弹出在内容上的控件背景色
  Color bgMask = const Color(0x4D000000); // 遮盖所有主体层级的蒙版
  Color bgSurfaceBase_1 = const Color(0xFFFFFFFF); // 最底层悬浮背景1号色
  Color bgSurfaceBody_1 = const Color(0xFFF0F3F5); // 主体层悬浮背景1号色
  Color bgSurfaceBody_2 = const Color(0xFFEBEBEB); // 主体层悬浮背景2号色

  // 固定色
  Color solidWhite_1 = const Color(0xFFFFFFFF); // 用于图片、蒙层、按钮和黑色主题上的染色
  Color solidWhite_2 = const Color(0xCCFFFFFF); // 用于图片、蒙层上的染色，边框按钮的边框
  Color solidWhite_3 = const Color(0x80FFFFFF); // 用于图片、蒙层上的染色，边框按钮的边框
  Color solidSeparator = const Color(0x33FFFFFF); // 用于图片上的分割线、边框按钮的染色
  Color solidGray_1 = const Color(0xFFDBDBDB); // 用于黑色主题上的染色
  Color solidGray_2 = const Color(0xFFBFBFBF); // 用于黑色主题上的染色
  Color solidGray_3 = const Color(0xFF808080); // 用于有色按钮上的文字图标、黑色主题上的染色
  Color solidGray_4 = const Color(0xFF333333); // 用于有色按钮上的文字图标、黑色主题上的染色
  Color solidBgBlackTransparent = const Color(0x26000000);
  Color solidBgPrimary_1 = const Color(0xFF1A1A1A);
  Color solidBgSecondaryHighlight = const Color(0x1AFFFFFF);
  Color solidLabelWhite = const Color(0x33FFFFFF);

  static C light(){ return C(); }
  static C dark(){
    C d = C();
    // 填充颜色
    d.isLight = false;
    d.tintGitYellow = const Color(0xFF12A152);
    d.tintGitBlue = const Color(0xFF009BE0);
    d.tintSuccess = const Color(0xFF12A152);
    d.tintError = const Color(0xFFD0472F);
    d.tintWarming = const Color(0xFFFF8A01); // 搜索结果高亮
    d.tintPrimary = const Color(0xFFDBDBDB); // 1级染色：tab icon、重要文字
    d.tintSecondary = const Color(0xFFBFBFBF); // 2级染色：动态搜索icon、次要文字
    d.tintTertiary = const Color(0xFF808080); // 3级染色：列表的向右箭头、辅助文字
    d.tintSeparator = const Color(0xFF333333); // body上分割线
    d.tintSeparator_2 = const Color(0xFF4B4B4B); // on_body上分割线
    d.tintPlaceholder = const Color(0xFF333333); // placeholder
    d.tintPicBorder = const Color(0x1AFFFFFF); // 图片的描边色
    d.tintIconGray = const Color(0xFF999999);  //

    // 背景色
    d.bgGitYellow = const Color(0xFF12A152); // 按钮背景
    d.bgGitBlue = const Color(0xFF009BE0); // 按钮背景
    d.bgError = const Color(0xFFD0472F); // 警告、突出的背景色
    d.bgSelectedBlue = const Color(0x2603A9F4); // 选中蓝
    d.bgBodyBase_1 = const Color(0xFF0F0F0F); // 最底层背景1号色
    d.bgBodyBase_2 = const Color(0xFF0F0F0F); // 最底层背景2号色
    d.bgBody_1 = const Color(0xFF1A1A1A); // 主体层1号色
    d.bgBody_2 = const Color(0xFF0F0F0F); // 主体层2号色
    d.bgOnBody_1 = const Color(0xFF333333); // 主体层之上的1号色：个人主页卡片背景
    d.bgOnBody_2 = const Color(0xFF262626); // 主体层之上的2号色：输入框、圈子、信息流卡片链接等背景
    d.bgOnBody_3 = const Color(0xFF262626); // 主体层之上的3号色：toast提示背景色
    d.bgPopover = const Color(0xE64B4B4B); // 主体层之上的3号色：弹出在内容上的控件背景色
    d.bgMask = const Color(0x80000000); // 遮盖所有主体层级的蒙版
    d.bgSurfaceBase_1 = const Color(0xFF333333); // 最底层悬浮背景1号色
    d.bgSurfaceBody_1 = const Color(0xFF333333); // 主体层悬浮背景1号色
    d.bgSurfaceBody_2 = const Color(0xFF333333); // 主体层悬浮背景2号色
    return d;
  }

  static C current(BuildContext context, {bool listen = true}){
    var colors =  Provider.of<SettingModel>(context, listen:listen).c;
    return colors;
  }

}

class F{

  static double feed = 15;

  static double f12 = 12;
  static double f14 = 14;
  static double f16 = 16;
  static double f18 = 18;
  static double f20 = 20;

  static FontWeight regular = FontWeight.w400;
  static FontWeight medium = FontWeight.w500;
  static FontWeight bold = FontWeight.w700;

}
