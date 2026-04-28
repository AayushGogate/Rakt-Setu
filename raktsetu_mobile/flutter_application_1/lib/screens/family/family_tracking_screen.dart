// lib/screens/family/family_tracking_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common_widgets.dart';

class FamilyTrackingScreen extends StatefulWidget {
  const FamilyTrackingScreen({super.key});

  @override
  State<FamilyTrackingScreen> createState() => _FamilyTrackingScreenState();
}

class _FamilyTrackingScreenState extends State<FamilyTrackingScreen> {
  final _controller = TextEditingController();
  String? _trackingId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Track Blood Delivery'),
        actions: const [LanguageToggleButton()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter Request ID',
                style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Paste request ID from doctor',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (_controller.text.trim().isNotEmpty) {
                        setState(() => _trackingId = _controller.text.trim());
                      }
                    },
                    child: const Text('Track'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (_trackingId != null)
                Expanded(
                  child: StreamBuilder<BloodRequest?>(
                    stream: FirestoreService.requestStream(_trackingId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(
                          color: AppColors.primary));
                      }
                      final req = snapshot.data;
                      if (req == null) {
                        return const EmptyState(
                          icon: '❓',
                          title: 'Request not found',
                          subtitle: 'Check the ID and try again',
                        );
                      }
                      return _FamilyStatusView(request: req);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyStatusView extends StatelessWidget {
  final BloodRequest request;
  const _FamilyStatusView({required this.request});

  @override
  Widget build(BuildContext context) {
    final isOnTheWay = request.status == RequestStatus.dispatched;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isOnTheWay ? AppColors.successFade : AppColors.infoFade,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOnTheWay
                ? AppColors.success.withOpacity(0.3)
                : AppColors.info.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(isOnTheWay ? '🚗' : '⏳',
                style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(
                isOnTheWay ? 'Blood is on the way!' : request.status.displayLabel,
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: isOnTheWay ? AppColors.success : AppColors.info,
                  fontFamily: 'Outfit',
                ),
                textAlign: TextAlign.center,
              ),
              if (request.eta != null && isOnTheWay) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text('Arriving in ${request.eta}',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w700, fontFamily: 'Outfit',
                    )),
                ),
              ],
              if (request.dispatchedFrom != null) ...[
                const SizedBox(height: 10),
                Text('From: ${request.dispatchedFrom}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isOnTheWay ? AppColors.success : AppColors.info,
                    fontFamily: 'Outfit',
                  )),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: const Border.fromBorderSide(
              BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: Row(
            children: [
              BloodTypeBadge(displayType: request.bloodTypeDisplay),
              const SizedBox(width: 12),
              Text('${request.unitsNeeded} unit${request.unitsNeeded > 1 ? "s" : ""}',
                style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              StatusChip(status: request.status),
            ],
          ),
        ),
      ],
    );
  }
}