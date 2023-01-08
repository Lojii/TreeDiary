// 全局信息
import 'package:flutter/cupertino.dart';
import 'package:flutter_pickers/time_picker/model/pduration.dart';
import 'package:treediary/provider/repo_list_model.dart';

class GlobalModel extends ChangeNotifier {

  List<String> currentEditTags = [];
  List<RepoModel> currentEditRepos = [];
  List<String>? homeTagFilter;

  GlobalModel();
  /// Edit
  editClear(){
    currentEditTags = [];
    currentEditRepos = [];
    notifyListeners();
  }
  editTagsChange(List<String> tags){
    currentEditTags = tags;
    notifyListeners();
  }
  editReposChange(List<RepoModel> repos){
    currentEditRepos = repos;
    notifyListeners();
  }
  // /// Home
  // homeSearchChange(String? searchKey){
  //   homeSearchFilter = searchKey;
  //   notifyListeners();
  // }
  // homeTimeChange(PDuration? time){
  //   homeTimeFilter = time;
  //   notifyListeners();
  // }
  // homeTimeSortChange(){
  //   homeTimeSortDesc = !homeTimeSortDesc;
  //   notifyListeners();
  // }
  homeTagChange(String tag){
    if(homeTagFilter != null){
      if(homeTagFilter!.contains(tag)){
        homeTagFilter!.remove(tag);
        if(homeTagFilter!.isEmpty){
          homeTagFilter = null;
        }
      }else{
        homeTagFilter!.add(tag);
      }
    }else{
      homeTagFilter = [tag];
    }
    notifyListeners();
  }
  homeTagClear(){
    homeTagFilter = null;
    notifyListeners();
  }

}