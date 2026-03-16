// lib/services/auth.dart

enum UserRole { tenant, host, admin }

/// Simple mocked auth service. Replace with real auth integration later.
class AuthService {
  // For now, return a fixed role. You can change it during testing.
  static UserRole currentRole = UserRole.host;

  static bool isHostOrAdmin() => currentRole == UserRole.host || currentRole == UserRole.admin;
}
