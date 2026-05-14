class UserModel {
  final String uid;
  final String email;
  final String role; // 'bireysel' or 'sme'
  final String fullName;
  final String? businessName; // null if bireysel

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.fullName,
    this.businessName,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'fullName': fullName,
      'businessName': businessName,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      role: map['role'] ?? 'bireysel',
      fullName: map['fullName'] ?? '',
      businessName: map['businessName'],
    );
  }
}
