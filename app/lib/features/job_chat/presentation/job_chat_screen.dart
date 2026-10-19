import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../composition/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../data/offline_chat_service.dart';
import '../domain/chat_message.dart';
import '../domain/chat_service.dart';

const kEmptyThreadCopy = 'No messages yet.';
const kWaitingToSend = 'Waiting to send.';
const kChatClosedCopy = 'This chat is closed.';

class JobChatScreen extends ConsumerStatefulWidget {
  const JobChatScreen({
    super.key,
    required this.bookingId,
    this.threadClosed = false,
    this.selfUserId = 'demo-user',
    this.showCall = false,
    this.onCall,
  });

  final String bookingId;
  final bool threadClosed;
  final String selfUserId;
  final bool showCall;
  final VoidCallback? onCall;

  @override
  ConsumerState<JobChatScreen> createState() => _JobChatScreenState();
}

class _JobChatScreenState extends ConsumerState<JobChatScreen> {
  final _composer = TextEditingController();
  Timer? _poll;
  List<ChatMessage> _messages = [];
  String? _error;

  ChatService get _chat => ref.read(chatServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _composer.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final chat = _chat;
    if (chat is OfflineChatService) {
      await chat.flush();
    }
    final result = await chat.list(widget.bookingId);
    if (!mounted) return;
    result.when(
      onOk: (items) => setState(() {
        _messages = items;
        _error = null;
      }),
      onErr: (failure) => setState(() => _error = failure.message),
    );
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || widget.threadClosed) return;
    _composer.clear();
    await _chat.send(bookingId: widget.bookingId, text: text);
    await _refresh();
  }

  Future<void> _retry(ChatMessage message) async {
    final chat = _chat;
    if (chat is OfflineChatService) {
      await chat.retry(message);
    } else {
      await chat.send(
        bookingId: message.bookingId,
        text: message.text ?? '',
        mediaPath: message.mediaPath,
        idempotencyKey: message.id,
      );
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          if (widget.showCall)
            TextButton(
              onPressed: widget.onCall,
              child: const Text('Call'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: AppColors.error)),
            ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      kEmptyThreadCopy,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _bubble(_messages[i]),
                  ),
          ),
          if (widget.threadClosed)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                kChatClosedCopy,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            _composerBar(),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage message) {
    final mine = message.senderId == widget.selfUserId ||
        message.senderId == 'local' ||
        message.senderId == 'demo-user';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: mine ? AppColors.primaryRed : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            if (message.state == ChatMessageState.sending)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  kWaitingToSend,
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            if (message.state == ChatMessageState.failed)
              TextButton(
                onPressed: () => _retry(message),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _composerBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _composer,
                maxLength: 1000,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Message',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _send,
              icon: const Icon(Icons.send_rounded, color: AppColors.primaryRed),
            ),
          ],
        ),
      ),
    );
  }
}
