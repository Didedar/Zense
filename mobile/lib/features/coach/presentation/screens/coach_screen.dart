import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/feature_providers.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  final _quickPrompts = [
    'Как мне начать копить?',
    'Стоит ли мне экономить на еде?',
    'Как перестать тратить импульсивно?',
    'На чём можно сэкономить?',
    'Как увеличить доход?',
  ];

  @override
  void initState() {
    super.initState();
    _loadInsight();
  }

  Future<void> _loadInsight() async {
    try {
      final insight = await ref.read(featureApiProvider).getLatestInsight();
      setState(() {
        _messages.insert(
            0,
            _ChatMessage(
                text: insight.message,
                isUser: false,
                actions: insight.actions));
      });
    } catch (_) {
      // No insight yet
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _messageController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await ref.read(featureApiProvider).askCoach(text);
      setState(() {
        _messages.add(_ChatMessage(
          text: response.answer,
          isUser: false,
          actions: response.suggestedActions.map((a) => a.action).toList(),
          disclaimer: response.disclaimer,
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(text: 'Ошибка: $e', isUser: false));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('AI Коуч'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          // Quick prompts
          if (_messages.length < 2)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _quickPrompts
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label:
                                Text(p, style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.surface,
                            side: const BorderSide(
                                color: AppColors.surfaceBorder),
                            onPressed: () => _sendMessage(p),
                          ),
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 8),
          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Спроси что-нибудь...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading
                        ? null
                        : () => _sendMessage(_messageController.text),
                    icon: const Icon(Icons.send_rounded),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_outlined,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Привет! 👋',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Я твой финансовый коуч.\nСпроси меня о бюджете, целях или как лучше управлять деньгами.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: msg.isUser ? const Radius.circular(4) : null,
            bottomLeft: !msg.isUser ? const Radius.circular(4) : null,
          ),
          border:
              msg.isUser ? null : Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser
                    ? AppColors.textOnPrimary
                    : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            if (msg.disclaimer != null) ...[
              const SizedBox(height: 8),
              Text(msg.disclaimer!,
                  style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                      fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16)
              .copyWith(bottomLeft: const Radius.circular(4)),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary)),
            const SizedBox(width: 8),
            Text('Думаю...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? actions;
  final String? disclaimer;

  _ChatMessage(
      {required this.text,
      required this.isUser,
      this.actions,
      this.disclaimer});
}
