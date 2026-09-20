import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/app_user.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      // Retry up to 5 times with a short delay to handle the race condition
      // where Firebase Auth fires before the Firestore doc has been written
      // (e.g. immediately after registration or Google Sign-In for new users).
      for (int attempt = 0; attempt < 5; attempt++) {
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data() != null) {
            return AppUser.fromMap(doc.data()!, user.uid);
          }
        } catch (e) {
          // Ignore transient errors and retry
        }
        if (attempt < 4) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      return null;
    });
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      final appUser = AppUser(
        uid: user.uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        role: UserRole.MEMBER,
        status: UserStatus.ACTIVE,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
      await sendEmailVerification();
    }
  }

  Future<void> signInWithGoogle() async {
    UserCredential userCredential;

    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      userCredential = await _auth.signInWithPopup(googleProvider);
    } else {
      // google_sign_in v7: use the singleton and authenticate().
      // initialize() (with serverClientId) is called once at app startup in
      // FirebaseSetup.initialize(), so we call authenticate() directly here.
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      // In v7, .authentication is a synchronous getter — no await needed.
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      userCredential = await _auth.signInWithCredential(credential);
    }

    final user = userCredential.user;

    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final appUser = AppUser(
          uid: user.uid,
          fullName: user.displayName ?? 'Google User',
          email: user.email ?? '',
          phoneNumber: user.phoneNumber ?? '',
          role: UserRole.MEMBER,
          status: UserStatus.ACTIVE,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
      }
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  bool get isEmailVerified {
    return _auth.currentUser?.emailVerified ?? false;
  }
}
