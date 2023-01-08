import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/repo/note_resource_info.dart';
import 'package:treediary/widgets/substring_highlight.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';

import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../provider/global_model.dart';

class EditTags extends StatefulWidget {
  //
  const EditTags({Key? key}) : super(key: key);

  @override
  _EditTagsState createState() => _EditTagsState();
}

class _EditTagsState extends State<EditTags>{

  late TextEditingController _editController;
  late FocusNode _focusNode;

  // List<String> selectTags = ['已完成'];//[];
  List<String> recentTags = [];//[];
  List<String> allTags = [];//[];
  List<String> sampleTags = [];//[];
  List<String> searchTags = [];

  @override
  initState(){
    _editController = TextEditingController();
    _focusNode = FocusNode();
    super.initState();
    _loadTags();
  }

  _loadTags() async{
    var repos = Provider.of<GlobalModel>(context, listen:false).currentEditRepos;
    // 后续需要过滤加密的仓库
    var tags = await NoteResourceInfo.allTags(repos.map((e) => e.localPath).toList());
    setState(() { allTags = tags.map((e) => e.payload).toList(); });
  }

  _selectTagsChange(List<String> newTags){
    Provider.of<GlobalModel>(context, listen:false).editTagsChange(newTags);
  }

  _clickTag(String tag){
    var tags = Provider.of<GlobalModel>(context, listen:false).currentEditTags;
    if(tags.contains(tag)){
      tags.remove(tag);
    }else{
      tags.add(tag);
    }
    Provider.of<GlobalModel>(context, listen:false).editTagsChange(tags);
  }

  // 点击，添加后，移除焦点并清空输入框
  _searchClick(String tag){
    if(tag.isEmpty){ return; }
    var tags = Provider.of<GlobalModel>(context, listen:false).currentEditTags;
    if(!tags.contains(tag)){
      tags.add(tag);
      Provider.of<GlobalModel>(context, listen:false).editTagsChange(tags);
    }
    setState((){
      searchTags = [];
    });
    // 清空输入框
    _editController.text = '';
    // 移除焦点
    _focusNode.unfocus();
  }

  _textDidChange(String value){
    List<String> newSearchTags = [];
    if(value.isNotEmpty){
      for(var tag in allTags){
        if(tag.contains(value)){
          if(Provider.of<GlobalModel>(context, listen:false).currentEditTags.contains(tag)){ continue; }
          newSearchTags.add(tag);
        }
      }
    }
    setState((){ searchTags = newSearchTags; });
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    // print('EditTags build');
    var selectTags = Provider.of<GlobalModel>(context, listen:true).currentEditTags;
    return Scaffold(
      backgroundColor: colors.bgBodyBase_1,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 导航栏
                Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => {
                        Navigator.pop(context)
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        // color: Colors.red,
                        child: SvgPicture.asset('static/images/nav_close.svg',width: 30,height: 30,color: colors.tintPrimary,),
                      ),
                    ),
                    Text(language.add_tags,style: TextStyle(fontSize: F.f16,fontWeight: FontWeight.w700,color: colors.tintPrimary),),
                    Container(
                      margin: const EdgeInsets.all(15),
                      width: 30,height: 30,
                    ),
                  ],
                ),
                // 输入框
                Flex(
                  direction: Axis.horizontal,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(left: 15,right: 5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            color: colors.bgOnBody_2,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(left: 10,top: 8,bottom: 8,right: 5),
                                  child: SvgPicture.asset('static/images/text_search.svg',width: 20,height: 20,color: colors.tintPrimary,),
                                ),
                                Expanded(
                                    child: TextField(
                                      controller: _editController,
                                      focusNode: _focusNode,
                                      onChanged:(value) => { _textDidChange(value) },
                                      // autofocus: true,
                                      maxLines: 1,
                                      decoration: InputDecoration(
                                          hintText: language.enter_the_label,
                                          hintStyle: TextStyle(fontSize: F.f16,color: colors.tintPlaceholder),
                                          border: const OutlineInputBorder(borderSide: BorderSide.none), //去除下边框
                                          contentPadding: const EdgeInsets.all(0),
                                      ),
                                      style: TextStyle(fontSize: F.f16,color: colors.tintPrimary),
                                    )
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => {_searchClick(_editController.text)},
                      child: Container(
                        padding: const EdgeInsets.only(left: 15,right: 15,top: 10,bottom: 10),
                        // color: Colors.red,
                        child: Text(language.add_tag,style: TextStyle(fontSize: F.f16,fontWeight: FontWeight.w700,color: colors.tintPrimary),),
                      ),
                    )
                  ],
                ),
                // 已添加
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  alignment: Alignment.topLeft,
                  child: selectTags.isNotEmpty && searchTags.isEmpty ? TagGroupWidget(
                    tags: selectTags,
                    selectTags:selectTags,
                    title: language.added_tags,
                    onChange: (List<String> newTags) => _selectTagsChange(newTags),
                  ) : Container(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if(recentTags.isNotEmpty && searchTags.isEmpty)
                      TagGroupWidget(
                        tags: recentTags,
                        selectTags:selectTags,
                        didClick:(tag) => _clickTag(tag),
                        title: language.recently_tags,
                      ),
                    if(allTags.isNotEmpty && searchTags.isEmpty)
                      TagGroupWidget(
                        tags: allTags,
                        selectTags:selectTags,
                        didClick:(tag) => _clickTag(tag),
                        title: language.all_tags,
                      ),
                    if(sampleTags.isNotEmpty && searchTags.isEmpty)
                      TagGroupWidget(
                        tags: sampleTags,
                        selectTags:selectTags,
                        didClick:(tag) => _clickTag(tag),
                        title: language.sample_tags,
                      ),
                    if( searchTags.isNotEmpty)
                      TagGroupWidget(
                        tags: searchTags,
                        selectTags:selectTags,
                        didClick:(tag) => _searchClick(tag),
                        highLightTxt:_editController.text
                      ),
                  ],
                ),
              )
            )
          ],
        ),
      ),
    );
  }
}

