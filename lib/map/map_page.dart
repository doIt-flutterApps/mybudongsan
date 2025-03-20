import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'map_filter.dart';
import 'map_filter_dialog.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MapPage();
  }
}

class _MapPage extends State<MapPage> {
  int currentItem = 0;
  MapFilter mapFilter = MapFilter();
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  static const CameraPosition _googleMapCamera = CameraPosition(
    target: LatLng(37.571320, 127.029403),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My 부동산'),
        actions: [
          IconButton(
            onPressed: () async {
              var result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return MapFilterDialog(mapFilter);
                  },
                ),
              );
              if (result != null) {
                mapFilter = result as MapFilter;
              }
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '홍길동',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'hong@gmail.com',
                    style: TextStyle(fontSize: 16.0, color: Colors.white),
                  ),
                ],
              ),
            ),
            ListTile(title: const Text('내가 선택한 아파트'), onTap: () {}),
            ListTile(title: const Text('설정'), onTap: () {}),
          ],
        ),
      ),
      body:
          currentItem == 0
              ? GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _googleMapCamera,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                markers: Set<Marker>.of(markers.values),
              )
              : ListView(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentItem,
        onTap: (value) {
          setState(() {
            currentItem = value;
          });
        },
        items: const [
          BottomNavigationBarItem(label: 'map', icon: Icon((Icons.map))),
          BottomNavigationBarItem(label: 'list', icon: Icon((Icons.list))),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('이 위치로 검색하기'),
      ),
    );
  }
}
