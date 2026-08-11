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
import '../../data/trip_command_executor.dart';
import '../../domain/trip_command.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../../trip_planner/domain/entities/trip_entity.dart';
import '../../../trip_planner/domain/repositories/trip_repository.dart';
import '../../../itinerary/domain/repositories/itinerary_repository.dart';

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

  List<String> _suggestions(BuildContext context) {
    final strings = AppStrings.of(context);
    return [
      strings.chatQuickReply1,
      strings.chatQuickReply2,
      strings.chatQuickReply3,
      strings.chatQuickReply4,
      strings.chatQuickReply5,
      strings.chatQuickReply6,
    ];
  }

  // Compact text summary of the itinerary, fed to the AI so replan-style
  // questions ("best order for today", "indoor alternative") are grounded in
  // the real stops rather than generic destination advice.
  String _itineraryContext = '';
  bool _contextReady = false;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    if (_trip == null) {
      _loadTrip();
    } else {
      _loadItineraryContext();
    }
  }

  Future<void> _loadTrip() async {
    setState(() => _isLoading = true);
    final result = await sl<TripRepository>().getTripById(widget.tripId);
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.of(context).snackTripNotFound)),
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
          _loadItineraryContext();
        }
      },
    );
  }

  /// Best-effort: any failure just leaves the context empty and the assistant
  /// falls back to destination-level advice.
  Future<void> _loadItineraryContext() async {
    try {
      final daysResult =
          await sl<ItineraryRepository>().getDaysForTrip(widget.tripId);
      final buffer = StringBuffer();
      await daysResult.fold(
        (_) async {},
        (days) async {
          for (final day in days) {
            final stopsResult =
                await sl<ItineraryRepository>().getStopsForDay(day.id);
            stopsResult.fold((_) {}, (stops) {
              if (stops.isEmpty) return;
              final names = stops.map((s) => s.nameEn?.isNotEmpty == true
                  ? s.nameEn!
                  : s.name);
              // Use the reader's language so the context handed to the model
              // matches the language they're actually chatting in.
              final dayTheme = day.displayTheme(context);
              final theme = dayTheme != null ? ' ($dayTheme)' : '';
              buffer.writeln('Day ${day.dayNumber}$theme: ${names.join(', ')}');
            });
          }
        },
      );
      _itineraryContext = buffer.toString().trim();
    } catch (_) {
      _itineraryContext = '';
    }
    if (mounted) setState(() => _contextReady = true);
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

    // Some messages are instructions to change the itinerary rather than
    // questions. Those are handled locally — and only ever after an explicit
    // confirmation — instead of being sent to the model.
    final command = parseTripCommand(text);
    if (command != null) {
      _handleCommand(command);
      return;
    }

    context.read<ChatCubit>().sendMessage(text);
    _scrollToBottom();
  }

  /// Resolves the command against the real trip, shows exactly what will
  /// change, and applies it only if the user confirms.
  Future<void> _handleCommand(TripCommand command) async {
    // Uses the State's own context so the `mounted` checks below actually
    // guard it across the awaits.
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final executor = sl<TripCommandExecutor>();

    final preview =
        await executor.preview(tripId: widget.tripId, command: command);
    if (!mounted) return;

    if (!preview.canRun) {
      final message = switch (preview.problem) {
        'ambiguous' => strings.cmdAmbiguous(preview.targetLabel),
        'not-found' => strings.cmdNotFound(preview.targetLabel),
        _ => strings.cmdFailed,
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final body = switch (command.kind) {
      TripCommandKind.deleteDay => () {
          // targetLabel packs "dayNumber|stopCount" from the preview.
          final parts = preview.targetLabel.split('|');
          return strings.cmdDeleteDayBody(
            int.tryParse(parts.first) ?? command.dayNumber ?? 0,
            parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
          );
        }(),
      TripCommandKind.deleteStop =>
        strings.cmdDeleteStopBody(preview.targetLabel),
      TripCommandKind.markVisited =>
        strings.cmdMarkVisitedBody(preview.targetLabel),
    };

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.adaptiveBgPopover(dialogContext),
            title: Text(strings.cmdConfirmTitle,
                style: AppTextStyles.titleMedium),
            content: Text(body, style: AppTextStyles.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(strings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  preview.isDestructive
                      ? strings.cmdConfirmDelete
                      : strings.cmdConfirmApply,
                  style: TextStyle(
                    color: preview.isDestructive
                        ? AppColors.error
                        : AppColors.accentTurquoise,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    final ok = await executor.apply(preview);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(ok ? strings.cmdDone : strings.cmdFailed)),
    );
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
    if (_trip == null || _isLoading || !_contextReady) {
      return Scaffold(
        backgroundColor: AppColors.adaptiveBgPrimary(context),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accentAmber),
        ),
      );
    }

    return BlocProvider(
      create: (_) => sl<ChatCubit>()
        ..initChat(
          tripId: widget.tripId,
          destination: _trip?.destination ?? '',
          tripSummary: [
            _trip?.displayAiSummary(context) ?? '',
            if (_itineraryContext.isNotEmpty) 'Itinerary:\n$_itineraryContext',
          ].where((s) => s.isNotEmpty).join('\n\n'),
        ),
      child: BlocListener<ChatCubit, ChatState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            current.errorMessage != previous.errorMessage,
        listener: (context, state) {
          if (state.failedMessageText != null) {
            _msgCtrl.text = state.failedMessageText!;
            _msgCtrl.selection =
                TextSelection.collapsed(offset: _msgCtrl.text.length);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<ChatCubit>().clearError();
        },
        child: Scaffold(
          backgroundColor: AppColors.adaptiveBgPrimary(context),
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
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.adaptiveBorder(context))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: AppStrings.of(context).back,
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.adaptiveTextPrimary(context), size: 20),
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
                Text(AppStrings.of(context).chatTitle, style: AppTextStyles.titleMedium),
                Text(AppStrings.of(context).chatOnlineStatus,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                    )),
              ],
            ),
          ),
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) => IconButton(
              tooltip: AppStrings.of(context).chatClearHistory,
              onPressed: state.messages.isEmpty
                  ? null
                  : () => context.read<ChatCubit>().clearHistory(),
              icon: Icon(Icons.refresh_rounded,
                  color: AppColors.adaptiveTextSecondary(context), size: 20),
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
          AppStrings.of(context).chatIntroTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.of(context).chatIntroSubtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        // Free-text guidance prompt card
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Text(
            AppStrings.of(context).chatIntroHint,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Text(AppStrings.of(context).chatSuggestedQuestions, style: AppTextStyles.titleSmall),
        const SizedBox(height: 12),
        ..._suggestions(context).map((s) => _SuggestionChip(
              text: s,
              onTap: () {
                _msgCtrl.text = s;
                _msgCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: _msgCtrl.text.length),
                );
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
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.adaptiveBorder(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.adaptiveGlass(context),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.adaptiveBorder(context)),
              ),
              child: TextField(
                controller: _msgCtrl,
                style: AppTextStyles.bodyMedium,
                maxLines: null,
                textDirection: AppStrings.of(context).languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: AppStrings.of(context).chatHint,
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.adaptiveTextSecondary(context)),
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
                    ? AppColors.adaptiveTextSecondary(context).withValues(alpha: 0.3)
                    : null,
                boxShadow: isTyping ? null : AppColors.amberGlow,
              ),
              child: Icon(
                Icons.send_rounded,
                // Matches the rest of the app's convention of dark text/icons
                // on the amber gradient (white on amber fails contrast).
                // The disabled "typing" state's background is a translucent
                // adaptiveTextSecondary — in light mode that's a pale gray,
                // so the icon must adapt too or it washes out.
                color: isTyping
                    ? AppColors.adaptiveTextPrimary(context)
                    : AppColors.bgPrimary,
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
    final isRTL = AppStrings.of(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        // For RTL: user = end (right), AI = start (left)
        // For LTR: user = end (right), AI = start (left) — same!
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // AI avatar on the left always
            _buildAIAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.amberGradient : null,
                color: isUser ? null : AppColors.adaptiveBgCard(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                ),
                border: isUser ? null : Border.all(color: AppColors.adaptiveBorder(context)),
              ),
              child: Text(
                message.content,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isUser ? AppColors.onAmber : AppColors.adaptiveTextPrimary(context),
                ),
                textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 30 * index),
          duration: 300.ms,
        );
  }

  Widget _buildAIAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [
          AppColors.accentAmber.withValues(alpha: 0.3),
          AppColors.accentTurquoise.withValues(alpha: 0.2),
        ]),
      ),
      child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsetsDirectional.only(end: 8),
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
              color: AppColors.adaptiveGlass(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: AppColors.adaptiveBorder(context)),
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
            Icon(Icons.chevron_left_rounded,
                color: AppColors.adaptiveTextSecondary(context), size: 18),
          ],
        ),
      ),
    );
  }
}
