import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The app calls Groq directly from the device, so it needs the user's own
/// API key (free at console.groq.com) rather than one baked into the app —
/// shipping a real key inside a distributed app binary would leak it.
class ApiKeyStore {
  ApiKeyStore._();
  static final ApiKeyStore instance = ApiKeyStore._();

  static const _key = 'groq_api_key';
  final _storage = const FlutterSecureStorage();

  Future<String?> get() => _storage.read(key: _key);

  Future<void> set(String value) => _storage.write(key: _key, value: value.trim());

  Future<void> clear() => _storage.delete(key: _key);
}
