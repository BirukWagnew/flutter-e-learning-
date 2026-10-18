import '../models/user_model.dart';
import '../services/storage_service.dart';

class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final String? errorMessage;

  AuthResult.success(this.user)
      : isSuccess = true,
        errorMessage = null;

  AuthResult.failure(this.errorMessage)
      : isSuccess = false,
        user = null;
}

class AuthRepository {
  final StorageService _storageService;

  AuthRepository(this._storageService) {
    _ensureDefaultDemoUser();
  }

  void _ensureDefaultDemoUser() {
    final registered = _storageService.getRegisteredUsers();
    const demoEmail = 'student@abyssinia.com';
    if (!registered.containsKey(demoEmail)) {
      final demoUser = UserModel(
        id: 'usr_demo_101',
        name: 'Biruk Student',
        email: demoEmail,
        role: 'Pro Learner',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
        joinedDate: DateTime(2026, 1, 15),
      );
      _storageService.saveRegisteredUser(
        user: demoUser,
        password: 'password123',
      );
    }
  }

  UserModel? getCurrentUser() {
    return _storageService.getCurrentUser();
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // Artificial small delay for realistic UX and loading states
    await Future.delayed(const Duration(milliseconds: 400));

    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      return AuthResult.failure('Please enter your email address');
    }
    if (password.isEmpty) {
      return AuthResult.failure('Please enter your password');
    }

    final users = _storageService.getRegisteredUsers();
    if (!users.containsKey(cleanEmail)) {
      return AuthResult.failure('No account found with this email. Please sign up.');
    }

    final userData = users[cleanEmail]!;
    final storedPassword = userData['password'] as String?;

    if (storedPassword != password) {
      return AuthResult.failure('Invalid password. Please check and try again.');
    }

    final user = UserModel.fromJson(Map<String, dynamic>.from(userData['user'] as Map));
    await _storageService.saveCurrentUser(user);
    return AuthResult.success(user);
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.length < 2) {
      return AuthResult.failure('Name must be at least 2 characters long');
    }
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return AuthResult.failure('Please enter a valid email address');
    }
    if (password.length < 6) {
      return AuthResult.failure('Password must be at least 6 characters');
    }

    final users = _storageService.getRegisteredUsers();
    if (users.containsKey(cleanEmail)) {
      return AuthResult.failure('An account with this email already exists. Please login.');
    }

    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      email: cleanEmail,
      role: 'Student',
      joinedDate: DateTime.now(),
    );

    await _storageService.saveRegisteredUser(user: newUser, password: password);
    await _storageService.saveCurrentUser(newUser);

    return AuthResult.success(newUser);
  }

  Future<void> logout() async {
    await _storageService.clearCurrentUser();
  }
}
