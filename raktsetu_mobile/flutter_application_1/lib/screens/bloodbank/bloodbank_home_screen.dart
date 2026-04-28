// lib/screens/bloodbank/bloodbank_home_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common_widgets.dart';
import 'inventory_screen.dart';

class BloodBankHomeScreen extends StatefulWidget {
  const BloodBankHomeScreen({super.key});

  @override
  State<BloodBankHomeScreen> createState() => _BloodBankHomeScreenState();
}

class _BloodBankHomeScreenState extends State<BloodBankHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // In production, this would come from authenticated user profile
  // For prototype: hardcoded to first bank in Firestore
  static const String _myBankId = 'YOUR_BANK_ID_HERE';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = LocaleHelper.strings;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            const Text('Blood Bank'),
          ],
        ),
        actions: [
          const LanguageToggleButton(),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const InventoryScreen(bankId: _myBankId),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: s.pendingRequests),
            Tab(text: s.myInventory),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _PendingRequestsTab(bankId: _myBankId),
          _InventoryTab(bankId: _myBankId),
        ],
      ),
    );
  }
}

// ── Pending requests tab ──────────────────────────────────────────────────────
class _PendingRequestsTab extends StatelessWidget {
  final String bankId;
  const _PendingRequestsTab({required this.bankId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BloodRequest>>(
      stream: FirestoreService.pendingRequestsForBank(bankId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
            color: AppColors.primary));
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const EmptyState(
            icon: '✅',
            title: 'No pending requests',
            subtitle: 'New blood requests will appear here in real time',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _RequestCard(
            request: requests[i],
            bankId: bankId,
          ),
        );
      },
    );
  }
}

// ── Request card for blood bank ───────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final BloodRequest request;
  final String bankId;

  const _RequestCard({required this.request, required this.bankId});

  Future<void> _confirm(BuildContext context) async {
    final eta = await showDialog<String>(
      context: context,
      builder: (_) => const _EtaDialog(),
    );
    if (eta == null) return;

    try {
      await FirestoreService.confirmRequest(
        request.id, bankId, 'Our Blood Bank', eta,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request confirmed. Hospital notified.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
            backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _dispatch(BuildContext context) async {
    await FirestoreService.markDispatched(request.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marked as dispatched. Family notified.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject request?'),
        content: const Text('This will notify the hospital to find another bank.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirm != true) return;
    await FirestoreService.rejectRequest(request.id);
  }

  @override
  Widget build(BuildContext context) {
    final s = LocaleHelper.strings;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              BloodTypeBadge(displayType: request.bloodTypeDisplay, fontSize: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${request.unitsNeeded} unit${request.unitsNeeded > 1 ? "s" : ""} needed',
                      style: Theme.of(context).textTheme.titleMedium),
                    if (request.createdAt != null)
                      Text(_timeAgo(request.createdAt!),
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              StatusChip(status: request.status),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),

          // Action buttons
          if (request.status == RequestStatus.pending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reject(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(s.rejectRequest),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _confirm(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(s.acceptRequest),
                  ),
                ),
              ],
            )
          else if (request.status == RequestStatus.confirmed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _dispatch(context),
                icon: const Icon(Icons.local_shipping_outlined, size: 16),
                label: Text(s.markDispatched),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            )
          else
            StatusChip(status: request.status),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── ETA dialog ────────────────────────────────────────────────────────────────
class _EtaDialog extends StatefulWidget {
  const _EtaDialog();

  @override
  State<_EtaDialog> createState() => _EtaDialogState();
}

class _EtaDialogState extends State<_EtaDialog> {
  String _selected = '15 mins';
  final _options = ['5 mins', '10 mins', '15 mins', '20 mins', '30 mins', '45 mins', '1 hour'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Estimated delivery time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _options.map((opt) => RadioListTile<String>(
          title: Text(opt, style: const TextStyle(fontFamily: 'Outfit')),
          value: opt,
          groupValue: _selected,
          activeColor: AppColors.primary,
          onChanged: (v) => setState(() => _selected = v!),
          dense: true,
        )).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Confirm')),
      ],
    );
  }
}

// ── Inventory tab ─────────────────────────────────────────────────────────────
class _InventoryTab extends StatelessWidget {
  final String bankId;
  const _InventoryTab({required this.bankId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BloodBank?>(
      stream: FirestoreService.bankStream(bankId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
            color: AppColors.primary));
        }

        final bank = snapshot.data;
        if (bank == null) {
          return EmptyState(
            icon: '🏥',
            title: 'Bank not found',
            subtitle: 'Bank ID: $bankId',
            onAction: () {},
            actionLabel: 'Retry',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BankInfoCard(bank: bank),
              const SizedBox(height: 16),
              Text('Current stock',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12, letterSpacing: 0.8)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.8,
                children: BloodTypeHelper.allDisplay.map((bt) {
                  final key   = BloodTypeHelper.key(bt);
                  final units = bank.unitsOf(key);
                  return MetricCard(
                    label: bt,
                    value: '$units',
                    sub: 'units',
                    valueColor: units < 5 ? AppColors.danger
                        : units < 10 ? AppColors.warning
                        : AppColors.success,
                    borderTopColor: units < 5 ? AppColors.danger
                        : units < 10 ? AppColors.warning
                        : AppColors.success,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InventoryScreen(bankId: bankId),
                    ),
                  ),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Update stock'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BankInfoCard extends StatelessWidget {
  final BloodBank bank;
  const _BankInfoCard({required this.bank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryFade, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bank.name, style: Theme.of(context).textTheme.titleLarge),
                Text(bank.address,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}