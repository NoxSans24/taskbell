class AuthSession {
  final String token;
  final String userId;
  final String email;

  const AuthSession({
    required this.token,
    required this.userId,
    required this.email,
  });
}
