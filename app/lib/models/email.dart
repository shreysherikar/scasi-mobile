import 'dart:convert' show base64Decode;

class ScasiEmail {
  final String id;
  final String? subject;
  final String? from;
  final String? date;
  final String? snippet;
  final String? body;

  ScasiEmail({
    required this.id,
    this.subject,
    this.from,
    this.date,
    this.snippet,
    this.body,
  });

  /// Parses a Gmail API `messages.get` response (format=full or metadata).
  factory ScasiEmail.fromGmailJson(Map<String, dynamic> json) {
    final headers = ((json['payload']?['headers'] as List?) ?? [])
        .cast<Map<String, dynamic>>();

    String? header(String name) {
      final match = headers.firstWhere(
        (h) => (h['name'] as String?)?.toLowerCase() == name.toLowerCase(),
        orElse: () => {},
      );
      return match['value'] as String?;
    }

    return ScasiEmail(
      id: json['id'] as String,
      subject: header('Subject'),
      from: header('From'),
      date: header('Date'),
      snippet: json['snippet'] as String?,
      body: _extractPlainText(json['payload'] as Map<String, dynamic>?),
    );
  }

  /// Walks Gmail's (possibly nested/multipart) payload for a text/plain part.
  /// Falls back to null so the UI can show `snippet` instead.
  static String? _extractPlainText(Map<String, dynamic>? payload) {
    if (payload == null) return null;

    String? decode(String? data) {
      if (data == null) return null;
      try {
        final normalized = data.replaceAll('-', '+').replaceAll('_', '/');
        final padded = normalized.padRight((normalized.length + 3) ~/ 4 * 4, '=');
        return String.fromCharCodes(base64Decode(padded));
      } catch (_) {
        return null;
      }
    }

    if (payload['mimeType'] == 'text/plain') {
      final data = payload['body']?['data'] as String?;
      final decoded = decode(data);
      if (decoded != null) return decoded;
    }

    final parts = (payload['parts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final part in parts) {
      final result = _extractPlainText(part);
      if (result != null) return result;
    }
    return null;
  }
}
