import '../models/email.dart';
import 'backend_api_service.dart';

class EmailActionsService {
  final _backend = BackendApiService();

  /// Uses the ported rule engine — no network call. See classify_rules.dart.
  /// (Exposed here too for a single import point in screens.)

  Future<Map<String, dynamic>> summarize(ScasiEmail email) {
    return _backend.summarize(
      subject: email.subject ?? '',
      sender: email.from,
      date: email.date,
      body: (email.body ?? email.snippet ?? '').substring(
        0,
        _cap(email.body ?? email.snippet ?? '', 3000),
      ),
    );
  }

  Future<String> draftReply(ScasiEmail email, {String tone = 'professional'}) async {
    String senderFirstName = '';
    final from = email.from;
    if (from != null) {
      final match = RegExp(r'^([^<@]+?)(?:\s*<|$)').firstMatch(from);
      if (match != null) senderFirstName = match.group(1)!.trim().split(RegExp(r'\s+')).first;
    }

    final snippet = (email.body ?? email.snippet ?? '');
    return _backend.draftReply(
      subject: email.subject ?? '',
      body: snippet.substring(0, _cap(snippet, 3000)),
      tone: tone,
      senderFirstName: senderFirstName.isNotEmpty ? senderFirstName : null,
    );
  }

  Future<Map<String, dynamic>> triage(List<ScasiEmail> emails) {
    return _backend.triage(
      emails
          .take(30)
          .map((e) => {
                'sender': e.from,
                'subject': e.subject,
                'snippet': e.snippet,
              })
          .toList(),
    );
  }

  int _cap(String s, int max) => s.length > max ? max : s.length;
}
