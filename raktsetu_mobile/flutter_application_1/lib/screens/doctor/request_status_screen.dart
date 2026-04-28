// lib/screens/doctor/request_status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common_widgets.dart';

class RequestStatusScreen extends StatelessWidget {
  final String requestId;

  const RequestStatusScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    // Assuming LocaleHelper provides localized strings for your presentation
    final s = LocaleHelper.strings;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(s.requestSent),
        automaticallyImplyLeading: false,
        actions: const [LanguageToggleButton()],
      ),
      body: StreamBuilder<BloodRequest?>(
        // This connects directly to your P1 Firestore logic
        stream: FirestoreService.requestStream(requestId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final request = snapshot.data;
          if (request == null) {
            return EmptyState(
              icon: '❓',
              title: 'Request not found',
              subtitle: 'Request ID: $requestId',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _StatusHeroCard(request: request),
                const SizedBox(height: 20),
                _ShareCard(requestId: requestId),
                const SizedBox(height: 20),
                _StatusTimeline(status: request.status),
                const SizedBox(height: 20),
                _DetailsCard(request: request),
                const SizedBox(height: 24),
                
                if (request.status == RequestStatus.completed ||
                    request.status == RequestStatus.rejected)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Status Hero Card ──────────────────────────────────────────────────────────
class _StatusHeroCard extends StatelessWidget {
  final BloodRequest request;
  const _StatusHeroCard({required this.request});

  @override
  Widget build(BuildContext context) {
    // Modern Dart Switch Expression for UI State
    final (bg, fg, icon, headline, subline) = switch (request.status) {
      RequestStatus.pending => (
        AppColors.warningFade, AppColors.warning,
        '⏳', LocaleHelper.strings.awaitingConfirm,
        'Blood bank will confirm shortly',
      ),
      RequestStatus.confirmed => (
        AppColors.infoFade, AppColors.info,
        '✅', 'Blood bank confirmed!',
        request.dispatchedFrom != null
            ? 'Dispatching from ${request.dispatchedFrom}'
            : 'Preparing blood for dispatch',
      ),
      RequestStatus.dispatched => (
        AppColors.successFade, AppColors.success,
        '🚗', LocaleHelper.strings.bloodOnTheWay,
        request.eta != null ? 'Arriving in ${request.eta}' : 'On the way',
      ),
      RequestStatus.completed => (
        AppColors.successFade, AppColors.success,
        '🎉', 'Blood delivered!',
        'Request fulfilled successfully',
      ),
      RequestStatus.rejected => (
        AppColors.dangerFade, AppColors.danger,
        '❌', 'Request rejected',
        'Please raise a new request',
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(headline,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: fg,
                fontFamily: 'Outfit',
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(subline,
              style: TextStyle(
                  fontSize: 14, color: fg.withValues(alpha: 0.8), fontFamily: 'Outfit'),
              textAlign: TextAlign.center),
          if (request.status == RequestStatus.dispatched && request.eta != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(request.eta!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Outfit',
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Share Tracking Card ───────────────────────────────────────────────────────
class _ShareCard extends StatelessWidget {
  final String requestId;
  const _ShareCard({required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Share with family', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Family can track this request live',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Text(requestId,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: requestId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request ID copied')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFade,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Timeline with Named Records ──────────────────────────────────────────────
class _StatusTimeline extends StatelessWidget {
  final RequestStatus status;
  const _StatusTimeline({required this.status});

  // FIXED: Using Named Records for production stability
  static const List<({RequestStatus status, String icon, String title, String sub})> _steps = [
    (status: RequestStatus.pending, icon: '🔍', title: 'Request raised', sub: 'Finding blood bank'),
    (status: RequestStatus.confirmed, icon: '✅', title: 'Confirmed', sub: 'Blood bank accepted'),
    (status: RequestStatus.dispatched, icon: '🚗', title: 'Dispatched', sub: 'Blood en route'),
    (status: RequestStatus.completed, icon: '🎉', title: 'Delivered', sub: 'Complete'),
  ];

  int get _currentStep {
    switch (status) {
      case RequestStatus.pending: return 0;
      case RequestStatus.confirmed: return 1;
      case RequestStatus.dispatched: return 2;
      case RequestStatus.completed: return 3;
      case RequestStatus.rejected: return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status timeline', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          ..._steps.asMap().entries.map((entry) {
            final idx = entry.key;
            final step = entry.value;
            final isDone = idx < _currentStep;
            final isCurrent = idx == _currentStep;
            final isLast = idx == _steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: isDone || isCurrent
                            ? (isDone ? AppColors.success : AppColors.primary)
                            : AppColors.bg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone || isCurrent
                              ? (isDone ? AppColors.success : AppColors.primary)
                              : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isDone
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text(step.icon, style: const TextStyle(fontSize: 12)),
                    ),
                    if (!isLast)
                      Container(
                        width: 1.5, height: 32,
                        color: isDone ? AppColors.success : AppColors.border,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                              color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
                              fontFamily: 'Outfit',
                            )),
                        Text(step.sub,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                        if (!isLast) const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Details Card ──────────────────────────────────────────────────────────────
class _DetailsCard extends StatelessWidget {
  final BloodRequest request;
  const _DetailsCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request details', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _Row('Blood type', request.bloodTypeDisplay),
          _Row('Units', '${request.unitsNeeded}'),
          if (request.dispatchedFrom != null) _Row('Blood bank', request.dispatchedFrom!),
          if (request.eta != null) _Row('ETA', request.eta!),
          _Row('Request ID', request.id, mono: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  const _Row(this.label, this.value, {this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    fontFamily: mono ? 'monospace' : 'Outfit',
                  ),
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}