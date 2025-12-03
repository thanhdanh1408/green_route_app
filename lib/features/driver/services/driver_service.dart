// lib/features/driver/services/driver_service.dart
import '../models/order_model.dart';

class DriverService {
  static final DriverService _instance = DriverService._();
  factory DriverService() => _instance;
  DriverService._();

  Future<List<OrderModel>> getAvailableOrders() async {
    await Future.delayed(const Duration(seconds: 1)); // Giả lập API
    return [
      OrderModel(
        id: 'GH001',
        from: 'Gia Lai',
        to: 'Đắk Lắk',
        fromDetail: 'Pleiku, Gia Lai',
        toDetail: 'Buôn Ma Thuột, Đắk Lắk',
        weight: '5 tấn',
        price: '3.500.000 đ',
        receiveDate: '25/11/2025',
        deliverDate: '26/11/2025',
        shipperName: 'Chủ hàng Trần Thị Lan',
        shipperPhone: '0977123456',
      ),
      OrderModel(
        id: 'GH002',
        from: 'Gia Lai',
        to: 'Đắk Lắk',
        fromDetail: 'An Khê, Gia Lai',
        toDetail: 'Krông Năng, Đắk Lắk',
        weight: '8 tấn',
        price: '4.200.000 đ',
        receiveDate: '24/11/2025',
        deliverDate: '27/11/2025',
        shipperName: 'Công ty ABC',
        shipperPhone: '0935123456',
      ),
    ];
  }
}