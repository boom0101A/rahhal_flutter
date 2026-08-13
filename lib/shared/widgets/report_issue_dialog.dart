import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/injection.dart';
import '../../core/network/issue_report_service.dart';

/// Small "report this AI result as wrong" dialog, shared by the stop detail
/// screen, the restaurant/hotel detail sheets, and the AI chat screen — one
/// widget instead of tripling the same AlertDialog+TextField pattern.
Future<void> showReportIssueDialog(
  BuildContext context, {
  required String sourceType,
  required String tripId,
  required String itemId,
  String? itemName,
  String? placeId,
  String? aiContext,
}) async {
  final strings = AppStrings.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final controller = TextEditingController();

  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.adaptiveBgCard(dialogContext),
      title: Text(strings.reportIssueTitle, style: AppTextStyles.titleMedium),
      content: TextField(
        controller: controller,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(hintText: strings.reportIssueHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
          child: Text(strings.reportIssueSubmit),
        ),
      ],
    ),
  );
  controller.dispose();
  if (reason == null || reason.isEmpty || !context.mounted) return;

  final ok = await sl<IssueReportService>().submitReport(
    sourceType: sourceType,
    tripId: tripId,
    itemId: itemId,
    itemName: itemName,
    placeId: placeId,
    reason: reason,
    extraContext: aiContext,
  );
  if (!context.mounted) return;
  messenger.showSnackBar(
    SnackBar(content: Text(ok ? strings.reportIssueSuccess : strings.reportIssueFailed)),
  );
}
