import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/models/app_user.dart';

/// Extended user model that adds profile photo support.
class MemberProfile {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final UserStatus status;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MemberProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.status,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  factory MemberProfile.fromMap(Map<String, dynamic> map, String uid) {
    return MemberProfile(
      uid: uid,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.MEMBER,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UserStatus.ACTIVE,
      ),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  factory MemberProfile.fromAppUser(AppUser user) {
    return MemberProfile(
      uid: user.uid,
      fullName: user.fullName,
      email: user.email,
      phoneNumber: user.phoneNumber,
      role: user.role,
      status: user.status,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'role': role.name,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  MemberProfile copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    UserStatus? status,
    DateTime? updatedAt,
  }) {
    return MemberProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role, // role is never changed via copyWith
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAdmin =>
      role == UserRole.ADMIN ||
      role == UserRole.SUPER_ADMIN ||
      role == UserRole.FINANCE_OFFICER;
}
