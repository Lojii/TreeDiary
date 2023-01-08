import 'package:treediary/provider/repo_list_model.dart';
import 'package:treediary/provider/setting_model.dart';
import 'package:treediary/utils/event_bus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../config/global_data.dart';
import '../repo/note_info.dart';

// provider持久化数据库
Database? provider_db;

// 用于provider数据库初始化、升级、增删改查
class ProviderSQLManager {

  static String ProviderRefresh = 'ProviderRefresh';

  static Future<void> initDatabase() async{
    Directory supportDirectory = await getApplicationSupportDirectory();
    String dbPath = path.join(supportDirectory.path, 'config');
    provider_db = await openDatabase(dbPath, version: 1);
    // 表初始化:设置表、仓库表、同步表
    await initTable(SettingModel.tableName, SettingModel.columns);
    await initTable(RepoModel.tableName, RepoModel.columns);
    await initTable(RepoSync.tableName, RepoSync.columns);

    // await RepoListSQL.initTable();// 测试数据
  }

  static initTable(String tableName, Map<String, String> columns) async{
    // print(' ↓↓↓↓↓↓↓↓↓↓ initTable:$tableName ↓↓↓↓↓↓↓↓↓↓');
    List<String> existingTables = [];
    List tableMaps = await provider_db?.rawQuery('SELECT name FROM sqlite_master WHERE type = "table"') ?? [];
    // print('initSettingTable tableMaps:' + tableMaps.toString());
    for (var item in tableMaps) { existingTables.add(item['name']); }
    if(!existingTables.contains(tableName)){// 创建
      String columnStr = '';
      for(var key in columns.keys){ columnStr = columnStr + (columnStr.isEmpty ? '' : ',') + ' $key ${columns[key]}'; }
      String createTableSQL = 'CREATE TABLE $tableName (id INTEGER PRIMARY KEY,$columnStr )';
      print(createTableSQL);
      await provider_db?.execute(createTableSQL);
    }else{ // 补全
      List<Map> allSettings = await provider_db?.rawQuery('pragma table_info ("$tableName")') ?? [];
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
          await provider_db?.rawQuery(alterSql);
        }
      }
    }
    // print('↑↑↑↑↑↑↑↑↑↑ initTable:$tableName ↑↑↑↑↑↑↑↑↑↑');
  }

  // tableXXX, xxx.toMap(), where: '$xxxId = ?', whereArgs: [xxx.id]
  static Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs}) async{
    try{
      int count = await provider_db?.update(table, values, where: where, whereArgs: whereArgs) ?? 0;
      return count;
    }catch(e){
      print(e);
      return -1;
    }
  }

  static Future<bool> delete(String table, {String? where, List<Object?>? whereArgs}) async{
    try{
      await provider_db?.delete(table,where: where, whereArgs: whereArgs);
      return true;
    }catch(e){
      print(e);
      return false;
    }
  }

  static Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async{
    try{
      var res = await provider_db?.rawQuery(sql, arguments);
      return res ?? [];
    }catch(e){
      print(e);
      return [];
    }
  }
  // 通知刷新
  static notify(){
    Bus.emit(ProviderRefresh);
  }

}
