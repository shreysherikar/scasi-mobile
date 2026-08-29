import 'package:flutter/material.dart';
import '../services/backend_api_service.dart';

enum _Role { user, assistant }

class _Turn {
  final _Role role;
  String text;
  bool streaming;
  String? error;
  _Turn({required this.role, this.text = '', this.streaming = false, this.error});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _backend = BackendApiService();
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Turn> _turns = [];
  bool _sending = false;
  String? _sessionId;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    _controller.clear();
    setState(() {
      _turns.add(_Turn(role: _Role.user, text: text));
      _turns.add(_Turn(role: _Role.assistant, streaming: true));
      _sending = true;
    });
    _scrollToBottom();
    final assistantTurn = _turns.last;

    try {
      // The backend keeps conversation history itself (Supabase-backed,
      // keyed by sessionId) so we only need to send the latest message.
      await for (final delta in _backend.streamChat(
        text,
        sessionId: _sessionId,
        onSessionId: (sid) => _sessionId = sid,
      )) {
        setState(() => assistantTurn.text += delta);
        _scrollToBottom();
      }
      setState(() => assistantTurn.streaming = false);
    } on BackendApiException catch (e) {
      setState(() {
        assistantTurn.streaming = false;
        assistantTurn.error = e.message;
      });
    } catch (e) {
      setState(() {
        assistantTurn.streaming = false;
        assistantTurn.error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _turns.isEmpty
              ? const Center(child: Text('Ask Scasi to draft something, summarize your day, or just chat.'))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: _turns.length,
                  itemBuilder: (context, i) => _Bubble(turn: _turns[i]),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Message Scasi…',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _sending ? null : _send, icon: const Icon(Icons.arrow_upward)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Turn turn;
  const _Bubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    final isUser = turn.role == _Role.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (turn.text.isNotEmpty) Text(turn.text),
            if (turn.error != null) Text(turn.error!, style: const TextStyle(color: Colors.red)),
            if (turn.streaming && turn.text.isEmpty && turn.error == null)
              const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    );
  }
}
