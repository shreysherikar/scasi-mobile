import 'package:flutter/material.dart';
import '../models/email.dart';
import '../services/gmail_service.dart';
import '../services/classify_rules.dart';
import '../services/email_actions_service.dart';
import '../services/backend_api_service.dart';
import 'email_detail_screen.dart';
import 'login_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _gmail = GmailService();
  final _actions = EmailActionsService();

  List<ScasiEmail> _emails = [];
  bool _loading = true;
  bool _triaging = false;
  String? _error;
  Map<String, dynamic>? _brief;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final emails = await _gmail.fetchInbox(maxResults: 20);
      setState(() {
        _emails = emails;
        _loading = false;
      });
    } on GmailAuthException {
      _goToLogin();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _runTriage() async {
    if (_emails.isEmpty) return;
    setState(() => _triaging = true);
    try {
      final brief = await _actions.triage(_emails);
      setState(() {
        _brief = brief;
        _triaging = false;
      });
    } on BackendApiException catch (e) {
      setState(() => _triaging = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Triage failed: ${e.message}')));
    } catch (e) {
      setState(() => _triaging = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Triage failed: $e')));
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: _triaging ? null : _runTriage,
                icon: _triaging
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.bolt),
                label: Text(_triaging ? 'Analyzing inbox…' : 'Run AI Triage Briefing'),
              ),
            ),
          ),
          if (_brief != null) SliverToBoxAdapter(child: _TriageCard(brief: _brief!)),
          if (_emails.isEmpty)
            const SliverFillRemaining(child: Center(child: Text('No inbox messages found.')))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final email = _emails[i];
                  final cls = classifyEmail(
                    subject: email.subject ?? '',
                    snippet: email.snippet ?? '',
                    from: email.from,
                  );
                  return ListTile(
                    leading: CircleAvatar(child: Text(_initial(email.from))),
                    title: Text(email.subject ?? '(no subject)', maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(email.snippet ?? email.from ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: _CategoryChip(category: cls.category),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EmailDetailScreen(email: email))),
                  );
                },
                childCount: _emails.length,
              ),
            ),
        ],
      ),
    );
  }
}

String _initial(String? from) {
  final trimmed = (from ?? '').trim();
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  Color _color() {
    switch (category) {
      case 'urgent':
        return Colors.red;
      case 'action_required':
        return Colors.orange;
      case 'financial':
        return Colors.purple;
      case 'meeting':
        return Colors.blue;
      case 'personal':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _color().withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(category, style: TextStyle(color: _color(), fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _TriageCard extends StatelessWidget {
  final Map<String, dynamic> brief;
  const _TriageCard({required this.brief});

  @override
  Widget build(BuildContext context) {
    final stats = brief['stats'] as Map<String, dynamic>? ?? {};
    final items = (brief['items'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Urgent: ${stats['urgent'] ?? 0} · Needs reply: ${stats['needsReply'] ?? 0} · FYI: ${stats['fyi'] ?? 0}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...items.take(6).map((raw) {
              final item = raw as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item['urgency'] == 'urgent' ? Icons.priority_high : Icons.circle,
                      size: 14,
                      color: item['urgency'] == 'urgent' ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${item['sender']}: ${item['action']}', style: const TextStyle(fontSize: 13))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
