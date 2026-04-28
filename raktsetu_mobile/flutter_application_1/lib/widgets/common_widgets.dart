// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

// ── Blood type badge ──────────────────────────────────────────────────────────
class BloodTypeBadge extends StatelessWidget {
  final String displayType; // "O+", "B-", etc.
  final double fontSize;

  const BloodTypeBadge({super.key, required this.displayType, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    final key = BloodTypeHelper.key(displayType);
    final bg   = AppColors.bloodTypeBg[key]   ?? AppColors.primaryFade;
    final text = AppColors.bloodTypeText[key]  ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        displayType,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: text,
          fontFamily: 'Outfit',
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────
class StatusChip extends StatelessWidget {
  final RequestStatus status;
  final bool marathi;

  const StatusChip({super.key, required this.status, this.marathi = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      RequestStatus.pending    => (AppColors.warningFade, AppColors.warning),
      RequestStatus.confirmed  => (AppColors.infoFade,    AppColors.info),
      RequestStatus.dispatched => (AppColors.successFade, AppColors.success),
      RequestStatus.completed  => (AppColors.successFade, AppColors.success),
      RequestStatus.rejected   => (AppColors.dangerFade,  AppColors.danger),
    };
    final label = marathi ? status.displayLabelMr : status.displayLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: fg, fontFamily: 'Outfit')),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
            if (onAction != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel ?? 'Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Metric card ───────────────────────────────────────────────────────────────
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? valueColor;
  final Color? borderTopColor;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.valueColor,
    this.borderTopColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: borderTopColor ?? AppColors.border, width: 2.5),
          left: const BorderSide(color: AppColors.border, width: 0.5),
          right: const BorderSide(color: AppColors.border, width: 0.5),
          bottom: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
            fontFamily: 'Outfit',
          )),
          if (sub != null)
            Text(sub!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ── Loading overlay ───────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 40, height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}