import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'api_key_store.dart';

class NoApiKeyException implements Exception {
  final String message = 'No Groq API key set. Add one in Settings (free at console.groq.com).';
}

class GroqService {
  Future<String> _requireKey() async {
    final key = await ApiKeyStore.instance.get();
    if (key == null || key.isEmpty) throw NoApiKeyException();
    return key;
  }

  /// One-shot JSON-mode completion — used for summarize/reply/triage, whose
  /// prompts (ported verbatim from Scasi's backend) all ask for a JSON object back.
  Future<Map<String, dynamic>> generateJson({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.4,
    int maxTokens = 1024,
  }) async {
    final key = await _requireKey();

    final res = await http.post(
      Uri.parse(kGroqEndpoint),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $key'},
      body: jsonEncode({
        'model': kGroqModel,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
      }),
    );

    if (res.statusCode >= 400) {
      throw Exception('Groq API error (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final content = decoded['choices']?[0]?['message']?['content'] as String?;
    if (content == null) throw Exception('Groq returned no content');

    final cleaned = content.replaceAll(RegExp(r'^```(?:json)?\s*|\s*```$'), '').trim();
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  /// Streaming chat completion — powers the Assistant tab. OpenAI-compatible
  /// SSE: lines prefixed `data: {...}`, terminated by `data: [DONE]`.
  Stream<String> streamChat(List<Map<String, String>> messages) async* {
    final key = await _requireKey();

    final request = http.Request('POST', Uri.parse(kGroqEndpoint))
      ..headers.addAll({'Content-Type': 'application/json', 'Authorization': 'Bearer $key'})
      ..body = jsonEncode({
        'model': kGroqModel,
        'temperature': 0.6,
        'stream': true,
        'messages': messages,
      });

    final client = http.Client();
    try {
      final response = await client.send(request);
      if (response.statusCode >= 400) {
        final body = await response.stream.bytesToString();
        throw Exception('Groq API error (${response.statusCode}): $body');
      }

      var buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        while (buffer.contains('\n')) {
          final idx = buffer.indexOf('\n');
          final line = buffer.substring(0, idx).trim();
          buffer = buffer.substring(idx + 1);
          if (!line.startsWith('data:')) continue;

          final payload = line.substring(5).trim();
          if (payload == '[DONE]') return;
          if (payload.isEmpty) continue;

          try {
            final json = jsonDecode(payload) as Map<String, dynamic>;
            final delta = json['choices']?[0]?['delta']?['content'] as String?;
            if (delta != null && delta.isNotEmpty) yield delta;
          } catch (_) {
            // Ignore malformed keep-alive lines.
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
