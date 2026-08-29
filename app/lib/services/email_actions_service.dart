import 'package:intl/intl.dart';
import '../models/email.dart';
import 'groq_service.dart';
import 'prompts.dart';

class EmailActionsService {
  final _groq = GroqService();

  /// Uses the ported rule engine — no network call. See classify_rules.dart.
  /// (Exposed here too for a single import point in screens.)

  Future<Map<String, dynamic>> summarize(ScasiEmail email) {
    final userPrompt = [
      'Subject: ${email.subject ?? ''}',
      if (email.from != null) 'From: ${email.from}',
      if (email.date != null) 'Received: ${email.date}',
      '',
      'Body:\n${(email.body ?? email.snippet ?? '').substring(0, _cap(email.body ?? email.snippet ?? '', 3000))}',
    ].join('\n');

    return _groq.generateJson(systemPrompt: kSummarizeSystemPrompt, userPrompt: userPrompt, temperature: 0.4, maxTokens: 512);
  }

  Future<String> draftReply(ScasiEmail email, {String tone = 'professional'}) async {
    String senderFirstName = '';
    final from = email.from;
    if (from != null) {
      final match = RegExp(r'^([^<@]+?)(?:\s*<|$)').firstMatch(from);
      if (match != null) senderFirstName = match.group(1)!.trim().split(RegExp(r'\s+')).first;
    }

    final snippet = (email.body ?? email.snippet ?? '');
    final userPrompt = [
      'Tone: $tone',
      'Subject: ${email.subject ?? ''}',
      if (senderFirstName.isNotEmpty) "Sender's first name: $senderFirstName",
      '',
      'Email Content:\n${snippet.substring(0, _cap(snippet, 3000))}',
      '',
      senderFirstName.isNotEmpty
          ? 'Draft a reply. Open with "Dear $senderFirstName," — never use placeholder text like [name] or [sender].'
          : 'Draft a reply:',
    ].join('\n');

    final result = await _groq.generateJson(systemPrompt: kReplySystemPrompt, userPrompt: userPrompt, temperature: 0.7, maxTokens: 1024);
    return result['reply'] as String? ?? '';
  }

  Future<Map<String, dynamic>> triage(List<ScasiEmail> emails) {
    final timeStr = DateFormat("EEEE, MMMM d, y 'at' h:mm a").format(DateTime.now());
    final blob = emails
        .take(30)
        .map((e) => 'From: ${e.from ?? "Unknown"}\nSubject: ${e.subject ?? ""}\nSnippet: ${e.snippet ?? ""}')
        .join('\n---\n');

    return _groq.generateJson(
      systemPrompt: triageSystemPrompt(timeStr),
      userPrompt: 'Analyze these emails:\n\n$blob',
      temperature: 0.2,
      maxTokens: 2000,
    );
  }

  int _cap(String s, int max) => s.length > max ? max : s.length;
}
