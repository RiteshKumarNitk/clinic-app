/// The signed-in account, from `GET /api/me`.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? fullName : parts.first;
  }

  /// Everything after the first word; the booking API requires a non-empty
  /// last name, so a single-word name falls back to the first name.
  String get lastName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.length > 1 ? parts.sublist(1).join(' ') : firstName;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final email = (json['email'] as String?) ?? '';
    final name = (json['fullName'] as String?)?.trim();
    return AppUser(
      id: json['id'] as String,
      email: email,
      fullName: name == null || name.isEmpty ? email : name,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'phone': phone,
    'avatarUrl': avatarUrl,
  };
}
