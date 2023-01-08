import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';

class GPSItem {

  String? longitude; // 经度
  String? latitude;  //  纬度
  String? altitude;  //  海拔
  String? name;      // 逆地理信息

  GPSItem({ this.longitude, this.latitude,this.altitude,this.name});

  static Future<GPSItem?> getLocation() async{
    EasyLoading.show();
    bool serviceEnabled;
    LocationPermission permission;

    try{
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        EasyLoading.dismiss();
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          EasyLoading.dismiss();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        EasyLoading.dismiss();
        return null;
      }

      Position p = await Geolocator.getCurrentPosition();
      EasyLoading.dismiss();
      return GPSItem(longitude: p.longitude.toStringAsFixed(5), latitude: p.latitude.toStringAsFixed(5), altitude: p.altitude.toStringAsFixed(2));
    }catch(e){
      if (kDebugMode) { print(e); }
      EasyLoading.dismiss();
      return null;
    }
  }
}
