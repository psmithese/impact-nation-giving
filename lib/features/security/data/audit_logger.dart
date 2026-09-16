import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> logAction({
    required String adminId,
    required String action,
    required String targetId,
    required String targetType,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _firestore.collection('audit_logs').add({
        'adminId': adminId,
        'action': action,
        'targetId': targetId,
        'targetType': targetType,
        'details': details,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Failed to audit log, swallow for now or send to Crashlytics
    }
  }
}
