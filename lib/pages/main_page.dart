import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:flutter_pickers/time_picker/model/date_mode.dart';
import 'package:flutter_pickers/time_picker/model/pduration.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/repo/note_info.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pickers/pickers.dart';

import '../config/global_data.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../provider/global_model.dart';
import '../provider/repo_list_model.dart';
import '../utils/event_bus.dart';
import '../widgets/edit_tags.dart';
import '../widgets/main_list_item.dart';
import '../widgets/viewer/empty_viewer.dart';

class MainPage extends StatefulWidget {

  static String forceRefresh = "forceRefresh"; // 强制刷新


  const MainPage({Key? key}) : super(key: key);

  @override
  MainPageState createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {

  // 列表
  List<NoteInfo> notes = [];
  int pageNum = 1;

  /// 当前刷新参数,old参数
  String oldRepoKey = '';
  String oldSearchFilter = '';
  String oldTimeFilter = '';
  bool oldTimeSortDesc = true;
  List<String> oldTagFilter = [];

  /// 为空的时候，不展示搜索框
  String? homeSearchFilter;
  PDuration? homeTimeFilter;
  bool homeTimeSortDesc = true;

  final FocusNode _focusNode = FocusNode();
  late EasyRefreshController _refreshController;
  final TextEditingController _textController = TextEditingController();

  // 初始化
  @override
  void initState() {
    super.initState();
    Bus.on('mainPageRefresh', (changeValue){  // changeValue: {NoteInfo? old, NoteInfo? new}  用于增删后通知首页刷新
      _tryRefresh(changeValue);
    });
    Bus.on(MainPage.forceRefresh, (args){  // changeValue: {NoteInfo? old, NoteInfo? new}
      // print('MainPage.forceRefresh');
      // Future.delayed(Duration(seconds: 1),(){_callRefresh(forced: true);});
      _callRefresh(forced: true);
    });
    Bus.on(Global.busRepoDidChange, (arg) {
      if(arg is RepoModel){ if(!arg.isDiary){ return; } }
      _callRefresh(forced: true);
    });
    Bus.on(Global.busHomeSearchDidClick, (arg) {
      setState(() {
        if(homeSearchFilter == null){
          homeSearchFilter = '';
        }else{
          homeSearchFilter = null;
        }
      });
      _callRefresh();
    });
    Bus.on(Global.busHomeTimeDidClick, (arg) {
      setState(() {
        if(homeTimeFilter == null){
          homeTimeFilter = PDuration();
          homeTimeSortDesc = true;
        }else{
          homeTimeFilter = null;
          homeTimeSortDesc = true;
        }
      });
      _callRefresh();
    });
    _refreshController = EasyRefreshController(controlFinishLoad: true, controlFinishRefresh: true);
  }

  @override
  void dispose() {
    super.dispose();
    Bus.off('mainPageRefresh');
    Bus.off(MainPage.forceRefresh);
    Bus.off(Global.busRepoDidChange);
    Bus.off(Global.busHomeSearchDidClick);
    Bus.off(Global.busHomeTimeDidClick);
    _refreshController.dispose();
  }
  /// 增删改通知首页刷新
  _tryRefresh(Map<String, NoteInfo?>? changeValue){
    if(changeValue != null){
      NoteInfo? newNote = changeValue['new'];
      NoteInfo? oldNote = changeValue['old'];
      if(newNote == null && oldNote != null){ // 删除
        notes.remove(oldNote);
        setState(() { notes = notes; });
      }else  if(newNote != null && oldNote != null){ // 改
        int oldIndex = notes.indexOf(oldNote);
        notes.remove(oldNote);
        notes.insert(oldIndex, newNote);
        setState(() { notes = notes; });
      }else{
        _refreshController.callRefresh();
      }
    }else{
      _refreshController.callRefresh();
    }
  }
  /// 执行刷新，如果前后刷新参数未发生改变，则不执行刷新，减少重复刷新
  _callRefresh({bool forced = false}){
    _focusNode.unfocus();
    if(forced){
      _refreshController.callRefresh();
      return;
    }
    /// 用现有参数与old参数对比，如果没有变化，则不刷新
    String newSearchFilter = homeSearchFilter ?? '';
    String newTimeFilter = '';
    bool newTimeSortDesc = true;
    List<String> newTagFilter = Provider.of<GlobalModel>(context, listen:false).homeTagFilter ?? [];
    if(homeTimeFilter != null){
      newTimeSortDesc = homeTimeSortDesc;
      int y = homeTimeFilter!.year ?? 0;
      int m = homeTimeFilter!.month ?? 0;
      int d = homeTimeFilter!.day ?? 0;
      if(y > 0 && m > 0 && d > 0){
        try{
          String timeStr = '${homeTimeFilter!.year.toString().padLeft(4,'0')}-${homeTimeFilter!.month.toString().padLeft(2,'0')}-${homeTimeFilter!.day.toString().padLeft(2,'0')} 23:59:59';
          var _strTimes = DateTime.parse(timeStr);
          var _intendTime = _strTimes.millisecondsSinceEpoch;
          newTimeFilter = _intendTime.toString(); // 时间戳
        }catch(e){
          debugPrint(e.toString());
        }
      }
    }
    if(oldSearchFilter == newSearchFilter && oldTimeFilter == newTimeFilter && oldTimeSortDesc == newTimeSortDesc && oldTagFilter.length == newTagFilter.length){
      var difList = oldTagFilter.where((element) => !newTagFilter.contains(element));
      if(difList.isEmpty){
        if (kDebugMode) { print('不需要刷新'); }
        return;
      }
    }
    _refreshController.callRefresh();
  }

  Widget? _searchItem(){
    var colors =  C.current(context);
    var language = L.current(context);
    var searchKey = homeSearchFilter;
    if(searchKey == null){ return null; }
    return Container(
      padding: const EdgeInsets.only(left: 10,bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                padding: const EdgeInsets.only(left: 10,top: 5,bottom: 5,right: 10),
                color: colors.bgOnBody_2,
                child: Row(
                  children: [
                    SvgPicture.asset('static/images/home_search.svg',width: 24,height: 24,color: colors.tintPrimary,),
                    const SizedBox(width: 5,),
                    Expanded(
                      child: TextField(
                        focusNode: _focusNode,
                        controller: _textController,
                        onChanged:(value){ setState(() { homeSearchFilter = value; }); },
                        onSubmitted: (value) {
                          _callRefresh();
                          // Future.delayed(const Duration(milliseconds: 500),(){ _callRefresh(); }); // 延迟500毫秒再执行刷新，不然可能会出现刷新异常
                        },
                        decoration: InputDecoration.collapsed(
                          hintText: language.enter_the_search_content,
                          hintStyle:TextStyle(fontSize: 17, color: colors.tintPlaceholder),
                        ),
                        style:TextStyle(fontSize: 17,color: colors.tintPrimary),
                        autofocus: true,
                      )
                    )
                  ]
                )
              )
            )
          ),
          GestureDetector(
            onTap: (){
              _textController.clear();
              setState(() { homeSearchFilter = null; });
              _callRefresh();
              // Future.delayed(const Duration(milliseconds: 500),(){ _callRefresh(); }); // 延迟500毫秒再执行刷新，不然可能会出现刷新异常
            },
            child: Container(
              padding: const EdgeInsets.only(right: 5,left: 5,top: 3,bottom: 3),
              child: SvgPicture.asset('static/images/home_field_close.svg',color: colors.tintPrimary)//,width: 26,height: 26,),
            )
          )
        ]
      )
    );
  }

  Widget? _timeFilterItem(){
    var colors =  C.current(context);
    var language = L.current(context);
    var searchTime = homeTimeFilter;  // 初始值设为PDuration() 0-0-0 0:0:0,0 即不设限
    var searchTimeDesc = homeTimeSortDesc;
    if(searchTime == null){ return null; }
    return Container(
      padding: const EdgeInsets.only(left: 10,bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: (){
                Pickers.showDatePicker(
                  context,
                  mode: DateMode.YMD,
                  pickerStyle: DefaultPickerStyle(haveRadius: true),
                  selectDate: searchTime,// 默认选中
                  minDate: PDuration(year: (PDuration.now().year ?? 2022) - 30),
                  maxDate: PDuration(year: PDuration.now().year),
                  onConfirm: (p) {
                    setState(() { homeTimeFilter = p; });
                    _callRefresh();
                  },
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  padding: const EdgeInsets.only(left: 10,top: 5,bottom: 5,right: 10),
                  color: colors.bgOnBody_2,
                  child: Text(
                    searchTime.year == 0 ? language.time_to_start : '${language.time_to_start}:${searchTime.year}-${searchTime.month.toString().padLeft(2,'0')}-${searchTime.day.toString().padLeft(2,'0')}',
                    style: TextStyle(fontSize: F.f16,color: colors.tintPrimary),
                  )
                )
              )
            )
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: (){
                  setState(() { homeTimeSortDesc = !homeTimeSortDesc; });
                  _callRefresh();
                },
                child: Container(
                  padding:const EdgeInsets.only(left: 10,right: 10,top: 5, bottom: 5),
                  child: Row(
                    children: [
                      SvgPicture.asset('static/images/home_up_down.svg', color: colors.tintPrimary,),
                      const SizedBox(width: 5,),
                      Text(language.ascending,style: TextStyle(color: searchTimeDesc ? colors.tintSecondary : colors.bgGitBlue,fontSize: F.f14),),
                      const SizedBox(width: 5,),
                      Text(language.descending,style: TextStyle(color: searchTimeDesc ? colors.bgGitBlue : colors.tintSecondary,fontSize: F.f14))
                    ]
                  )
                )
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: (){
                  setState(() {
                    homeTimeFilter = null;
                    if(!searchTimeDesc){
                      homeTimeSortDesc = true;
                    }
                  });
                  _callRefresh();
                },
                child: Container(
                  padding: const EdgeInsets.only(right: 5,left: 5,top: 3,bottom: 3),
                  child: SvgPicture.asset('static/images/home_field_close.svg',color: colors.tintPrimary,)
                )
              )
            ]
          )
        ],
      ),
    );
  }

  Widget? _tagFilterItem(){
    var colors =  C.current(context);
    var selectTags =  Provider.of<GlobalModel>(context, listen:true).homeTagFilter;
    if(selectTags == null){ return null; }
    return Container(
      padding: const EdgeInsets.only(left: 10,bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...selectTags.map((e) => Container(
                    padding: const EdgeInsets.only(right: 10),
                    child: TagItemWidget(
                      tagStr: e,
                      onDelete: (){
                        Provider.of<GlobalModel>(context, listen:false).homeTagChange(e);
                        _callRefresh(forced: true);
                      },
                      onClick: () => {},
                      isSelect: true,
                    )
                  )).toList(),
                ],
              ),
            )
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: (){
              Provider.of<GlobalModel>(context, listen:false).homeTagClear();
              _callRefresh(forced: true);
            },
            child: Container(
                padding: const EdgeInsets.only(right: 5,left: 5,top: 3,bottom: 3),
                child: SvgPicture.asset('static/images/home_field_close.svg',color: colors.tintPrimary,)
            )
          )
        ]
      ),
    );
  }

  resetPage(){
    Provider.of<GlobalModel>(context, listen:false).homeTagFilter = null;
    setState(() {
      homeSearchFilter = null;
      homeTimeFilter = null;
      homeTimeSortDesc = true;
    });
  }

  Future<List<NoteInfo>> _loadNote(int pageNum) async{
    var currentRepo = Provider.of<RepoListModel>(context, listen:false).currentSelectedRepo;
    if(currentRepo == null){ return []; }
    /// 保存上次刷新参数，用于减少重复刷新
    oldSearchFilter = homeSearchFilter ?? '';
    oldTimeFilter = '';
    oldTimeSortDesc = true;
    oldTagFilter = Provider.of<GlobalModel>(context, listen:false).homeTagFilter ?? [];
    if(homeTimeFilter != null){
      oldTimeSortDesc = homeTimeSortDesc;
      int y = homeTimeFilter!.year ?? 0;
      int m = homeTimeFilter!.month ?? 0;
      int d = homeTimeFilter!.day ?? 0;
      if(y > 0 && m > 0 && d > 0){
        try{
          String timeStr = '${homeTimeFilter!.year.toString().padLeft(4,'0')}-${homeTimeFilter!.month.toString().padLeft(2,'0')}-${homeTimeFilter!.day.toString().padLeft(2,'0')} 23:59:59';
          var _strTimes = DateTime.parse(timeStr);
          var _intendTime = _strTimes.millisecondsSinceEpoch;
          oldTimeFilter = _intendTime.toString(); // 时间戳
        }catch(e){
          debugPrint(e.toString());
        }
      }
    }
    var list = await NoteInfo.loadList(repoKey: currentRepo.localPath, searchKey: oldSearchFilter, timePoint: oldTimeFilter, isDesc: oldTimeSortDesc, tags: oldTagFilter, pageSize: 20, pageNum: pageNum);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var currentRepo = Provider.of<RepoListModel>(context, listen:true).currentSelectedRepo;
    if(currentRepo == null){ return Container(); }
    if(oldRepoKey != currentRepo.localPath){
      oldRepoKey = currentRepo.localPath;
      resetPage();/// 仓库切换，重置页面
    }

    List<Widget> filterItems = [];
    var searchItem = _searchItem();
    if(searchItem != null){ filterItems.add(searchItem); }
    var timeItem = _timeFilterItem();
    if(timeItem != null){ filterItems.add(timeItem); }
    var tagItem = _tagFilterItem();
    if(tagItem != null){ filterItems.add(tagItem); }

    Widget body = Column(
      children: <Widget>[
        if(filterItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.only(left: 10,right: 10),
            child: ClipRRect(
              borderRadius:BorderRadius.circular(5),
              child: Container(
                color: colors.bgOnBody_1,
                padding: const EdgeInsets.only(top: 10),
                child: PreferredSize(
                  preferredSize: const Size(double.infinity, 0),
                  child: Column(
                    children: filterItems,
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: EasyRefresh.builder(
            refreshOnStart: true,
            controller: _refreshController,
            childBuilder: (context, physics) {
              return ListView.builder( // notes.isEmpty ? const EmptyViewer() :
                physics: physics,
                padding: const EdgeInsets.only(left: 10,right: 10,top: 0),
                itemBuilder: (context, index) {
                  List<String>? highLightTexts;
                  if(searchItem != null && _textController.text.isNotEmpty){
                    highLightTexts = _textController.text.split(' ').toList();
                  }
                  return notes.isEmpty ? const EmptyViewer() : MainListItem(note: notes[index],highLightTexts:highLightTexts);
                },
                itemCount: notes.isEmpty ?  1 : notes.length,
              );
            },
            onRefresh: () async {
              if (!mounted) { return; }
              pageNum = 0;
              var list = await _loadNote(pageNum);
              _refreshController.finishRefresh(IndicatorResult.success);
              _refreshController.resetFooter();
              setState(() { notes = list; });
            },
            onLoad: () async {
              if (!mounted) { return; }
              if(notes.isEmpty){
                _refreshController.finishLoad(IndicatorResult.success);
                return;
              }
              var list = await _loadNote(pageNum + 1);
              if(list.isEmpty){
                _refreshController.finishLoad(IndicatorResult.noMore);
              }else{
                _refreshController.finishLoad(IndicatorResult.success);
                setState(() { notes.addAll(list); });
                pageNum ++;
              }
            },
          ),
        )
      ],
    );

    return Scaffold(
      backgroundColor: colors.bgBodyBase_2,
      body: body
    );
  }
}
// 键盘收起后，刷新下拉距离有点多，无法解除刷新状态
// https://github.com/xuelongqy/flutter_easy_refresh/issues/572