class UserModel {
  final String uid;
  final String username;
  final String email;
  final String profilePic;
  final String role; 
  final bool isVerified; 

  // [UPGRADE CTO] Mengubah constructor menjadi 'const' untuk efisiensi memori (RAM)
  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.profilePic,
    required this.role,
    this.isVerified = false,
  });

  // [UPGRADE CTO] Objek kosong default untuk inisialisasi awal (menghindari NullPointerException / Layar Merah)
  factory UserModel.empty() {
    return const UserModel(
      uid: '',
      username: 'Pengguna Flowa',
      email: '',
      profilePic: '',
      role: 'user',
      isVerified: false,
    );
  }

  // Mengubah data dari Database (JSON) menjadi objek Flutter dengan Pengamanan Super
  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        // Pengamanan tipe data: Memaksa konversi ke String untuk mencegah Crash 
        // jika server Firebase tidak sengaja mengirim tipe data angka (int)
        uid: json['uid']?.toString() ?? '',
        username: json['username']?.toString() ?? 'Pengguna Flowa',
        email: json['email']?.toString() ?? '',
        profilePic: json['profilePic']?.toString() ?? '',
        role: json['role']?.toString() ?? 'user', 
        isVerified: json['isVerified'] as bool? ?? false,
      );
    } catch (e) {
      // Jika terjadi anomali data dari server, kembalikan objek kosong, BUKAN membuat aplikasi crash
      return UserModel.empty();
    }
  }

  // Mengubah data dari Flutter menjadi JSON untuk disimpan ke Database
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'profilePic': profilePic,
      'role': role,
      'isVerified': isVerified,
    };
  }

  // [UPGRADE CTO] Method copyWith WAJIB ada di standar industri untuk State Management
  // Memungkinkan kita mengubah 1 variabel (misal update profilePic) tanpa merusak variabel lain
  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? profilePic,
    String? role,
    bool? isVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
