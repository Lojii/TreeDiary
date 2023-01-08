import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/provider/global_model.dart';
import 'package:treediary/repo/note_resource_info.dart';
import 'package:provider/provider.dart';
import '../pages/main_page.dart';
import '../provider/global_color.dart';
import '../provider/global_language.dart';
import '../provider/repo_list_model.dart';
import '../utils/event_bus.dart';

class TagListDrawer extends StatefulWidget{

  const TagListDrawer({Key? key}) : super(key: key);

  @override
  TagListDrawerState createState() => TagListDrawerState();
}

class TagListDrawerState extends State <TagListDrawer>{

  bool hadInit = false;
  List<NoteResourceInfo> tags = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (hadInit) { return; }
    hadInit = true;
    _loadAllTags();
  }

  _loadAllTags() async{
    var currentRepo = Provider.of<RepoListModel>(context, listen:false).currentSelectedRepo;
    if(currentRepo == null){ return; }
    var allTag = await NoteResourceInfo.allTags([currentRepo.localPath]);
    setState(() { tags = allTag; });
  }

  Widget _tagItem(NoteResourceInfo tag, List<String>? selectTags){
    var colors =  C.current(context);
    bool select = selectTags?.contains(tag.payload) ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (){
        Provider.of<GlobalModel>(context, listen:false).homeTagChange(tag.payload);
        Bus.emit(MainPage.forceRefresh);
      },
      child: Container(
        color: select ? colors.bgOnBody_2 : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 10,top: 10,bottom: 10,right: 5),
              child: SvgPicture.asset(select ? 'static/images/check_box.svg' : 'static/images/check_box_un.svg', color: colors.tintSecondary,),
            ),
            Container(
              constraints: const BoxConstraints( maxWidth: 260, ),
              padding: const EdgeInsets.only(right: 15),
              child: Row(
                children: [
                  Expanded(child: Text(tag.payload, style: TextStyle(color: colors.tintPrimary, fontSize: F.f16),maxLines: 1,overflow: TextOverflow.ellipsis,)),
                  const SizedBox(width: 5,),
                  Text('${tag.count}', style: TextStyle(color: colors.tintTertiary, fontSize: F.f16),),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var colors =  C.current(context);
    var language = L.current(context);
    var selectTags =  Provider.of<GlobalModel>(context, listen:true).homeTagFilter;
    return Container(
      color: colors.bgBody_1,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 10,right: 10,top: 10,bottom: 10),
              child: Text(language.all_tags,style: TextStyle(fontSize: F.f20,fontWeight: FontWeight.w600, color: colors.tintPrimary),),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if(tags.isNotEmpty)
                      ...tags.map((e) => _tagItem(e, selectTags)),
                    if(tags.isEmpty)
                      Container(
                        padding: const EdgeInsets.only(top: 10,left: 15,right: 15),
                        constraints: const BoxConstraints( maxWidth: 260, ),
                        child: Text(language.no_tags,style: TextStyle(color: colors.tintPrimary,fontSize: F.f16),textAlign: TextAlign.center,),
                      )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

}