import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> createOrder({
    required String productId,
    required int quantity,
    required String paymentMethod,
    required String deliveryMethod,
    String deliveryAddress = '',
    String note = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Silakan login terlebih dahulu.');
    if (quantity < 1 || quantity > 99) throw Exception('Jumlah barang tidak valid.');
    if (paymentMethod != 'cod') throw Exception('Saat ini pembayaran yang tersedia hanya COD.');

    final productRef = _db.collection('products').doc(productId);
    final settingsRef = _db.collection('app_config').doc('platform');
    final orderRef = _db.collection('orders').doc();

    return _db.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);
      final settingsSnapshot = await transaction.get(settingsRef);
      if (!productSnapshot.exists) throw Exception('Produk tidak ditemukan.');
      final product = productSnapshot.data()!;
      final settings = settingsSnapshot.data() ?? <String, dynamic>{};

      if (settings['maintenanceMode'] == true) throw Exception('Flowa sedang dalam pemeliharaan.');
      if (settings['ordersEnabled'] == false) throw Exception('Penerimaan pesanan sedang dinonaktifkan.');
      if (settings['codEnabled'] == false) throw Exception('COD sedang dinonaktifkan.');
      if (product['status'] != 'active') throw Exception('Produk tidak tersedia.');
      if (product['sellerId'] == user.uid) throw Exception('Kamu tidak dapat membeli produk sendiri.');

      final options = product['deliveryOptions'];
      if (options is List && !options.contains(deliveryMethod)) {
        throw Exception('Metode serah terima tidak tersedia pada iklan ini.');
      }
      if (!['delivery', 'meetup'].contains(deliveryMethod)) {
        throw Exception('Metode serah terima tidak valid.');
      }
      if (deliveryMethod == 'delivery' && deliveryAddress.trim().length < 8) {
        throw Exception('Masukkan alamat lengkap penerima.');
      }

      final stock = (product['stock'] as num?)?.toInt() ?? 0;
      if (stock < quantity) throw Exception('Stok produk tidak mencukupi.');
      final unitPrice = (product['price'] as num?)?.toInt() ?? 0;
      if (unitPrice <= 0) throw Exception('Harga produk tidak valid.');

      final subtotal = unitPrice * quantity;
      final nextStock = stock - quantity;
      transaction.update(productRef, {
        'stock': nextStock,
        'status': nextStock == 0 ? 'sold_out' : 'active',
        'lastOrderId': orderRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(orderRef, {
        'orderId': orderRef.id,
        'buyerId': user.uid,
        'sellerId': product['sellerId'],
        'productId': productId,
        'productTitle': product['title'] ?? 'Produk',
        'productImage': product['imageUrl'] ?? '',
        'quantity': quantity,
        'unitPrice': unitPrice,
        'subtotal': subtotal,
        'serviceFee': 0,
        'total': subtotal,
        'paymentMethod': 'cod',
        'paymentStatus': 'pay_on_delivery',
        'deliveryMethod': deliveryMethod,
        'deliveryAddress': deliveryMethod == 'delivery' ? deliveryAddress.trim().substring(0, deliveryAddress.trim().length.clamp(0, 500)) : '',
        'note': note.trim().substring(0, note.trim().length.clamp(0, 500)),
        'status': 'awaiting_confirmation',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': [{
          'status': 'awaiting_confirmation',
          'by': user.uid,
          'at': Timestamp.now(),
        }],
      });
      return {
        'orderId': orderRef.id,
        'total': subtotal,
        'status': 'awaiting_confirmation',
      };
    });
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
