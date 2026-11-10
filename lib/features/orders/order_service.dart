import 'package:cloud_functions/cloud_functions.dart';

class OrderService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> createOrder({
    required String productId,
    required int quantity,
    required String paymentMethod,
    required String deliveryMethod,
    String deliveryAddress = '',
    String note = '',
  }) async {
    final result = await _functions.httpsCallable('createMarketplaceOrder').call({
      'productId': productId,
      'quantity': quantity,
      'paymentMethod': paymentMethod,
      'deliveryMethod': deliveryMethod,
      'deliveryAddress': deliveryAddress,
      'note': note,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> updateStatus({
    required String orderId,
    required String status,
    String reason = '',
  }) async {
    final result = await _functions.httpsCallable('updateMarketplaceOrderStatus').call({
      'orderId': orderId,
      'status': status,
      'reason': reason,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> setStaffRole({
    required String uid,
    required String role,
  }) async {
    final result = await _functions.httpsCallable('setStaffRole').call({
      'uid': uid,
      'role': role,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
