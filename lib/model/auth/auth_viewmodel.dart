import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hackethos4u/model/auth/auth_model.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;

  TokenModel? _loginTokenData;
  TokenModel? get loginTokenData => _loginTokenData;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<TokenModel?> login(String email, String password) async {
    final creds = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final token = await creds.user?.getIdToken();
    _loginTokenData = TokenModel(token: token ?? '');
    // Persist basic profile for existing UI expectations
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', creds.user?.displayName ?? 'Student');
    await prefs.setString('userEmail', creds.user?.email ?? email);
    notifyListeners();
    return _loginTokenData;
  }

  Future<TokenModel?> register(
      String name, String email, String password) async {
    final creds = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await creds.user?.updateDisplayName(name);
    final token = await creds.user?.getIdToken();
    _loginTokenData = TokenModel(token: token ?? '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    notifyListeners();
    return _loginTokenData;
  }

  Future<void> logout() async {
    await _auth.signOut();
    _loginTokenData = null;
    notifyListeners();
  }
}
