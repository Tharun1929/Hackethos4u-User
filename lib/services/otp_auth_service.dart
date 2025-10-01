import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class OTPAuthService {
  static final OTPAuthService _instance = OTPAuthService._internal();
  factory OTPAuthService() => _instance;
  OTPAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // OTP configuration
  static const int _otpLength = 6;
  static const int _otpExpiryMinutes = 5;
  static const int _maxAttempts = 3;
  static const int _resendCooldownSeconds = 60;

  // Generate OTP
  String _generateOTP() {
    final random = Random();
    final otp = StringBuffer();

    for (int i = 0; i < _otpLength; i++) {
      otp.write(random.nextInt(10));
    }

    return otp.toString();
  }

  // Send OTP via SMS (mock implementation)
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      // Generate OTP
      final otp = _generateOTP();
      final expiryTime =
          DateTime.now().add(Duration(minutes: _otpExpiryMinutes));

      // Store OTP in Firestore
      await _firestore.collection('otp_verifications').doc(phoneNumber).set({
        'otp': otp,
        'expiryTime': Timestamp.fromDate(expiryTime),
        'attempts': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false,
      });

      // In a real app, you would integrate with SMS service like Twilio, AWS SNS, etc.
      // For now, we'll log the OTP for testing
      // print('🔐 OTP for $phoneNumber: $otp (Expires in $_otpExpiryMinutes minutes)');

      // Store phone number for verification
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_phone_number', phoneNumber);
      await prefs.setString('otp_sent_time', DateTime.now().toIso8601String());

      return true;
    } catch (e) {
      // print('Error sending OTP: $e');
      return false;
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(
      String phoneNumber, String enteredOTP) async {
    try {
      // Get OTP data from Firestore
      final otpDoc = await _firestore
          .collection('otp_verifications')
          .doc(phoneNumber)
          .get();

      if (!otpDoc.exists) {
        return {
          'success': false,
          'error': 'OTP not found. Please request a new OTP.',
          'code': 'OTP_NOT_FOUND'
        };
      }

      final otpData = otpDoc.data()!;
      final storedOTP = otpData['otp'] as String;
      final expiryTime = (otpData['expiryTime'] as Timestamp).toDate();
      final attempts = otpData['attempts'] as int;
      final isVerified = otpData['isVerified'] as bool;

      // Check if already verified
      if (isVerified) {
        return {
          'success': false,
          'error': 'Phone number already verified.',
          'code': 'ALREADY_VERIFIED'
        };
      }

      // Check attempts limit
      if (attempts >= _maxAttempts) {
        return {
          'success': false,
          'error':
              'Maximum verification attempts exceeded. Please request a new OTP.',
          'code': 'MAX_ATTEMPTS_EXCEEDED'
        };
      }

      // Check expiry
      if (DateTime.now().isAfter(expiryTime)) {
        return {
          'success': false,
          'error': 'OTP has expired. Please request a new OTP.',
          'code': 'OTP_EXPIRED'
        };
      }

      // Verify OTP
      if (enteredOTP == storedOTP) {
        // Mark as verified
        await _firestore
            .collection('otp_verifications')
            .doc(phoneNumber)
            .update({
          'isVerified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        });

        // Store verification status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('phone_verified', true);
        await prefs.setString('verified_phone_number', phoneNumber);

        return {
          'success': true,
          'message': 'Phone number verified successfully!',
          'phoneNumber': phoneNumber
        };
      } else {
        // Increment attempts
        await _firestore
            .collection('otp_verifications')
            .doc(phoneNumber)
            .update({
          'attempts': FieldValue.increment(1),
        });

        final remainingAttempts = _maxAttempts - (attempts + 1);
        return {
          'success': false,
          'error': 'Invalid OTP. $remainingAttempts attempts remaining.',
          'code': 'INVALID_OTP',
          'remainingAttempts': remainingAttempts
        };
      }
    } catch (e) {
      // print('Error verifying OTP: $e');
      return {
        'success': false,
        'error': 'Verification failed. Please try again.',
        'code': 'VERIFICATION_ERROR'
      };
    }
  }

  // Check if phone number is verified
  Future<bool> isPhoneVerified(String phoneNumber) async {
    try {
      final otpDoc = await _firestore
          .collection('otp_verifications')
          .doc(phoneNumber)
          .get();

      if (!otpDoc.exists) return false;

      final otpData = otpDoc.data()!;
      return otpData['isVerified'] == true;
    } catch (e) {
      // print('Error checking phone verification: $e');
      return false;
    }
  }

  // Check resend cooldown
  Future<bool> canResendOTP(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final otpSentTimeStr = prefs.getString('otp_sent_time');

      if (otpSentTimeStr == null) return true;

      final otpSentTime = DateTime.parse(otpSentTimeStr);
      final now = DateTime.now();
      final difference = now.difference(otpSentTime).inSeconds;

      return difference >= _resendCooldownSeconds;
    } catch (e) {
      // print('Error checking resend cooldown: $e');
      return true;
    }
  }

  // Get remaining cooldown time
  Future<int> getRemainingCooldown(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final otpSentTimeStr = prefs.getString('otp_sent_time');

      if (otpSentTimeStr == null) return 0;

      final otpSentTime = DateTime.parse(otpSentTimeStr);
      final now = DateTime.now();
      final difference = now.difference(otpSentTime).inSeconds;

      return difference < _resendCooldownSeconds
          ? _resendCooldownSeconds - difference
          : 0;
    } catch (e) {
      // print('Error getting remaining cooldown: $e');
      return 0;
    }
  }

  // Create user account with phone number
  Future<Map<String, dynamic>> createUserWithPhone(
    String phoneNumber, {
    String? name,
    String? email,
  }) async {
    try {
      // Check if phone is verified
      final isVerified = await isPhoneVerified(phoneNumber);
      if (!isVerified) {
        return {
          'success': false,
          'error':
              'Phone number not verified. Please verify your phone number first.',
          'code': 'PHONE_NOT_VERIFIED'
        };
      }

      // Check if user already exists
      final existingUserQuery = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'User with this phone number already exists.',
          'code': 'USER_EXISTS'
        };
      }

      // Create user document
      final userDoc = await _firestore.collection('users').add({
        'phoneNumber': phoneNumber,
        'name': name ?? '',
        'email': email ?? '',
        'isPhoneVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'profileCompleted': false,
      });

      // Store user data locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userDoc.id);
      await prefs.setString('user_phone', phoneNumber);
      await prefs.setBool('is_logged_in', true);

      return {
        'success': true,
        'message': 'Account created successfully!',
        'userId': userDoc.id,
        'phoneNumber': phoneNumber
      };
    } catch (e) {
      // print('Error creating user with phone: $e');
      return {
        'success': false,
        'error': 'Failed to create account. Please try again.',
        'code': 'CREATE_USER_ERROR'
      };
    }
  }

  // Login with phone number
  Future<Map<String, dynamic>> loginWithPhone(String phoneNumber) async {
    try {
      // Check if phone is verified
      final isVerified = await isPhoneVerified(phoneNumber);
      if (!isVerified) {
        return {
          'success': false,
          'error':
              'Phone number not verified. Please verify your phone number first.',
          'code': 'PHONE_NOT_VERIFIED'
        };
      }

      // Find user by phone number
      final userQuery = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'No account found with this phone number.',
          'code': 'USER_NOT_FOUND'
        };
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();

      // Update last login
      await _firestore.collection('users').doc(userDoc.id).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      // Store user data locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userDoc.id);
      await prefs.setString('user_phone', phoneNumber);
      await prefs.setBool('is_logged_in', true);

      return {
        'success': true,
        'message': 'Login successful!',
        'userId': userDoc.id,
        'userData': userData,
        'phoneNumber': phoneNumber
      };
    } catch (e) {
      // print('Error logging in with phone: $e');
      return {
        'success': false,
        'error': 'Login failed. Please try again.',
        'code': 'LOGIN_ERROR'
      };
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_phone');
      await prefs.remove('is_logged_in');
      await prefs.remove('phone_verified');
      await prefs.remove('verified_phone_number');
      await prefs.remove('pending_phone_number');
      await prefs.remove('otp_sent_time');
    } catch (e) {
      // print('Error during logout: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_logged_in') ?? false;
    } catch (e) {
      // print('Error checking login status: $e');
      return false;
    }
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) return null;

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return null;

      return userDoc.data();
    } catch (e) {
      // print('Error getting current user: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) return false;

      await _firestore.collection('users').doc(userId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      // print('Error updating user profile: $e');
      return false;
    }
  }

  // Delete OTP verification record
  Future<void> deleteOTPVerification(String phoneNumber) async {
    try {
      await _firestore
          .collection('otp_verifications')
          .doc(phoneNumber)
          .delete();
    } catch (e) {
      // print('Error deleting OTP verification: $e');
    }
  }

  // Get OTP statistics (for admin)
  Future<Map<String, dynamic>> getOTPStatistics() async {
    try {
      final otpQuery = await _firestore.collection('otp_verifications').get();

      final totalOTPs = otpQuery.docs.length;
      final verifiedOTPs = otpQuery.docs.where((doc) {
        final data = doc.data();
        return data['isVerified'] == true;
      }).length;

      final failedOTPs = otpQuery.docs.where((doc) {
        final data = doc.data();
        return data['attempts'] >= _maxAttempts;
      }).length;

      return {
        'totalOTPs': totalOTPs,
        'verifiedOTPs': verifiedOTPs,
        'failedOTPs': failedOTPs,
        'successRate': totalOTPs > 0 ? (verifiedOTPs / totalOTPs) * 100 : 0.0,
      };
    } catch (e) {
      // print('Error getting OTP statistics: $e');
      return {};
    }
  }
}
