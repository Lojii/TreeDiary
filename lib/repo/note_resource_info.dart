
import 'package:flutter/foundation.dart';
import 'package:treediary/repo/sql_manager.dart';

class NoteResourceType{
  static String tag = "tag";
  static String image = "image";
  static String imagePreview = "imagePreview";
  static String video = "video";
  static String videoPreview = "videoPreview";
  static String file = "file";
  static String audio = "audio";
  static String link = "link";
  static String linkSnapshot = "linkSnapshot";
  static String unknown = "unknown";
  static String gps = "gps";
  static String address = "address";
}

class NoteResourceInfo {
  /// 根据id的序号排序

  // 唯一信息
  int id = -1;
  String repoKey;     // repo路径，比如 pt_rexx (全路径不太行)
  String mdKey;       // md路径 2022/12/23-231103-123.md
  String payload;     //
  String type;        // NoteResourceType
  int count = 0;      // 用于统计tag数量

  NoteResourceInfo({ required this.repoKey,required this.mdKey, required this.payload, required this.type });

  static String tableName = 'NoteResource';
  static Map<String, String> columns = {
    "id": "INTEGER PRIMARY KEY",
    "repoKey": "TEXT",
    "mdKey": "TEXT",
    "payload": "TEXT",
    "type": "TEXT",
    "num": "INTEGER",
  };

  Map<String, Object> toMap(){
    Map<String, Object> map = {
      "repoKey": repoKey,
      "mdKey": mdKey,
      "payload": payload,
      "type": type,
    };
    return map;
  }

  /// 新增资源
  add() async{
    await SQLManager.save(table: NoteResourceInfo.tableName, values: toMap());
  }
  static addAll(List<NoteResourceInfo> resources) async{
    for(var r in resources){ await r.add(); }
  }
  // /// 删除资源
  // static void delete() async{
  //   /// 检查是否存在，如果存在，则num--,如果num == 0，则移除该tag
  //
  // }
  // static deleteAll({required String repoKey, String? mdKey}) async{ // 如果mdPath为空，则删除所有
  //   /// 检查是否存在，如果存在，则num--,如果num == 0，则移除该tag
  //
  // }
  /// 获取Note对应的所有资源
  static Future<List<NoteResourceInfo>> list({required String repoKey, String? mdKey, String? type}) async{
    String whereStr = "WHERE repoKey = '$repoKey'";
    if(mdKey != null && mdKey.isNotEmpty){ whereStr = whereStr + " AND mdKey = '$mdKey'"; }
    if(type != null && type.isNotEmpty){ whereStr = whereStr + " AND type = '$type'"; }
    String resourceSQL = "SELECT * FROM ${NoteResourceInfo.tableName} $whereStr GROUP BY id  ORDER BY id ASC";
    var resourceMaps = await SQLManager.rawQuery(resourceSQL);
    List<NoteResourceInfo> resources = [];
    for(var r in resourceMaps){
      var mk = r['mdKey'];
      var payload = r['payload'];
      var type = r['type'];
      var id = r['id'];
      if(mk != null && payload != null && type != null && id != null){
        if(mk is String && payload is String && type is String && id is int){
          NoteResourceInfo resource = NoteResourceInfo(repoKey: repoKey, mdKey: mk, payload: payload, type: type);
          resource.id = id;
          resources.add(resource);
        }
      }
    }
    return resources;
  }
  /// 获取Note对应的所有标签
  static Future<List<NoteResourceInfo>> allTags(List<String> repoKeys) async{
    String whereOr = '';
    for(var rk in repoKeys){
      if(whereOr.isEmpty){
        whereOr = "repoKey = '$rk'";
      }else{
        whereOr = whereOr + " OR repoKey = '$rk'";
      }
    }
    if(whereOr.isNotEmpty){
      whereOr = "WHERE ($whereOr) AND type = '${NoteResourceType.tag}'";
    }else{
      whereOr = "WHERE type = '${NoteResourceType.tag}'";
    }
    String resourceSQL = "SELECT *, COUNT(payload) as num FROM ${NoteResourceInfo.tableName} $whereOr GROUP BY payload ORDER BY COUNT(payload) DESC";
    if (kDebugMode) { print(resourceSQL); }
    var resourceMaps = await SQLManager.rawQuery(resourceSQL);
    List<NoteResourceInfo> resources = [];
    for(var r in resourceMaps){
      var rk = r['repoKey'];
      var mk = r['mdKey'];
      var payload = r['payload'];
      var type = r['type'];
      var id = r['id'];
      var num = r['num'];
      if(rk != null && mk != null && payload != null && type != null && id != null && num != null){
        if(rk is String && mk is String && payload is String && type is String && id is int && num is int){
          NoteResourceInfo resource = NoteResourceInfo(repoKey: rk, mdKey: mk, payload: payload, type: type);
          resource.id = id;
          resource.count = num;
          resources.add(resource);
        }
      }
    }
    return resources;
  }


  @override
  String toString() {
    return '$payload $type';
  }

}
