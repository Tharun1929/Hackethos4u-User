import 'package:flutter/material.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ErrorType {
  network,
  authentication,
  firestore,
  storage,
  payment,
  validation,
  unknown,
}

class ErrorHandlingService {
  static final ErrorHandlingService _instance =
      ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  // final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // ===== ERROR TYPES =====

  // ===== ERROR HANDLING =====

  /// Handle and log error
  Future<void> handleError({
    required dynamic error,
    required StackTrace stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Log to Crashlytics
      // await _crashlytics.recordError(error, stackTrace, context: context);

      // Add additional data if provided
      if (additionalData != null) {
        for (final entry in additionalData.entries) {
          // await _crashlytics.setCustomKey(entry.key, entry.value);
        }
      }

      // Log to console for debugging
      print('Error in $context: $error');
      print('Stack trace: $stackTrace');
    } catch (e) {
      print('Error in error handling: $e');
    }
  }

  /// Handle Firebase Auth errors
  String handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'invalid-email':
          return 'Invalid email address format.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email but different sign-in method.';
        case 'invalid-credential':
          return 'Invalid credentials. Please check your email and password.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'requires-recent-login':
          return 'Please sign in again to perform this action.';
        case 'invalid-verification-code':
          return 'Invalid verification code. Please try again.';
        case 'invalid-verification-id':
          return 'Invalid verification ID. Please request a new code.';
        case 'credential-already-in-use':
          return 'This credential is already associated with a different account.';
        case 'admin-restricted-operation':
          return 'This operation is restricted to administrators.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Handle Firestore errors
  String handleFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        case 'not-found':
          return 'The requested data was not found.';
        case 'already-exists':
          return 'This data already exists.';
        case 'resource-exhausted':
          return 'Too many requests. Please try again later.';
        case 'failed-precondition':
          return 'The operation failed due to a precondition.';
        case 'aborted':
          return 'The operation was aborted. Please try again.';
        case 'out-of-range':
          return 'The operation is out of range.';
        case 'unimplemented':
          return 'This feature is not implemented yet.';
        case 'internal':
          return 'An internal error occurred. Please try again.';
        case 'unavailable':
          return 'Service is temporarily unavailable. Please try again later.';
        case 'data-loss':
          return 'Data loss occurred. Please contact support.';
        case 'unauthenticated':
          return 'You must be signed in to perform this action.';
        case 'deadline-exceeded':
          return 'Request timeout. Please try again.';
        default:
          return 'Database error: ${error.message}';
      }
    }
    return 'An unexpected database error occurred.';
  }

  /// Handle Firebase Storage errors
  String handleStorageError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to access this file.';
        case 'not-found':
          return 'The requested file was not found.';
        case 'already-exists':
          return 'A file with this name already exists.';
        case 'resource-exhausted':
          return 'Storage quota exceeded. Please contact support.';
        case 'failed-precondition':
          return 'The file operation failed due to a precondition.';
        case 'aborted':
          return 'The file operation was aborted. Please try again.';
        case 'out-of-range':
          return 'The file operation is out of range.';
        case 'unimplemented':
          return 'This file operation is not implemented yet.';
        case 'internal':
          return 'An internal storage error occurred.';
        case 'unavailable':
          return 'Storage service is temporarily unavailable.';
        case 'data-loss':
          return 'File data loss occurred. Please contact support.';
        case 'unauthenticated':
          return 'You must be signed in to access files.';
        case 'deadline-exceeded':
          return 'File upload/download timeout. Please try again.';
        case 'cancelled':
          return 'File operation was cancelled.';
        case 'unknown':
          return 'Unknown storage error occurred.';
        case 'invalid-argument':
          return 'Invalid file argument provided.';
        case 'invalid-checksum':
          return 'File checksum validation failed.';
        case 'invalid-format':
          return 'Invalid file format.';
        case 'invalid-state':
          return 'Invalid file state for this operation.';
        case 'quota-exceeded':
          return 'Storage quota exceeded.';
        case 'retry-limit-exceeded':
          return 'Maximum retry attempts exceeded.';
        case 'unauthorized':
          return 'Unauthorized access to file.';
        default:
          return 'Storage error: ${error.message}';
      }
    }
    return 'An unexpected storage error occurred.';
  }

  /// Handle payment errors
  String handlePaymentError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (errorString.contains('cancelled')) {
      return 'Payment was cancelled. You can try again anytime.';
    } else if (errorString.contains('failed')) {
      return 'Payment failed. Please check your payment details and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Payment request timed out. Please try again.';
    } else if (errorString.contains('invalid')) {
      return 'Invalid payment details. Please check your information.';
    } else if (errorString.contains('insufficient')) {
      return 'Insufficient funds. Please check your account balance.';
    } else if (errorString.contains('declined')) {
      return 'Payment was declined by your bank. Please contact your bank or try a different payment method.';
    } else if (errorString.contains('expired')) {
      return 'Payment method has expired. Please update your payment details.';
    } else {
      return 'Payment error occurred. Please try again or contact support if the problem persists.';
    }
  }

  /// Handle validation errors
  String handleValidationError(dynamic error) {
    if (error is FormatException) {
      return 'Invalid format. Please check your input.';
    } else if (error is ArgumentError) {
      return 'Invalid argument provided.';
    } else if (error is StateError) {
      return 'Invalid state for this operation.';
    } else {
      return 'Validation error: ${error.toString()}';
    }
  }

  /// Get user-friendly error message
  String getUserFriendlyError(dynamic error, {ErrorType? errorType}) {
    try {
      if (errorType != null) {
        switch (errorType) {
          case ErrorType.authentication:
            return handleAuthError(error);
          case ErrorType.firestore:
            return handleFirestoreError(error);
          case ErrorType.storage:
            return handleStorageError(error);
          case ErrorType.payment:
            return handlePaymentError(error);
          case ErrorType.validation:
            return handleValidationError(error);
          case ErrorType.network:
            return 'Network error. Please check your internet connection and try again.';
          case ErrorType.unknown:
          default:
            return 'An unexpected error occurred. Please try again.';
        }
      }

      // Auto-detect error type
      if (error is FirebaseAuthException) {
        return handleAuthError(error);
      } else if (error is FirebaseException) {
        if (error.code.startsWith('storage/')) {
          return handleStorageError(error);
        } else {
          return handleFirestoreError(error);
        }
      } else if (error.toString().toLowerCase().contains('payment')) {
        return handlePaymentError(error);
      } else if (error is FormatException || error is ArgumentError) {
        return handleValidationError(error);
      } else if (error.toString().toLowerCase().contains('network') ||
          error.toString().toLowerCase().contains('socket')) {
        return 'Network error. Please check your internet connection and try again.';
      } else {
        return 'An unexpected error occurred. Please try again.';
      }
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // ===== ERROR REPORTING =====

  /// Report error to analytics
  Future<void> reportError({
    required String errorType,
    required String errorMessage,
    String? context,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // await _crashlytics.setCustomKey('error_type', errorType);
      // await _crashlytics.setCustomKey('error_message', errorMessage);

      if (context != null) {
        // await _crashlytics.setCustomKey('error_context', context);
      }

      if (parameters != null) {
        for (final entry in parameters.entries) {
          // await _crashlytics.setCustomKey(entry.key, entry.value);
        }
      }
    } catch (e) {
      print('Error reporting to analytics: $e');
    }
  }

  /// Log non-fatal error
  Future<void> logNonFatalError({
    required String message,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // await _crashlytics.log('Non-fatal error: $message');

      if (context != null) {
        // await _crashlytics.log('Context: $context');
      }

      if (additionalData != null) {
        for (final entry in additionalData.entries) {
          // await _crashlytics.log('${entry.key}: ${entry.value}');
        }
      }
    } catch (e) {
      print('Error logging non-fatal error: $e');
    }
  }

  // ===== ERROR RECOVERY =====

  /// Check if error is recoverable
  bool isRecoverableError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
        case 'deadline-exceeded':
        case 'resource-exhausted':
        case 'aborted':
          return true;
        default:
          return false;
      }
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection');
  }

  /// Get retry delay for error
  Duration getRetryDelay(dynamic error, int attemptCount) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'resource-exhausted':
          return Duration(seconds: 60 * attemptCount); // Exponential backoff
        case 'unavailable':
        case 'deadline-exceeded':
          return Duration(seconds: 5 * attemptCount);
        default:
          return Duration(seconds: 2 * attemptCount);
      }
    }

    return Duration(seconds: 2 * attemptCount);
  }

  // ===== ERROR UI HELPERS =====

  /// Show error snackbar
  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show error dialog
  void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show retry dialog
  Future<bool> showRetryDialog(BuildContext context, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ===== ERROR MONITORING =====

  /// Set user identifier for crash reports
  Future<void> setUserIdentifier(String userId) async {
    try {
      // await _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      print('Error setting user identifier: $e');
    }
  }

  /// Set custom keys for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      // await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      print('Error setting custom key: $e');
    }
  }

  /// Log breadcrumb for debugging
  Future<void> logBreadcrumb(String message) async {
    try {
      // await _crashlytics.log(message);
    } catch (e) {
      print('Error logging breadcrumb: $e');
    }
  }

  // ===== INITIALIZATION =====

  /// Initialize error handling service
  Future<void> initialize() async {
    try {
      // Enable crash collection
      // await _crashlytics.setCrashlyticsCollectionEnabled(true);

      // Set up error handling
      FlutterError.onError = (FlutterErrorDetails details) {
        // _crashlytics.recordFlutterFatalError(details);
      };

      // Set up platform error handling
      // PlatformDispatcher.instance.onError = (error, stack) {
      //   _crashlytics.recordError(error, stack, fatal: true);
      //   return true;
      // };
    } catch (e) {
      print('Error initializing error handling service: $e');
    }
  }
}
