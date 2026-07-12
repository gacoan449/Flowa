class UserModel {
  final String uid;
  final String username;
  final String email;
  final String profilePic;
  final String role; // Isi nilai ini: 'user' atau 'creator'
  final bool isVerified; // Untuk centang biru kreator resmi

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.profilePic,
    required this.role,
    this.isVerified = false,
  });

  // Mengubah data dari Database (JSON) menjadi objek Flutter
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      username: json['username'] ?? 'Pengguna Flowa',
      email: json['email'] ?? '',
      profilePic: json['profilePic'] ?? '',
      role: json['role'] ?? 'user', // Default sebagai user biasa jika kosong
      isVerified: json['isVerified'] ?? false,
    );
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
}
