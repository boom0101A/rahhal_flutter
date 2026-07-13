# ملف كود Dart: lib\features\ai_chat\presentation\screens\chat_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../cubit/chat_cubit.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../../trip_planner/domain/entities/trip_entity.dart';
import '../../../trip_planner/domain/repositories/trip_repository.dart';

class ChatScreen extends StatefulWidget {
  final String tripId;
  final TripEntity? trip;

  const ChatScreen({super.key, required this.tripId, this.trip});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  TripEntity? _trip;
  bool _isLoading = false;

  List<String> get _suggestions => [
    AppStrings.chatQuickReply1,
    AppStrings.chatQuickReply2,
    AppStrings.chatQuickReply3,
    AppStrings.chatQuickReply4,
  ];

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    if (_trip == null) {
      _loadTrip();
    }
  }

  Future<void> _loadTrip() async {
    setState(() => _isLoading = true);
    final result = await sl<TripRepository>().getTripById(widget.tripId);
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.snackTripNotFound)),
          );
          context.pop();
        }
      },
      (trip) {
        if (mounted) {
          setState(() {
            _trip = trip;
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context) {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    context.read<ChatCubit>().sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_trip == null || _isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentAmber),
        ),
      );
    }

    return BlocProvider(
      create: (_) => sl<ChatCubit>()
        ..initChat(
          tripId: widget.tripId,
          destination: _trip?.destination ?? '',
          tripSummary: _trip?.aiSummary ?? '',
        ),
      child: BlocListener<ChatCubit, ChatState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            current.errorMessage != previous.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        },
        child: Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context),

                // Messages
                Expanded(
                  child: BlocBuilder<ChatCubit, ChatState>(
                    builder: (context, state) {
                      if (state.messages.isEmpty && !state.isTyping) {
                        return _buildWelcome(context);
                      }
                      return _buildMessages(context, state);
                    },
                  ),
                ),

                // Input
                BlocBuilder<ChatCubit, ChatState>(
                  builder: (context, state) =>
                      _buildInput(context, state.isTyping),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.accentAmber.withValues(alpha: 0.3),
                  AppColors.accentTurquoise.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.chatTitle, style: AppTextStyles.titleMedium),
                Text(AppStrings.chatOnlineStatus,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                    )),
              ],
            ),
          ),
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) => IconButton(
              onPressed: state.messages.isEmpty
                  ? null
                  : () => context.read<ChatCubit>().clearHistory(),
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        // Bot avatar
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.accentAmber.withValues(alpha: 0.25),
                  AppColors.accentTurquoise.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 36)),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.05, duration: 2000.ms),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.chatIntroTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.chatIntroSubtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 32),
        Text(AppStrings.chatSuggestions, style: AppTextStyles.titleSmall),
        const SizedBox(height: 12),
        ..._suggestions.map((s) => _SuggestionChip(
              text: s,
              onTap: () {
                _msgCtrl.text = s;
                _sendMessage(context);
              },
            )),
      ],
    );
  }

  Widget _buildMessages(BuildContext context, ChatState state) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.messages.length + (state.isTyping ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (state.isTyping && i == state.messages.length) {
          return _TypingIndicator();
        }
        final msg = state.messages[i];
        return _MessageBubble(message: msg, index: i);
      },
    );
  }

  Widget _buildInput(BuildContext context, bool isTyping) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _msgCtrl,
                style: AppTextStyles.bodyMedium,
                maxLines: null,
                textDirection: AppStrings.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: AppStrings.chatHint,
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(context),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isTyping ? null : () => _sendMessage(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isTyping ? null : AppColors.amberGradient,
                color: isTyping
                    ? AppColors.textSecondary.withValues(alpha: 0.3)
                    : null,
                boxShadow: isTyping ? null : AppColors.amberGlow,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final int index;

  const _MessageBubble({required this.message, required this.index});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentAmber.withValues(alpha: 0.3),
                    AppColors.accentTurquoise.withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 14)),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? null : AppColors.amberGradient,
                color: isUser ? AppColors.glass : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? Radius.zero : const Radius.circular(20),
                  bottomRight: isUser ? const Radius.circular(20) : Radius.zero,
                ),
                border: isUser ? Border.all(color: AppColors.border) : null,
              ),
              child: Text(
                message.content,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isUser ? AppColors.textPrimary : AppColors.bgPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 30 * index),
          duration: 300.ms,
        );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.accentAmber.withValues(alpha: 0.3),
                  AppColors.accentTurquoise.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 14)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentAmber,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(
                      begin: 0.5,
                      end: 1.0,
                      delay: Duration(milliseconds: i * 150),
                      duration: 400.ms,
                    )
                    .then()
                    .scaleXY(begin: 1.0, end: 0.5, duration: 400.ms),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.accentAmber, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: AppTextStyles.bodyMedium),
            ),
            const Icon(Icons.chevron_left_rounded,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

```
