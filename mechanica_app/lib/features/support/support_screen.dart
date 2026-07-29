import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../navigation/route_names.dart';
import '../../providers/app_providers.dart';
import '../../mock/mock_data.dart';
import '../../widgets/shared/app_widgets.dart';
import '../../widgets/shared/app_states.dart';

// ─── SUPPORT SCREEN ───────────────────────────────────────────────────────────

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Support'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick contact
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.bikeCardGradient, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3))),
              child: Row(
                children: [
                  Expanded(
                    child: _ContactButton(Icons.call_rounded, 'Call Us', '+91 9206 06199', () => showAppSnackbar(context, 'Calling support...')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ContactButton(Icons.chat_rounded, 'Live Chat', 'Start Chat', () => context.push(RouteNames.chat)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Create Ticket', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push(RouteNames.ticket),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2))),
                child: const Row(
                  children: [
                    Icon(Icons.confirmation_number_outlined, color: AppColors.primaryRed, size: 24),
                    SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Raise a Complaint', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('We will resolve it within 24 hours', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    )),
                    Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('FAQs', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...[
              ('How do I book a service?', 'Go to Home > Book Service and follow the 6 easy steps.'),
              ('What is the pickup & drop charge?', 'We charge ₹100 for pickup and drop service.'),
              ('How do I track my bike?', 'You can track your bike in real-time from the Tracking screen.'),
              ('Can I reschedule my booking?', 'Yes, you can reschedule up to 2 hours before the service.'),
              ('What is the cancellation policy?', 'Free cancellation up to 24 hours before service.'),
            ].map((faq) => _FaqItem(faq.$1, faq.$2)).toList(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ContactButton(this.icon, this.title, this.subtitle, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryRed, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _open ? AppColors.primaryRed.withValues(alpha: 0.3) : AppColors.divider),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(child: Text(widget.question, style: const TextStyle(color: Colors.white, fontSize: 13))),
                  Icon(_open ? Icons.remove_rounded : Icons.add_rounded, color: AppColors.primaryRed, size: 18),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(widget.answer, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
            ),
        ],
      ),
    );
  }
}

// ─── CHAT SCREEN ──────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage('Hello! How can I help you today?', false, DateTime.now().subtract(const Duration(minutes: 5))),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    if (_ctrl.text.isEmpty) return;
    final text = _ctrl.text;
    _ctrl.clear();
    setState(() => _messages.add(_ChatMessage(text, true, DateTime.now())));

    // Simulate reply
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _messages.add(_ChatMessage(
          'Thank you for reaching out! Our team will get back to you shortly.',
          false,
          DateTime.now(),
        )));
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    _scroll.animateTo(_scroll.position.maxScrollExtent + 100, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(radius: 16, backgroundColor: AppColors.primaryRed, child: Icon(Icons.support_agent_rounded, size: 16, color: Colors.white)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Support Team', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Row(children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Online', style: TextStyle(color: AppColors.success, fontSize: 10)),
                ]),
              ],
            ),
          ],
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m.isUser ? AppColors.primaryRed : AppColors.cardBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: m.isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: m.isUser ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    child: Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ).animate().fadeIn(duration: 300.ms);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.surface, border: const Border(top: BorderSide(color: AppColors.divider))),
            child: Row(
              children: [
                Expanded(child: AppTextField(hint: 'Type a message...', controller: _ctrl, onChanged: (_) => setState(() {}))),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  _ChatMessage(this.text, this.isUser, this.time);
}

// ─── TICKET SCREEN ────────────────────────────────────────────────────────────

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});
  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  String? _category;
  final _ctrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Raise a Ticket'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Issue Category', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['Booking Issue', 'Payment Problem', 'Quality Complaint', 'Other'].map((c) {
                final sel = _category == c;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primaryRed.withValues(alpha: 0.1) : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? AppColors.primaryRed : AppColors.divider),
                    ),
                    child: Text(c, style: TextStyle(color: sel ? AppColors.primaryRed : AppColors.textSecondary, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Describe Your Issue', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            AppTextField(hint: 'Describe the issue in detail...', controller: _ctrl, maxLines: 5),
            const Spacer(),
            AppButton(
              label: 'Submit Ticket',
              isLoading: _isLoading,
              onPressed: _category == null ? null : () async {
                setState(() => _isLoading = true);
                await Future.delayed(const Duration(milliseconds: 1200));
                if (mounted) {
                  setState(() => _isLoading = false);
                  showAppSnackbar(context, 'Ticket submitted! ID: TKT-${(1000 + DateTime.now().millisecond).toString()}');
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
