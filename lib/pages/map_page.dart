import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:treediary/model/gps_item.dart';
import 'package:latlong2/latlong.dart';

// import 'package:map/map.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart' as Lottie;

import '../provider/global_color.dart';
import '../provider/global_language.dart';
// import 'package:flutter/gestures.dart';
// import 'package:latlng/latlng.dart';

class CachedTileProvider extends TileProvider {
  // const CachedTileProvider();
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    var keyUrl = getTileUrl(coords, options);
    // print(keyUrl.split('.tile.').last);
    return CachedNetworkImageProvider(keyUrl,cacheKey:keyUrl.split('.tile.').last);
  }
}

class MapPage extends StatefulWidget {

  final bool isEdit;
  GPSItem? gps;

  MapPage({Key? key, this.isEdit = false, this.gps}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  // late final MapController mapController;
  LatLng? _currentCenter;
  late CenterOnLocationUpdate _centerOnLocationUpdate;
  late StreamController<double?> _centerCurrentLocationStreamController;

  @override
  void dispose() {
    _centerCurrentLocationStreamController.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // mapController = MapController();
    _centerOnLocationUpdate = CenterOnLocationUpdate.never;
    _centerCurrentLocationStreamController = StreamController<double?>();
  }

  toLocation() async {
    setState(() => _centerOnLocationUpdate = CenterOnLocationUpdate.once,);
    // Center the location marker on the map and zoom the map to level 18.
    _centerCurrentLocationStreamController.add(17);
  }

  Timer? _positionChangedTimer;

  Widget build(BuildContext context) {
    print('build');
    var language = L.current(context);
    var centerLatLng = LatLng(48, 18);
    if(widget.gps != null){
      if(widget.gps!.latitude != null && widget.gps!.longitude != null){
        centerLatLng = LatLng(double.parse(widget.gps!.latitude!), double.parse(widget.gps!.longitude!));
      }
    }
    Widget body = Stack(
      children: [
        FlutterMap(
          // mapController: mapController,
          options: MapOptions(
            center: centerLatLng,
            interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            zoom: 16,
            maxZoom:17,
            minZoom: 3,
            onPositionChanged: (MapPosition position, bool hasGesture) {
              _positionChangedTimer?.cancel();
              _positionChangedTimer =  Timer(const Duration(milliseconds:100), () { // 节流
                if (hasGesture) {
                  setState(() {
                    _centerOnLocationUpdate = CenterOnLocationUpdate.never;
                    _currentCenter = position.center;
                  });
                }else{
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    if(mounted){
                      setState(() => {
                        _currentCenter = position.center
                      });
                    }
                  });
                }
              });
            },
            plugins: [
              LocationMarkerPlugin(
                centerCurrentLocationStream: _centerCurrentLocationStreamController.stream,
                centerOnLocationUpdate: _centerOnLocationUpdate,
              ),
            ],
          ),
          layers: [
            TileLayerOptions(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                tileProvider: CachedTileProvider()
            ),
            LocationMarkerLayerOptions(), // <-- add layer options here
            if(!widget.isEdit && widget.gps != null)
              MarkerLayerOptions(
                markers: [
                  Marker(
                    width: 100.0,
                    height: 100.0,
                    point: centerLatLng,
                    builder: (ctx) => Container(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: SvgPicture.asset('static/images/map_pin.svg',height: 50,),
                    ),
                  ),
                ],
              )
          ],
        ),
        // 底部按钮
        Positioned(
          bottom: 0,
          right: 0,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => { toLocation() },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    // color: Colors.red,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        color: Colors.white,
                        child: const Icon(
                            Icons.my_location_outlined,
                            size: 20,
                            color: Color.fromRGBO(83, 83, 83, 1)
                        ),
                      )
                    )
                  )
                ),
                if(widget.isEdit)
                  Container(
                    padding: const EdgeInsets.only(left: 15,right: 15,bottom: 15),
                    width: MediaQuery.of(context).size.width,
                    // height: 40,
                    // color: Colors.red,
                    child: GestureDetector(
                      onTap: () => { Navigator.pop(context, GPSItem(latitude: _currentCenter?.latitude.toStringAsFixed(5),longitude: _currentCenter?.longitude.toStringAsFixed(5))) },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          // height: 40,
                          color: const Color.fromRGBO(67, 198, 255, 1),
                          padding: const EdgeInsets.only(top: 10,bottom: 10),
                          child: Center(
                            child: Text(language.manually_done + (_currentCenter != null ? '(${_currentCenter?.latitude.toStringAsFixed(5)},${_currentCenter?.longitude.toStringAsFixed(5)})' : ''),textAlign: TextAlign.center,style: TextStyle(color: Colors.white,fontSize: F.f18),),
                          ),
                      )
                      )
                    )
                  ),
                Container(
                  color: const Color.fromRGBO(255, 255, 255, 0.4),
                  padding: const EdgeInsets.all(2),
                  child: Text("© OpenStreetMap contributors", style: TextStyle(color: Colors.black87,fontSize: F.f12),),
                )
              ],
            ),
          )
        ),
        // 中心选址大头针
        if(widget.isEdit)
          Align(
            child: Container(
              padding: const EdgeInsets.only(bottom: 50),
              child: SvgPicture.asset('static/images/map_pin.svg',height: 50,),
            ),
          ),
        // 返回按钮
        Positioned(
          child: SafeArea(
            child: GestureDetector(
              onTap: () => { Navigator.pop(context, widget.gps) },
              child: Container(
                padding: const EdgeInsets.only(left: 15,top: 10),
                child: SvgPicture.asset('static/images/map_back.svg'),
              )
            )
          )
        )
      ],
    );

    if(widget.isEdit){
      body = WillPopScope(
        child: body,
        onWillPop: () async{
          return false;
        }
      );
    }

    return body;
  }
}
