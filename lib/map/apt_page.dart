import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';

class AptPage extends StatefulWidget {
  final String aptHash;
  final Map<String, dynamic> aptInfo;

  const AptPage({super.key, required this.aptHash, required this.aptInfo});

  @override
  State<AptPage> createState() => _AptPageState();
}

class _AptPageState extends State<AptPage> {
  late final CollectionReference<Map<String, dynamic>>
  _aptRef; // final 추가, 타입 명시
  int _startYear = 2006; // 시작 연도
  bool _isFavorite = false; // 찜 상태 관리

  @override
  void initState() {
    super.initState();
    // _aptRef = FirebaseFirestore.instance.collection(widget.aptHash); // 타입 명시하기
    _aptRef = FirebaseFirestore.instance.collection('wydmu17me');
    _checkFavorite(); // 찜 여부 확인하기
  }

  Future<void> _checkFavorite() async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('rollcake')
              .doc('favorite')
              .get();

      if (docSnapshot.exists) {
        // 문서가 있다면 찜 상태 확인하기
        final favoriteData =
            docSnapshot.data() as Map<String, dynamic>?; // 형 변환과 null 확인하기
        if (favoriteData != null && favoriteData['aptHash'] == widget.aptHash) {
          setState(() {
            _isFavorite = true;
          });
        }
      }
    } catch (e) {
      print('Error checking favorite: $e');
    }
  }

  // 찜 추가/제거 함수
  Future<void> _toggleFavorite() async {
    try {
      final favoriteRef = FirebaseFirestore.instance
          .collection('rollcake')
          .doc('favorite');
      if (_isFavorite) {
        // 찜 제거하기
        await favoriteRef.delete();
        setState(() {
          _isFavorite = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('나의 아파트에서 제거되었습니다.')));
      } else {
        // 찜 추가하기
        await favoriteRef.set(widget.aptInfo);
        setState(() {
          _isFavorite = true;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('나의 아파트로 등록되었습니다.')));
      }
    } catch (e) {
      // 오류 처리하기
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('찜 기능에 오류가 발생했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersQuery = _aptRef // _aptRef 사용하기
        .orderBy('deal_ymd')
        .where(
          'deal_ymd',
          isGreaterThanOrEqualTo: '${_startYear}0000', // _startYear 사용하기
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.aptInfo['name']),
        actions: [
          IconButton(
            onPressed: _toggleFavorite, // 찜 토글 함수 호출하기
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
            ), // 찜 상태에 따라 아이콘 변경하기
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAptInfo(widget.aptInfo), // 아파트 정보 표시 위젯 분리하기
          Container(
            color: Colors.black,
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 5), // margin 수정하기
          ),
          Text('검색 시작 연도: $_startYear년'), // _startYear 사용하기
          Slider(
            value: _startYear.toDouble(),
            onChanged: (value) {
              setState(() {
                _startYear = value.toInt();
              });
            },
            min: 2006,
            max: 2023,
          ),
          Expanded(
            child: FirestoreListView<Map<String, dynamic>>(
              query: usersQuery,
              pageSize: 20,
              itemBuilder: (context, snapshot) {
                if (!snapshot.exists) {
                  return const Center(
                    child: CircularProgressIndicator(), // 데이터 로딩 중 표시하기
                  );
                }
                Map<String, dynamic> apt = snapshot.data()!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0), // Padding 추가하기
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // Row 위젯 정렬하기
                      children: [
                        Expanded(
                          // Expanded 추가하기
                          child: Column(
                            // Column 위젯 정렬하기
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('계약 일시: ${apt['deal_ymd']}'),
                              Text('계약 층: ${apt['floor']}층'),
                              Text(
                                '계약 가격: ${double.parse(apt['obj_amt']) / 10000}억',
                              ),
                              Text('전용 면적: ${apt['bldg_area']}㎡'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              emptyBuilder:
                  (context) => const Center(child: Text('매매 데이터가 없습니다.')),
              // Center 위젯 추가하기
              errorBuilder:
                  (context, err, stack) =>
                      Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다.')),
            ),
          ),
        ],
      ),
    );
  }

  // 아파트 정보 표시 위젯
  Widget _buildAptInfo(Map<String, dynamic> aptInfo) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('아파트 이름: ${aptInfo['name']}'),
          Text('아파트 주소: ${aptInfo['address']}'),
          Text('아파트 동 수: ${aptInfo['ALL_DONG_CO']}'),
          Text('아파트 세대 수: ${aptInfo['ALL_HSHLD_CO']}'),
          Text('아파트 주차 대수: ${aptInfo['CNT_PA']}'),
          Text('60㎡ 이하 평형 세대 수: ${aptInfo['KAPTMPAREA60']}'),
          Text('60㎡~85㎡ 이하 평형 세대 수: ${aptInfo['KAPTMPAREA85']}'),
        ],
      ),
    );
  }
}
