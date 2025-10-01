import '../model/profile/user_model.dart';

class UserService {
  // Simulated in-memory user database
  static final List<UserModel> _mockDatabase = [];

  /// Simulated login function
  static Future<UserModel?> loginUser(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (email.isEmpty || password.isEmpty) return null;

    try {
      return _mockDatabase.firstWhere(
        (user) => user.email == email && user.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  /// Simulated registration
  static Future<bool> registerUser(UserModel user) async {
    await Future.delayed(const Duration(seconds: 1));

    if (user.email?.isEmpty != false ||
        user.password?.isEmpty != false ||
        user.firstname?.isEmpty != false ||
        user.lastname?.isEmpty != false ||
        (user.id ?? 0) <= 0) {
      return false;
    }

    final emailExists = _mockDatabase.any(
      (existingUser) => existingUser.email == user.email,
    );

    if (emailExists) return false;

    _mockDatabase.add(user);
    return true;
  }

  static List<UserModel> getAllUsers() {
    return _mockDatabase;
  }
}
