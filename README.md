# PasarKomunitas

MVP Super-App Ekonomi Lokal tanpa AI/LLM.

## Autentikasi
- Firebase Authentication Email/Password.
- Tidak menggunakan Google Sign-In.
- Tidak menggunakan OTP.

## Koin
Pembelian koin dirancang melalui gateway TriPay. Credential rahasia TriPay **wajib disimpan di backend**, bukan di APK Flutter.

## Setup
1. Buat proyek Firebase.
2. Aktifkan Authentication > Email/Password.
3. Jalankan `flutterfire configure` untuk membuat `lib/firebase_options.dart`.
4. Konfigurasikan backend endpoint `/payments/tripay/create`.
5. Tambahkan webhook backend untuk memverifikasi status pembayaran TriPay sebelum menambah saldo koin.

Jangan menambah saldo hanya dari callback aplikasi pengguna.
