import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'app_user.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Starts phone verification. [onCodeSent] receives the verification id that
  /// must be passed to [verifyOtp]. On some Android devices the SMS is read
  /// automatically, in which case the user is signed in without typing a code.
  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          onError(e.message ?? 'Sign in failed');
        }
      },
      verificationFailed: (e) => onError(e.message ?? 'Verification failed'),
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> verifyOtp(String verificationId, String smsCode) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Stream<AppUser?> watchProfile(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? AppUser.fromDoc(snap) : null);
  }

  /// New accounts are always residents. Guards and admins are promoted by an
  /// admin directly in the Firestore console (see README) - Firestore rules
  /// prevent users from changing their own role.
  Future<void> createProfile({
    required User user,
    required String name,
    required String flat,
  }) {
    return _db.collection('users').doc(user.uid).set({
      'name': name,
      'flat': flat,
      'phone': user.phoneNumber ?? '',
      'role': UserRole.resident.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveFcmToken(String uid, String token) {
    return _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  Future<void> signOut() => _auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);

/// The signed-in user's Firestore profile (role, flat, ...). Null if the user
/// is signed out or has not completed profile setup yet.
final profileProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchProfile(user.uid);
});
