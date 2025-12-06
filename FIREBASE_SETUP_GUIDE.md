// HƯỚNG DẪN SETUP FIREBASE REALTIME DATABASE CHO FLUTTER

// ========== BƯỚC 1: TẠO FIREBASE PROJECT ==========
/*
1. Truy cập https://console.firebase.google.com
2. Click "Tạo dự án" (Create project)
3. Điền tên: "green_route_app"
4. Skip Google Analytics (hoặc bật nếu muốn)
5. Click "Tạo dự án"
6. Chờ hoàn thành
*/

// ========== BƯỚC 2: THÊM APP VÀO FIREBASE ==========
/*
A. CHO ANDROID:
   1. Vào Project Settings > Ứng dụng và dịch vụ
   2. Click "Thêm ứng dụng" > Chọn Android
   3. Điền thông tin:
      - Tên gói: com.example.green_route_app
      - Biệt danh (optional): Green Route App
   4. Download google-services.json
   5. Copy vào: android/app/google-services.json
   6. Tiếp theo, Firebase CLI sẽ hướng dẫn

B. CHO WEB:
   1. Click "Thêm ứng dụng" > Chọn Web (</>)
   2. Điền tên: "green_route_app-web"
   3. Copy Config JavaScript (sẽ dùng sau)
   4. Click "Tiếp tục tới console"
*/

// ========== BƯỚC 3: SETUP REALTIME DATABASE ==========
/*
1. Vào Firebase Console > Realtime Database
2. Click "Tạo cơ sở dữ liệu"
3. Chọn vị trí: Southeast Asia (Singapore) cho tốc độ tốt
4. Chế độ: "Bắt đầu ở chế độ kiểm tra"
5. Bật Realtime Database
6. Thiết lập Rules (cho phép read/write mọi người trong khi test):

{
  "rules": {
    ".read": true,
    ".write": true
  }
}

⚠️ LƯU Ý: Trong production, cần setup auth rules an toàn hơn
*/

// ========== BƯỚC 4: THÊM FLUTTER FIREBASE PACKAGES ==========
/*
Chạy command:

flutter pub add firebase_core
flutter pub add firebase_database
flutter pub add firebase_auth (optional, nếu muốn auth)

Hoặc thêm vào pubspec.yaml:
dependencies:
  firebase_core: ^2.24.0
  firebase_database: ^10.2.0
*/

// ========== BƯỚC 5: SETUP CODE ANDROID ==========
/*
File: android/app/build.gradle

Thêm ở cuối file:
apply plugin: 'com.google.gms.google-services'

File: android/build.gradle

Thêm ở dependencies:
classpath 'com.google.gms:google-services:4.3.15'
*/

// ========== BƯỚC 6: SETUP CODE WEB ==========
/*
File: web/index.html

Thêm trước </body>:

<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-database.js"></script>

<script>
  const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "your-project.firebaseapp.com",
    databaseURL: "https://your-project-default-rtdb.asia-southeast1.firebasedatabase.app",
    projectId: "your-project",
    storageBucket: "your-project.appspot.com",
    messagingSenderId: "YOUR_SENDER_ID",
    appId: "YOUR_APP_ID"
  };

  firebase.initializeApp(firebaseConfig);
</script>
*/

// ========== BƯỚC 7: INITIALIZE FIREBASE TRONG CODE ==========
/*
File: lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
*/

