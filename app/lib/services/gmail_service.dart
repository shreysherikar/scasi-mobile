import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/email.dart';
import 'auth_service.dart';

class GmailAuthException implements Exception {
  final String message;
  GmailAuthException([this.message = 'Not signed in to Google']);
}

/// Talks to the Gmail REST API directly — no backend involved. This is
/// Google's supported pattern for native/mobile apps (as opposed to the
/// server-side code-exchange flow web apps need for a refresh token).
class GmailService {
  static const _base = 'https://gmail.googleapis.com/gmail/v1/users/me';

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.instance.getAccessToken();
    if (token == null) throw GmailAuthException();
    return {'Authorization': 'Bearer $token'};
  }

  /// Fetches the most recent [maxResults] inbox messages with full content.
  Future<List<ScasiEmail>> fetchInbox({int maxResults = 20}) async {
    final headers = await _headers();

    final listRes = await http.get(
      Uri.parse('$_base/messages?maxResults=$maxResults&labelIds=INBOX'),
      headers: headers,
    );
    _checkOk(listRes);

    final listJson = jsonDecode(listRes.body) as Map<String, dynamic>;
    final refs = (listJson['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final emails = <ScasiEmail>[];
    // Sequential to stay well under Gmail's per-second quota on a personal key.
    for (final ref in refs) {
      final id = ref['id'] as String;
      final msgRes = await http.get(
        Uri.parse('$_base/messages/$id?format=full'),
        headers: headers,
      );
      if (msgRes.statusCode != 200) continue; // skip a single bad message rather than failing the whole inbox
      emails.add(ScasiEmail.fromGmailJson(jsonDecode(msgRes.body) as Map<String, dynamic>));
    }
    return emails;
  }

  void _checkOk(http.Response res) {
    if (res.statusCode == 401) throw GmailAuthException('Google session expired — please sign in again');
    if (res.statusCode >= 400) throw Exception('Gmail API error (${res.statusCode}): ${res.body}');
  }
}
