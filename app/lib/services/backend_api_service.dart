import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'supabase_service.dart';

class BackendApiException implements Exception {
  final int? statusCode;
  final String message;
  BackendApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// Talks to our own FastAPI backend (see /backend) instead of calling Groq
/// directly from the device. Every call is authenticated with the Supabase
/// session token — the backend verifies it against Supabase's public keys,
/// so there's no separate backend login step.
class BackendApiService {
  Future<Map<String, String>> _headers() async {
    final token = SupabaseService.instance.backendToken;
    if (token == null) throw BackendApiException('Not signed in');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<Map<String, dynamic>> _postJson(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$kBackendBaseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode >= 400) {
      throw BackendApiException('Backend error (${res.statusCode}): ${res.body}', statusCode: res.statusCode);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> summarize({
    required String subject,
    String? sender,
    String? date,
    required String body,
  }) =>
      _postJson('/emails/summarize', {
        'subject': subject,
        'sender': sender,
        'date': date,
        'body': body,
      });

  Future<String> draftReply({
    required String subject,
    required String body,
    String tone = 'professional',
    String? senderFirstName,
  }) async {
    final result = await _postJson('/emails/reply', {
      'subject': subject,
      'body': body,
      'tone': tone,
      'senderFirstName': senderFirstName,
    });
    return result['reply'] as String? ?? '';
  }

  Future<Map<String, dynamic>> triage(List<Map<String, String?>> emails) =>
      _postJson('/emails/triage', {'emails': emails});

  /// Streams `/chat/stream` (Server-Sent Events) from our backend, yielding
  /// the `token` events' text deltas — mirrors the old GroqService streaming
  /// interface so chat_screen.dart barely has to change.
  Stream<String> streamChat(
    String message, {
    String? sessionId,
    void Function(String sessionId)? onSessionId,
  }) async* {
    final headers = await _headers();
    final request = http.Request('POST', Uri.parse('$kBackendBaseUrl/chat/stream'))
      ..headers.addAll(headers)
      ..body = jsonEncode({'message': message, 'sessionId': sessionId});

    final client = http.Client();
    try {
      final response = await client.send(request);
      if (response.statusCode >= 400) {
        final body = await response.stream.bytesToString();
        throw BackendApiException('Backend error (${response.statusCode}): $body', statusCode: response.statusCode);
      }

      String? currentEvent;
      var buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        while (buffer.contains('\n')) {
          final idx = buffer.indexOf('\n');
          final line = buffer.substring(0, idx).trim();
          buffer = buffer.substring(idx + 1);

          if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
            continue;
          }
          if (!line.startsWith('data:')) continue;
          final payload = line.substring(5).trim();
          if (payload.isEmpty) continue;

          final data = jsonDecode(payload) as Map<String, dynamic>;
          switch (currentEvent) {
            case 'token':
              yield data['text'] as String? ?? '';
              break;
            case 'done':
              if (data['sessionId'] != null) onSessionId?.call(data['sessionId'] as String);
              return;
            case 'error':
              throw BackendApiException(data['message'] as String? ?? 'Unknown chat error');
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
