import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current Firebase user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Sign In ──────────────────────────────────────────
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        return await getUserData(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // ─── Sign Out ─────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Create Staff Account (Owner Only) ────────────────
  /// Uses a secondary Firebase App instance so the owner session
  /// is never interrupted.
  Future<UserModel?> createStaffAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    FirebaseApp? secondaryApp;

    try {
      // Create a secondary Firebase App to avoid signing out the owner
      secondaryApp = await Firebase.initializeApp(
        name: 'StaffCreation_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        final user = UserModel(
          userId: credential.user!.uid,
          name: name,
          email: email.trim(),
          role: kRoleStaff,
          createdAt: DateTime.now(),
        );

        // Write to Firestore using the main app's Firestore instance
        await _firestore
            .collection(kUsersCollection)
            .doc(credential.user!.uid)
            .set(user.toMap());

        // Sign out from secondary app
        await secondaryAuth.signOut();

        return user;
      }
      return null;
    } catch (e) {
      debugPrint('Staff creation error: $e');
      rethrow;
    } finally {
      // Clean up the secondary app
      try {
        if (secondaryApp != null) {
          await secondaryApp.delete();
        }
      } catch (_) {}
    }
  }

  // ─── Create Owner Account (Sign Up) ──────────────────
  Future<UserModel?> createOwnerAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        final user = UserModel(
          userId: credential.user!.uid,
          name: name,
          email: email.trim(),
          role: kRoleOwner,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(kUsersCollection)
            .doc(credential.user!.uid)
            .set(user.toMap());

        return user;
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // ─── Delete Staff Account ─────────────────────────────
  /// Removes a staff user's Firestore document.
  /// Note: Firebase Auth account deletion requires admin SDK or
  /// the user themselves. We only delete the Firestore doc here.
  Future<void> deleteStaffAccount(String uid) async {
    await _firestore.collection(kUsersCollection).doc(uid).delete();
  }

  // ─── Password Reset ──────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─── Get User Data ───────────────────────────────────
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(kUsersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── Get All Staff ───────────────────────────────────
  Future<List<UserModel>> getAllStaff() async {
    try {
      final snapshot = await _firestore
          .collection(kUsersCollection)
          .where('role', isEqualTo: kRoleStaff)
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─── Stream Staff List ───────────────────────────────
  Stream<List<UserModel>> getStaffStream() {
    return _firestore
        .collection(kUsersCollection)
        .where('role', isEqualTo: kRoleStaff)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }
}
