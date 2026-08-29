import 'package:flutter/material.dart';
import '../models/email.dart';
import '../services/email_actions_service.dart';
import '../services/groq_service.dart';
import 'settings_screen.dart';

class EmailDetailScreen extends StatefulWidget {
  final ScasiEmail email;
  const EmailDetailScreen({super.key, required this.email});

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen> {
  final _actions = EmailActionsService();
  bool _summarizing = false;
  bool _drafting = false;
  Map<String, dynamic>? _summary;
  String? _draftReply;

  Future<void> _summarize() async {
    setState(() => _summarizing = true);
    try {
      final result = await _actions.summarize(widget.email);
      setState(() {
        _summary = result;
        _summarizing = false;
      });
    } on NoApiKeyException {
      setState(() => _summarizing = false);
      _promptForKey();
    } catch (e) {
      setState(() => _summarizing = false);
      _showError(e);
    }
  }

  Future<void> _draftReplyAction() async {
    setState(() => _drafting = true);
    try {
      final result = await _actions.draftReply(widget.email);
      setState(() {
        _draftReply = result;
        _drafting = false;
      });
    } on NoApiKeyException {
      setState(() => _drafting = false);
      _promptForKey();
    } catch (e) {
      setState(() => _drafting = false);
      _showError(e);
    }
  }

  void _promptForKey() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Add a Groq API key in Settings to use AI features.'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ),
    );
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email;
    return Scaffold(
      appBar: AppBar(title: const Text('Email')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(email.subject ?? '(no subject)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(email.from ?? '', style: const TextStyle(color: Colors.grey)),
          if (email.date != null) Text(email.date!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(height: 32),
          Text(email.body ?? email.snippet ?? ''),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _summarizing ? null : _summarize,
                icon: _summarizing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.summarize_outlined),
                label: const Text('Summarize'),
              ),
              OutlinedButton.icon(
                onPressed: _drafting ? null : _draftReplyAction,
                icon: _drafting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.reply_outlined),
                label: const Text('Draft reply'),
              ),
            ],
          ),
          if (_summary != null) ...[
            const SizedBox(height: 20),
            _SummaryCard(summary: _summary!),
          ],
          if (_draftReply != null) ...[
            const SizedBox(height: 12),
            _ResultCard(title: 'Draft reply', content: _draftReply!),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SelectableText(summary['summary']?.toString() ?? ''),
            const SizedBox(height: 10),
            _row('Key ask', summary['keyAsk']),
            _row('Deadline', summary['deadline']),
            _row('Tone', summary['tone']),
            _row('Next step', summary['nextStep']),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: '$value'),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String content;
  const _ResultCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SelectableText(content),
          ],
        ),
      ),
    );
  }
}
