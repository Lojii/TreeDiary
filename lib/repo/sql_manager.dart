import 'dart:math';

import 'note_resource_info.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert' as convert;
// import 'package:treediary/common/utils/common_utils.dart';

import 'package:treediary/provider/repo_list_model.dart';
import '../config/global_data.dart';
import 'note_info.dart';
import 'repo_action.dart';
import 'repo_util.dart';

/* 保存相对路径
创建时间、
更新时间、
创建者、
日记路径、
md路径、       2022/06/15.164259.816/1655282579816.md
md内容(前一万字)、
info.json路径(如果有)、
版本、
image路径列表、
image缩略图路径列表、
video路径列表、
video缩略图路径列表、
file路径列表、
audio路径列表、
标签列表、
经纬度、
link列表、
网页快照文件路径、
* */

Database? note_db;

class SQLManager {
  /// @change {'new' 'modified' 'deleted' 'renamed'}
  static updateDatabase({required Map<String, List<String>> changes, required String repoLocalPath}) async{
    print(changes.toString());
    List<String> newFiles = changes['new'] ?? [];
    List<String> modifiedFiles = changes['modified'] ?? [];
    List<String> deletedFiles = changes['deleted'] ?? [];
    List<String> renamedFiles = changes['renamed'] ?? [];

    var repoBasePath = Global.repoBaseDir + '/' + repoLocalPath;
    if(newFiles.isNotEmpty){
      addNotes(newFiles, repoBasePath,repoLocalPath);
    }
    if(modifiedFiles.isNotEmpty){
    }
    if(deletedFiles.isNotEmpty){
      deleteNotes(deletedFiles, repoLocalPath);
    }
    if(renamedFiles.isNotEmpty){

    }
  }

  static Future<void> initDatabase() async{
    var databasesPath = await getDatabasesPath();
    String dbPath = path.join(databasesPath, 'forest');
    note_db = await openDatabase(dbPath, version: 1);
    await initTable(NoteInfo.tableName, NoteInfo.columns);
    await initTable(NoteResourceInfo.tableName, NoteResourceInfo.columns);
  }

  static initTable(String tableName, Map<String, String> columns) async{
    print(' ↓↓↓↓↓↓↓↓↓↓ initTable:$tableName ↓↓↓↓↓↓↓↓↓↓');
    List<String> existingTables = [];
    List tableMaps = await note_db?.rawQuery('SELECT name FROM sqlite_master WHERE type = "table"') ?? [];
    // print('initSettingTable tableMaps:' + tableMaps.toString());
    for (var item in tableMaps) { existingTables.add(item['name']); }
    if(!existingTables.contains(tableName)){// 创建
      String columnStr = '';
      for(var key in columns.keys){ columnStr = columnStr + (columnStr.isEmpty ? '' : ',') + ' $key ${columns[key]}'; }
      String createTableSQL = 'CREATE TABLE $tableName ( $columnStr )';
      print(createTableSQL);
      await note_db?.execute(createTableSQL);
    }else{ // 补全
      List<Map> allSettings = await note_db?.rawQuery('pragma table_info ("$tableName")') ?? [];
      List<String> existColumns = [];
      for(var item in allSettings){
        existColumns.add(item['name'] ?? '');
      }
      // print('initSettingTable columns:' + columns.toString());
      List<String> needAddColumns = [];
      for(var key in columns.keys){
        if(key.isEmpty){continue;}
        if(!existColumns.contains(key)){ needAddColumns.add(key); }
      }
      if(needAddColumns.isNotEmpty){
        for(var name in needAddColumns){
          String alterSql = 'ALTER TABLE $tableName ADD COLUMN $name ${columns[name]}';
          print(alterSql);
          await note_db?.rawQuery(alterSql);
        }
      }
    }
    print('↑↑↑↑↑↑↑↑↑↑ initTable:$tableName ↑↑↑↑↑↑↑↑↑↑');
  }


  static insert({required String table, required Map map}){

  }

  static Future<List<Map<String, Object?>>> rawQuery(String sql) async {
    try{
      List<Map<String, Object?>> list = await note_db!.rawQuery(sql);
      return list;
    }catch(e){
      return [];
    }
  }

  static Future<bool> rawDelete(String sql) async {
    try{
      int e = await note_db!.rawDelete(sql);
      return e > 0;
    }catch(e){
      return false;
    }
  }


  // static Future<List<Map<String, Object?>>> query({required String table}) async {
  //   // await db!.query(table,where: '', whereArgs: [], orderBy: '',limit: 10);
  //   List<Map<String, Object?>> list = await db!.rawQuery('SELECT * FROM Note');
  //   return list;
  // }
  // TODO:同步方法
  // insert / update
  static save({required String table, required Map<String, Object> values, Map<String, String>? uniqueKey} ) async{
    // update
    if(uniqueKey != null && uniqueKey.isNotEmpty){
      String whereStr = uniqueKey.keys.map((k) => '$k = ?').toList().join(' and ');
      List<String> args = uniqueKey.values.toList();
      // print(whereStr);
      // print(args);
      List<Map> maps = await note_db!.query(table,where: whereStr, whereArgs: args );
      if(maps.isNotEmpty){
        await note_db!.update(table, values, where: whereStr, whereArgs: args);
        return;
      }
    }
    // insert
    await note_db!.insert(table, values);
  }

  /// 参数为.md文件路径，从md文件里扫描出需要的内容，而不是从其他地方
  /// 执行commit或者拉取更新的时候，过滤出发生变化的md文件，根据新增、删除、修改执行对应的方法，首次clone的时候，对所有md文件，执行一次add方法
  static Future<void> addNotes(List<String> mdPaths, String repoBasePath, String repoLocalPath) async{
    for(var file in mdPaths){
      if(file.endsWith('.md')){
        NoteInfo? note = await NoteInfo.from(mdFile: '$repoBasePath/$file',repoLocalPath:repoLocalPath);
        await note?.saveToDB();
      }
    }
  }
  static Future<void> deleteNotes(List<String> mdPaths, String repoLocalPath) async{
    for(var file in mdPaths){
      if(file.endsWith('.md')){
        await NoteInfo.deleteToDB(mdKey: file, repoKey: repoLocalPath);
      }
    }
  }
  static Future<void> updateNotes(List<String> mdPaths) async{

  }

}
