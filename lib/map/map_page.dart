import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'map_filter.dart';
import 'map_filter_dialog.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../geoFire/geoflutterfire.dart';
import '../geoFire/models/point.dart';
import 'apt_page.dart';

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
  Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  MarkerId? selectedMarker;
  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;
  late List<DocumentSnapshot> documentList = List<DocumentSnapshot>.empty(
    growable: true,
  );

  static const CameraPosition _googleMapCamera = CameraPosition(
    target: LatLng(37.571320, 127.029403),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    addCustomIcon();
  }

  void addCustomIcon() {
    BitmapDescriptor.asset(
      const ImageConfiguration(),
      'res/images/apartment.png',
      width: 50,
      height: 50,
    ).then((icon) {
      setState(() {
        markerIcon = icon;
      });
    });
  }

  Future<void> _searchApt() async {
    // GoogleMapController 가져오기
    final GoogleMapController controller = await _controller.future;
    // 현재 지도 화면 영역 가져오기
    final bounds = await controller.getVisibleRegion();

    // 화면 영역의 중심 좌표 계산하기
    final LatLng centerBounds = LatLng(
      (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
      (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
    );

    // Firestore 'cities' 컬렉션 참조 가져오기
    final aptRef = FirebaseFirestore.instance.collection('cities');
    final geo = Geoflutterfire();

    // GeoFirePoint 객체 생성하기(지도 중심 좌표 사용)
    final GeoFirePoint center = geo.point(
      latitude: centerBounds.latitude,
      longitude: centerBounds.longitude,
    );

    // 검색 반경과 GeoFire 필드 설정하기
    const double radius = 1; // 검색 반경 1km
    const String field = 'position'; // GeoFire 필드 이름

    // GeoFlutterFire를 사용하여 Firestore 쿼리 실행하기(반경 내 문서 검색)
    final Stream<List<DocumentSnapshot>> stream = geo
        .collection(collectionRef: aptRef)
        .within(center: center, radius: radius, field: field);

    // 검색 결과 스트림 Listen
    stream.listen((List<DocumentSnapshot> documentList) {
      // 검색 결과 문서 목록 저장하고 마커 업데이트하기
      this.documentList = documentList;
      _drawMarkers(documentList);
    });
  }

  void _drawMarkers(List<DocumentSnapshot> documentList) {
    setState(() {
      markers.clear(); // 기존 마커를 효율적으로 제거하기
    });

    // 검색 결과 문서 목록 순회하기
    for (final DocumentSnapshot doc in documentList) {
      // 각 문서에서 아파트 정보 추출하기
      final Map<String, dynamic> info = doc.data()! as Map<String, dynamic>;
      // 필터 조건에 맞는지 확인하기
      if (selectedCheck(
        info,
        mapFilter.peopleString,
        mapFilter.carString,
        mapFilter.buildingString,
      )) {
        // MarkerId 생성하기(geohash 사용)
        final MarkerId markerId = MarkerId(info['position']['geohash']);

        // Marker 생성하기
        final Marker marker = Marker(
          markerId: markerId,
          infoWindow: InfoWindow(
            title: info['name'],
            snippet: info['address'],
            onTap: () {
              // AptPage로 이동하기
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return AptPage(
                      aptHash: info['position']['geohash'],
                      aptInfo: info,
                    );
                  },
                ),
              );
            },
          ),
          position: LatLng(
            (info['position']['geopoint'] as GeoPoint).latitude,
            (info['position']['geopoint'] as GeoPoint).longitude,
          ),
          icon: markerIcon,
        );
        // 지도에 마커 추가하기
        setState(() {
          markers[markerId] = marker;
        });
      }
    }
  }

  bool selectedCheck(
    Map<String, dynamic> info,
    String? peopleString,
    String? carString,
    String? buildingString,
  ) {
    final dong = info['ALL_DONG_CO'];
    final people = info['ALL_HSHLD_CO'];
    final parking = people / info['CNT_PA'];

    // 동 수와 세대 수 먼저 확인하기
    if (dong < int.parse(buildingString!) ||
        people < int.parse(peopleString!)) {
      return false;
    }

    // carString으로 주차 대수 확인하기
    if (carString == '1') {
      return parking < 1;
    } else {
      return parking >= 1;
    }
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
              : ListView.builder(
                itemBuilder: (context, value) {
                  Map<String, dynamic> item =
                      documentList[value].data() as Map<String, dynamic>;
                  return InkWell(
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.apartment),
                        title: Text(item['name']),
                        subtitle: Text(item['address']),
                        trailing: const Icon(Icons.arrow_circle_right_sharp),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return AptPage(
                              aptHash: item['position']['geohash'],
                              aptInfo: item,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                itemCount: documentList.length,
              ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentItem,
        onTap: (value) {
          if (value == 0) {
            _controller = Completer<GoogleMapController>();
          }

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
        onPressed: _searchApt,
        label: const Text('이 위치로 검색하기'),
      ),
    );
  }
}