class TagItemWidget extends StatelessWidget {
  final String tagStr;
  final String? highLightTxt;
  final VoidCallback? onDelete; // 如果onDelete不为空，则显示删除按钮
  final VoidCallback? onClick;
  final bool isSelect;

  const TagItemWidget({Key? key, required this.tagStr, this.onDelete, this.isSelect = false, this.onClick, this.highLightTxt}) : super(key: key);

  _didDelete(){
    if(onDelete != null){
      onDelete!();
    }
  }

  _didClick(){
    if(onClick != null){
      onClick!();
    }
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    // print('TagItemWidget build');
    return GestureDetector(
        onTap: _didClick,
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Container(
            // color: Colors.red,
            padding: onDelete != null ? const EdgeInsets.fromLTRB(6, 0, 0, 0) : const EdgeInsets.fromLTRB(6, 5, 6, 5),
            // margin: const EdgeInsets.only(right: 9),
            decoration: BoxDecoration(
              border:  Border.all(color: colors.tintPicBorder, width: 1), // 边色与边宽度
              borderRadius: BorderRadius.circular((100.0)), // 圆角度
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible (child:Container(
                  padding: const EdgeInsets.only(left: 3,right: 3),
                  // child: Text(
                  //     '#' + tagStr,
                  //     overflow: TextOverflow.ellipsis,
                  //     style: TextStyle(
                  //         color: isSelect ? const Color(0xFF535353) : const Color(0xFF979797),
                  //         fontSize: 12.0,
                  //         fontWeight:isSelect ? FontWeight.w600 : FontWeight.w400
                  //     ),
                  //     textAlign: TextAlign.right,
                  //   // maxLines: 2,
                  // ),
                  child: SubstringHighlight(
                    text: '#' + tagStr,
                    term: highLightTxt == null ? '' : highLightTxt!,
                    overflow: TextOverflow.ellipsis,
                    textStyle: TextStyle(
                        color: isSelect ? colors.tintPrimary : colors.tintSecondary,
                        fontSize: F.f12,
                        // fontWeight:isSelect ? FontWeight.w600 : FontWeight.w400
                    ),
                    textStyleHighlight:TextStyle(
                        color: colors.tintWarming,
                        fontSize: F.f12,
                        // fontWeight:isSelect ? FontWeight.w600 : FontWeight.w400
                    ),
                    textAlign: TextAlign.right,
                  ),
                )),
                if(onDelete != null)
                  GestureDetector(
                    onTap: _didDelete,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      child: SvgPicture.asset('static/images/item_delete.svg',color: colors.tintSecondary,),
                    ),
                  ),
              ],
            ),
          ),
        )
    );
  }
}

class TagGroupWidget extends StatefulWidget {
  final String? title;
  final String? highLightTxt;
  final List<String> tags;
  final List<String>? selectTags;
  final Function? onChange; // 为空时，不能编辑和排序
  final Function? didClick; // 选择

  const TagGroupWidget({Key? key, this.title, required this.tags, this.selectTags, this.onChange, this.didClick, this.highLightTxt, }) : super(key: key);

  @override
  _TagGroupWidgetState createState() => _TagGroupWidgetState();
}

class _TagGroupWidgetState extends State<TagGroupWidget>{

  didDelete(){

  }

  _onTagReorder(int oldIndex, int newIndex) {
    setState(() {
      String path = widget.tags.removeAt(oldIndex);
      widget.tags.insert(newIndex, path);
    });
  }

  _onDelete(String tag){
    setState(() { widget.tags.remove(tag); });
    if(widget.onChange != null){
      widget.onChange!(widget.tags);
    }
  }

  @override
  Widget build(BuildContext context) {
    // print('TagGroupWidget build');
    var colors =  C.current(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Container(
          padding: const EdgeInsets.only(left: 15,top: 15,bottom: 8),
          child: widget.title != null ? Text(widget.title! + ':',style: TextStyle(fontSize: F.f14,color: colors.tintPrimary,fontWeight: FontWeight.w600),) : Container(),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.only(left: 15,right: 15),
          child: ReorderableWrap(
            spacing: 10.0,
            runSpacing: 10.0,
            enableReorder: widget.onChange != null,
            children: widget.tags.map((e) => TagItemWidget(
              tagStr: e,
              highLightTxt: widget.highLightTxt,
              isSelect: widget.selectTags?.contains(e) ?? false,
              onDelete: widget.onChange != null ? () => {_onDelete(e)} : null,
              onClick: widget.didClick != null ? () => { widget.didClick!(e) } : null,
            )).toList(),
            onReorder: _onTagReorder,
            onNoReorder: (int index) {
              debugPrint('${DateTime.now().toString().substring(5, 22)} reorder cancelled. index:$index');
            },
            onReorderStarted: (int index) {
              debugPrint('${DateTime.now().toString().substring(5, 22)} reorder started: index:$index');
            }
          )
        ),
        Container(
          height: 0.5,
          margin: EdgeInsets.only(top: 15,left: 15,right: 15),
          color: colors.tintSeparator_2,
        )
      ],
    );
  }
}
