import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' as dart_io;
import 'package:flutter/foundation.dart';
import '../model/user/user_model.dart';
import 'firebase_storage_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ===== EMAIL/PASSWORD AUTH =====

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Create user profile in Firestore
      await _createUserProfile(credential.user!, name, email);

      return credential;
    } catch (e) {
      // print('Error signing up: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Note: Admin users can also use the user app if needed
      // This allows flexibility for testing and cross-app functionality

      // Update last login in Firestore
      await _updateLastLogin(credential.user!);

      return credential;
    } catch (e) {
      // print('Error signing in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      // print('Error signing out: $e');
      rethrow;
    }
  }

  // ===== GOOGLE SIGN IN =====

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Ensure GoogleSignIn is initialized (required for 7.x API)
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb
            ? '695695824497-2l8dhhqg2he9n58nmrtknco2dpbjta3s.apps.googleusercontent.com'
            : null,
      );

      // Try lightweight (silent) auth first if supported, then fall back to interactive
      GoogleSignInAccount? googleUser = await GoogleSignIn.instance
              .attemptLightweightAuthentication() ??
          await GoogleSignIn.instance.authenticate(scopeHint: const ['email', 'profile']);

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      final userCredential = await _auth.signInWithCredential(credential);

      // Create user profile in Firestore if new user
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _createUserProfile(
          userCredential.user!,
          userCredential.user!.displayName ?? 'User',
          userCredential.user!.email ?? '',
        );
      } else {
        // Update last login for existing user
        await _updateLastLogin(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // ===== FIRESTORE USER PROFILE =====

  // Create user profile in Firestore
  Future<void> _createUserProfile(User user, String name, String email) async {
    try {
      final userData = {
        'id': user.uid,
        'fullName': name,
        'email': email,
        'phone': user.phoneNumber,
        'role': 'student',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'photoURL': user.photoURL,
        'preferences': {
          'notifications': true,
          'emailUpdates': true,
          'theme': 'light',
        },
        'stats': {
          'coursesEnrolled': 0,
          'coursesCompleted': 0,
          'totalTimeSpent': 0,
          'certificatesEarned': 0,
        },
      };

      // Use set with merge to avoid overwriting existing data
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
      print('✅ User profile created successfully in Firestore');
    } catch (e) {
      print('❌ Error creating user profile: $e');
      // Don't rethrow for profile creation as it's not critical for auth
      // The user can still sign in and we can retry profile creation later
    }
  }

  // Update last login
  Future<void> _updateLastLogin(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error updating last login: $e');
      // Don't rethrow as this is not critical
    }
  }

  // Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      // print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile in Firestore and FirebaseAuth display name/email
  Future<void> updateUserProfile(UserModel user,
      {String? fullName, String? email, String? bio}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      // Update FirebaseAuth profile if provided
      if (fullName != null && fullName.trim().isNotEmpty) {
        await currentUser.updateDisplayName(fullName.trim());
      }
      if (email != null &&
          email.trim().isNotEmpty &&
          email.trim() != currentUser.email) {
        // Use verified email update to support current auth SDK across platforms
        await currentUser.verifyBeforeUpdateEmail(email.trim());
      }

      final Map<String, dynamic> update = {
        'firstname': user.firstname,
        'lastname': user.lastname,
        'phone': user.phone,
        'preferences': user.preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (fullName != null) update['fullName'] = fullName;
      if (email != null) update['email'] = email;
      if (bio != null) update['bio'] = bio;

      await _firestore.collection('users').doc(currentUser.uid).update(update);
    } catch (e) {
      // print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage(String imagePath) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      // Upload to Firebase Storage
      final fileName =
          'profile_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      String? downloadUrl;
      if (kIsWeb) {
        // For web, we need to handle file uploads differently
        throw Exception(
            'Web file upload not supported in this method. Use uploadBytes instead.');
      } else {
        final file = dart_io.File(imagePath);
        downloadUrl = await FirebaseStorageService.uploadImage(
          imageFile: file,
          folder: 'users/${currentUser.uid}/avatars',
          fileName: fileName,
        );
      }

      if (downloadUrl != null) {
        // Update user profile with image URL
        await _firestore.collection('users').doc(currentUser.uid).update({
          'profileImage': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return downloadUrl;
      }

      return null;
    } catch (e) {
      // print('Error uploading profile image: $e');
      return null;
    }
  }

  // ===== PASSWORD RESET =====

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // print('Attempting to send password reset email to: $email');

      // Validate email format
      if (!email.contains('@') || !email.contains('.')) {
        throw Exception('Invalid email format');
      }

      await _auth.sendPasswordResetEmail(email: email);
      // print('Password reset email sent successfully to: $email');

      // Additional logging for debugging
      // print('Firebase project ID: ${_auth.app.options.projectId}');
      // print('Firebase auth domain: ${_auth.app.options.authDomain}');
    } catch (e) {
      // print('Error sending password reset email: $e');
      // print('Error type: ${e.runtimeType}');

      // Provide more specific error messages
      if (e.toString().contains('user-not-found')) {
        throw Exception('No account found with this email address');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Invalid email address format');
      } else if (e.toString().contains('too-many-requests')) {
        throw Exception('Too many requests. Please try again later');
      } else {
        rethrow;
      }
    }
  }

  // ===== USER MANAGEMENT =====

  // Delete user account
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete user account
        await user.delete();
        // print('User account deleted successfully');
      }
    } catch (e) {
      // print('Error deleting user account: $e');
      rethrow;
    }
  }

  // Update user password
  Future<void> updateUserPassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        // print('User password updated successfully');
      }
    } catch (e) {
      // print('Error updating user password: $e');
      rethrow;
    }
  }

  // ===== DEMO AUTH FOR TESTING =====

  // Demo user registration (for testing without Firebase)
  static Future<bool> registerDemoUser(
      String email, String password, String name) async {
    try {
      // For demo purposes, we'll use a simple in-memory storage
      // In production, this should always use Firebase
      final demoUsers = <String, Map<String, dynamic>>{
        'demo@hackethos4u.com': {
          'password': 'password123',
          'name': 'Demo User',
          'email': 'demo@hackethos4u.com',
        },
      };

      final emailLower = email.toLowerCase();

      if (demoUsers.containsKey(emailLower)) {
        return false; // User already exists
      }

      demoUsers[emailLower] = {
        'password': password,
        'name': name,
        'email': emailLower,
      };

      return true;
    } catch (e) {
      // print('Error registering demo user: $e');
      return false;
    }
  }

  // Demo user verification (for testing without Firebase)
  static Future<Map<String, dynamic>?> verifyDemoUser(
      String email, String password) async {
    try {
      final demoUsers = <String, Map<String, dynamic>>{
        'demo@hackethos4u.com': {
          'password': 'password123',
          'name': 'Demo User',
          'email': 'demo@hackethos4u.com',
        },
        'test@edutiv.com': {
          'password': 'test123',
          'name': 'Test User',
          'email': 'test@edutiv.com',
        },
      };

      final emailLower = email.toLowerCase();

      if (demoUsers.containsKey(emailLower)) {
        final userData = demoUsers[emailLower]!;
        if (userData['password'] == password) {
          return userData;
        }
      }

      return null;
    } catch (e) {
      // print('Error verifying demo user: $e');
      return null;
    }
  }

  // Check if demo email exists
  static bool demoEmailExists(String email) {
    final demoUsers = <String, Map<String, dynamic>>{
      'demo@hackethos4u.com': {
        'password': 'password123',
        'name': 'Demo User',
        'email': 'demo@hackethos4u.com',
      },
      'test@edutiv.com': {
        'password': 'test123',
        'name': 'Test User',
        'email': 'test@edutiv.com',
      },
    };

    return demoUsers.containsKey(email.toLowerCase());
  }
}