// ========== BƯỚC 8: TẠO FIREBASE SERVICE ==========
/*
File: lib/core/services/firebase_service.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  static final instance = FirebaseService._();
  FirebaseService._();

  final _db = FirebaseDatabase.instance.ref();

  // Thêm bidding order
  Future<void> addBiddingOrder(Map<String, dynamic> order) async {
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    await _db.child('bidding_orders').child(orderId).set({
      'id': orderId,
      'from': order['from'],
      'to': order['to'],
      'goods': order['goods'],
      'weight': order['weight'],
      'price': order['price'],
      'pickup': order['pickup'],
      'deliver': order['deliver'],
      'shipperName': order['shipperName'],
      'bids': [],
      'createdAt': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Bidding order added: $orderId');
  }

  // Lấy tất cả bidding orders (realtime)
  Stream<List<Map<String, dynamic>>> getBiddingOrdersStream() {
    return _db.child('bidding_orders').onValue.map((event) {
      if (event.snapshot.value == null) return [];
      
      final data = event.snapshot.value as Map;
      return data.entries.map((e) {
        final order = Map<String, dynamic>.from(e.value as Map);
        return order;
      }).toList();
    });
  }

  // Thêm bid vào order
  Future<void> addBidToOrder(String orderId, Map<String, dynamic> bid) async {
    final bidId = DateTime.now().millisecondsSinceEpoch.toString();
    await _db
        .child('bidding_orders')
        .child(orderId)
        .child('bids')
        .child(bidId)
        .set(bid);
    debugPrint('✅ Bid added to order: $orderId');
  }

  // Thêm empty trip
  Future<void> addEmptyTrip(Map<String, dynamic> trip) async {
    final tripId = trip['id'];
    await _db.child('empty_trips').child(tripId).set(trip);
    debugPrint('✅ Empty trip added: $tripId');
  }

  // Lấy tất cả empty trips (realtime)
  Stream<List<Map<String, dynamic>>> getEmptyTripsStream() {
    return _db.child('empty_trips').onValue.map((event) {
      if (event.snapshot.value == null) return [];
      
      final data = event.snapshot.value as Map;
      return data.entries.map((e) {
        final trip = Map<String, dynamic>.from(e.value as Map);
        return trip;
      }).toList();
    });
  }

  // Shipper join trip
  Future<void> addShipperToTrip(String tripId, Map<String, dynamic> shipper) async {
    final shipperId = shipper['shipperId'];
    await _db
        .child('empty_trips')
        .child(tripId)
        .child('joinedShippers')
        .child(shipperId)
        .set(shipper);
    debugPrint('✅ Shipper joined trip: $tripId');
  }
}
*/

// ========== BƯỚC 9: UPDATE SCREENS DÙNG FIREBASE ==========
/*
Example - FindDriverScreen:

import 'package:firebase_database/firebase_database.dart';
import '../../../core/services/firebase_service.dart';

class FindDriverScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseService.instance.getBiddingOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text('Chưa có đơn'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (ctx, i) {
              final order = orders[i];
              return Card(
                child: ListTile(
                  title: Text('${order['from']} → ${order['to']}'),
                  subtitle: Text(order['goods']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Example - CreateOrderScreen:

import '../../../core/services/firebase_service.dart';

void _submitOrder() async {
  // ... validation code ...

  await FirebaseService.instance.addBiddingOrder({
    'from': _fromCtrl.text,
    'to': _toCtrl.text,
    'goods': _goodsCtrl.text,
    'weight': _weightCtrl.text,
    'price': _priceCtrl.text,
    'pickup': _pickupCtrl.text,
    'deliver': _deliverCtrl.text,
    'shipperName': 'Công ty ABC',
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Đã đăng tìm tài xế thành công!')),
  );
}
*/

// ========== BƯỚC 10: FIREBASE REALTIME DATABASE RULES (PRODUCTION) ==========
/*
{
  "rules": {
    "bidding_orders": {
      ".read": true,
      ".write": "root.child('users').child(auth.uid).exists()",
      "$orderId": {
        ".validate": "newData.hasChildren(['id', 'from', 'to'])"
      }
    },
    "empty_trips": {
      ".read": true,
      ".write": "root.child('users').child(auth.uid).exists()",
      "$tripId": {
        ".validate": "newData.hasChildren(['id', 'driverId'])"
      }
    }
  }
}
*/

// ========== LỢI ÍCH CỦA FIREBASE REALTIME DATABASE ==========
/*
✅ Realtime sync: Dữ liệu cập nhật tức thì trên tất cả devices
✅ Offline support: Flutter Firebase hỗ trợ offline persistence
✅ Automatic scalability: Firebase tự động scale
✅ Security rules: Kiểm soát read/write quyền
✅ No backend cần setup: Google quản lý infrastructure
✅ Dễ test: Có Firebase Console để debug
✅ Miễn phí tier: Free tier đủ cho app nhỏ
*/

// ========== TESTING VỚI FIREBASE CONSOLE ==========
/*
1. Mở Firebase Console > Realtime Database
2. Click "Data" tab
3. Có thể manually thêm dữ liệu test
4. Xem realtime updates khi app gửi dữ liệu
5. Debug bằng Rules validation errors
*/
