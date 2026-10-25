import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { resident, guard, admin }

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    required this.flat,
    required this.role,
  });

  final String uid;
  final String name;
  final String phone;
  final String flat;
  final UserRole role;

  bool get isResident => role == UserRole.resident;
  bool get isGuard => role == UserRole.guard;
  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: (d['name'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      flat: (d['flat'] as String?) ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == d['role'],
        orElse: () => UserRole.resident,
      ),
    );
  }
}
