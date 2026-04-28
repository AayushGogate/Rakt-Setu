// lib/screens/doctor/doctor_home_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import 'request_form_screen.dart';


class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  Position? _position;
  bool _locating = false;

  // Demo: recent requests (in production, stream from Firestore by hospitalId)
  final List<_RecentRequest> _recent = [
    const _RecentRequest('O+', 2, RequestStatus.dispatched, '12 mins ago'),
    const _RecentRequest('B-', 1, RequestStatus.completed,  '2 hrs ago'),
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() => _locating = false); return; }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() => _locating = false); return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() { _position = pos; _locating = false; });
    } catch (_) {
      setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    //final s = LocaleHelper.strings;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title:  const Text('RaktSetu'),
        actions: [
          const LanguageToggleButton(),
          IconButton(
            icon: const Icon(Icons.exit_to_app_outlined, size: 20),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const _RoleBack()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Emergency request button — the primary CTA
              _EmergencyButton(
                position: _position,
                locating: _locating,
                onTap: () {
                  if (_position == null && !_locating) {
                    _getLocation();
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RequestFormScreen(position: _position),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Location status
              if (_locating)
                const _InfoBanner(
                  icon: Icons.my_location,
                  text: 'Getting your location for accurate matching...',
                  color: AppColors.info,
                )
              else if (_position != null)
                const _InfoBanner(
                  icon: Icons.location_on,
                  text: 'Location ready — matching will use your GPS',
                  color: AppColors.success,
                )
              else
                _InfoBanner(
                  icon: Icons.location_off,
                  text: 'Enable location for nearest blood bank matching',
                  color: AppColors.warning,
                  onTap: _getLocation,
                ),

              const SizedBox(height: 28),

              // Quick blood type request chips
              Text('Quick request',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12, letterSpacing: 0.8)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: BloodTypeHelper.allDisplay.map((bt) =>
                  _QuickChip(
                    bloodType: bt,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RequestFormScreen(
                          position: _position,
                          preselectedType: bt,
                        ),
                      ),
                    ),
                  ),
                ).toList(),
              ),

              const SizedBox(height: 28),

              // Recent requests
              if (_recent.isNotEmpty) ...[
                const SectionHeader(title: 'Recent requests'),
                const SizedBox(height: 12),
                ..._recent.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RecentRequestCard(
                    request: r,
                    onTap: () {
                      // In production: navigate with real requestId
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Loading request...')),
                      );
                    },
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Emergency button ──────────────────────────────────────────────────────────
class _EmergencyButton extends StatelessWidget {
  final Position? position;
  final bool locating;
  final VoidCallback onTap;

  const _EmergencyButton({
    required this.position, required this.locating, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.water_drop, color: Colors.white, size: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('URGENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      fontFamily: 'Outfit',
                    )),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Request Blood',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontFamily: 'Outfit',
                letterSpacing: -0.5,
              )),
            const SizedBox(height: 4),
            Text(
              locating
                ? 'Getting location...'
                : position != null
                  ? 'Tap to find nearest available blood'
                  : 'Location needed — tap to enable',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontFamily: 'Outfit',
              )),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.flash_on, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('AI matching · Real-time routing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                  )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info banner ───────────────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const _InfoBanner({required this.icon, required this.text,
    required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text,
              style: TextStyle(fontSize: 12, color: color,
                fontWeight: FontWeight.w500, fontFamily: 'Outfit'))),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 12, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Quick blood type chip ─────────────────────────────────────────────────────
class _QuickChip extends StatelessWidget {
  final String bloodType;
  final VoidCallback onTap;

  const _QuickChip({required this.bloodType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.water_drop, size: 12, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(bloodType,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                fontFamily: 'Outfit', color: AppColors.textPrimary,
              )),
          ],
        ),
      ),
    );
  }
}

class _RecentRequest {
  final String bloodType;
  final int units;
  final RequestStatus status;
  final String timeAgo;
  const _RecentRequest(this.bloodType, this.units, this.status, this.timeAgo);
}

class _RecentRequestCard extends StatelessWidget {
  final _RecentRequest request;
  final VoidCallback onTap;

  const _RecentRequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            BloodTypeBadge(displayType: request.bloodType),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${request.units} unit${request.units > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.titleMedium),
                  Text(request.timeAgo,
                    style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            StatusChip(status: request.status),
          ],
        ),
      ),
    );
  }
}

class _RoleBack extends StatelessWidget {
  const _RoleBack();
  @override
  Widget build(BuildContext context) {
    // Import role selection
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}