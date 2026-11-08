import 'dart:convert';
import 'package:http/http.dart' as http;

/// PENTING: API key TriPay tidak boleh disimpan di aplikasi Flutter.
/// Aplikasi harus memanggil backend Anda, lalu backend yang berkomunikasi
/// dengan TriPay menggunakan credential rahasia.
class TripayService {
  final String backendBaseUrl;
  TripayService(this.backendBaseUrl);

  Future<Map<String, dynamic>> createTopUp({
    required String packageId,
    required String paymentMethod,
  }) async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/payments/tripay/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'package_id': packageId,
        'payment_method': paymentMethod,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal membuat transaksi top up.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
