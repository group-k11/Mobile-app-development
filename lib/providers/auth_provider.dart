import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isOwner => _currentUser?.isOwner ?? false;
  bool get isStaff => _currentUser?.isStaff ?? false;

  // ─── Initialize ───────────────────────────────────────
  Future<void> initialize() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _currentUser = await _authService.getUserData(firebaseUser.uid);
      notifyListeners();
    }
  }

  // ─── Sign In ──────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _getAuthErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Sign Up (Owner Registration) ─────────────────────
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.createOwnerAccount(
        name: name,
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _getAuthErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Sign Out ─────────────────────────────────────────
  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // ─── Create Staff Account ────────────────────────────
  /// Uses secondary Firebase App — no owner password needed,
  /// owner session stays intact.
  Future<bool> createStaffAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final staffUser = await _authService.createStaffAccount(
        name: name,
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return staffUser != null;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to create staff account: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Delete Staff Account ────────────────────────────
  Future<bool> deleteStaff(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.deleteStaffAccount(uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete staff account';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Get Staff List ──────────────────────────────────
  Future<List<UserModel>> getStaffList() async {
    return await _authService.getAllStaff();
  }

  // ─── Stream Staff List ───────────────────────────────
  Stream<List<UserModel>> get staffStream => _authService.getStaffStream();

  // ─── Password Reset ──────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordReset(email);
      return true;
    } catch (e) {
      _error = 'Failed to send password reset email';
      notifyListeners();
      return false;
    }
  }

  // ─── Clear Error ──────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── Auth Error Messages ──────────────────────────────
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Invalid password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak (min 6 characters)';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        if (code.contains('user-not-found')) {
          return 'No account found with this email';
        }
        if (code.contains('wrong-password') ||
            code.contains('invalid-credential')) {
          return 'Invalid email or password';
        }
        if (code.contains('email-already-in-use')) {
          return 'An account already exists with this email';
        }
        if (code.contains('network')) {
          return 'Network error. Check your internet connection.';
        }
        return 'Authentication failed. Please try again.';
    }
  }
}
