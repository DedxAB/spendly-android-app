import 'package:flutter/material.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';
import 'package:spendly/core/widgets/dialog_actions_row.dart';

Future<bool> showAppDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Delete',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      backgroundColor: Theme.of(dialogContext).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      title: Text(
        title,
        style: Theme.of(dialogContext).textTheme.titleLarge,
      ),
      content: Text(
        message,
        style: Theme.of(
          dialogContext,
        ).textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
      actions: [
        DialogActionsRow(
          cancelText: 'Cancel',
          confirmText: confirmText,
          confirmColor: const Color(0xFFB13232),
          onCancel: () => Navigator.pop(dialogContext, false),
          onConfirm: () => Navigator.pop(dialogContext, true),
        ),
      ],
    ),
  );
  return result == true;
}
