class User {
  const User({
    required this.idUser,
    required this.namaLengkap,
    required this.email,
    required this.role,
  });

  final int idUser;
  final String namaLengkap;
  final String email;
  final String role;

  bool get isAdmin => role == 'Admin';

  factory User.fromJson(Map<String, dynamic> json) => User(
        idUser: _toInt(json['id_user']),
        namaLengkap: json['nama_lengkap'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id_user': idUser,
        'nama_lengkap': namaLengkap,
        'email': email,
        'role': role,
      };
}

int _toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
