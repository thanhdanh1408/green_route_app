// lib/features/driver/models/order_model.dart
import 'dart:convert';

class OrderModel {
  final String id;
  final String from;
  final String to;
  final String fromDetail;
  final String toDetail;
  final String weight;
  final String price;
  final String receiveDate;
  final String deliverDate;
  final String? shipperName;
  final String? shipperPhone;
  final String bidStatus; // 'available' | 'waiting' | 'accepted' | 'completed'

  const OrderModel({
    required this.id,
    required this.from,
    required this.to,
    required this.fromDetail,
    required this.toDetail,
    required this.weight,
    required this.price,
    required this.receiveDate,
    required this.deliverDate,
    this.shipperName,
    this.shipperPhone,
    this.bidStatus = 'available',
  });

  // CHUYỂN THÀNH MAP ĐỂ LƯU SHARED_PREFERENCES
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'fromDetail': fromDetail,
      'toDetail': toDetail,
      'weight': weight,
      'price': price,
      'receiveDate': receiveDate,
      'deliverDate': deliverDate,
      'shipperName': shipperName,
      'shipperPhone': shipperPhone,
      'bidStatus': bidStatus,
    };
  }

  // TỪ MAP → OrderModel
  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String,
      from: map['from'] as String,
      to: map['to'] as String,
      fromDetail: map['fromDetail'] as String,
      toDetail: map['toDetail'] as String,
      weight: map['weight'] as String,
      price: map['price'] as String,
      receiveDate: map['receiveDate'] as String,
      deliverDate: map['deliverDate'] as String,
      shipperName: map['shipperName'] as String?,
      shipperPhone: map['shipperPhone'] as String?,
      bidStatus: map['bidStatus'] as String? ?? 'available',
    );
  }

  // CHUYỂN THÀNH JSON STRING
  String toJson() => jsonEncode(toMap());

  // TỪ JSON STRING → OrderModel
  factory OrderModel.fromJson(String source) =>
      OrderModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  // COPY WITH METHOD ĐỂ THAY ĐỔI TRẠNG THÁI
  OrderModel copyWith({String? bidStatus}) {
    return OrderModel(
      id: id,
      from: from,
      to: to,
      fromDetail: fromDetail,
      toDetail: toDetail,
      weight: weight,
      price: price,
      receiveDate: receiveDate,
      deliverDate: deliverDate,
      shipperName: shipperName,
      shipperPhone: shipperPhone,
      bidStatus: bidStatus ?? this.bidStatus,
    );
  }
}
