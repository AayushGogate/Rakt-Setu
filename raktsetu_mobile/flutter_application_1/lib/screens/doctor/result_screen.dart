// lib/screens/doctor/results_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Ensure this is in pubspec.yaml
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Ensure this is in pubspec.yaml
import 'package:url_launcher/url_launcher.dart';

// Internal Project Imports
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common_widgets.dart';
import 'request_status_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String requestId;
  final String bloodType;
  final int unitsNeeded;
  final List<BloodBank> matches;
  final Position position;

  const ResultsScreen({
    super.key,
    required this.requestId,
    required this.bloodType,
    required this.unitsNeeded,
    required this.matches,
    required this.position,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _selectedIndex = 0;
  bool _confirming = false;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  /// Builds custom markers for the hospital and all matched blood banks
  void _buildMarkers() {
    final Set<Marker> markers = {};

    // 1. Hospital marker (Azure color to distinguish from banks)
    markers.add(
      Marker(
        markerId: const MarkerId('hospital'),
        position: LatLng(widget.position.latitude, widget.position.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Hospital'),
      ),
    );

    // 2. Blood bank markers
    for (var i = 0; i < widget.matches.length; i++) {
      final bank = widget.matches[i];
      markers.add(
        Marker(
          markerId: MarkerId('bank_$i'),
          position: LatLng(bank.lat, bank.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == _selectedIndex ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
          ),
          onTap: () {
            setState(() => _selectedIndex = i);
            _buildMarkers(); // Update marker colors
          },
          infoWindow: InfoWindow(
            title: bank.name,
            snippet: 'Travel time: ${bank.travelTime ?? "Calculating..."}',
          ),
        ),
      );
    }
    setState(() => _markers = markers);
  }

  /// Fits the map camera to show both the hospital and all results
  void _fitBounds() {
    if (widget.matches.isEmpty || _mapController == null) return;

    double minLat = widget.position.latitude;
    double maxLat = widget.position.latitude;
    double minLng = widget.position.longitude;
    double maxLng = widget.position.longitude;

    for (var bank in widget.matches) {
      if (bank.lat < minLat) minLat = bank.lat;
      if (bank.lat > maxLat) maxLat = bank.lat;
      if (bank.lng < minLng) minLng = bank.lng;
      if (bank.lng > maxLng) maxLng = bank.lng;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.005, minLng - 0.005),
          northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
        ),
        50.0, // Padding
      ),
    );
  }

  Future<void> _confirmSelection() async {
    if (_confirming) return;
    setState(() => _confirming = true);

    final selectedBank = widget.matches[_selectedIndex];

    try {
      // Logic handled by P1 Backend
      await FirestoreService.confirmRequest(
        widget.requestId,
        selectedBank.id,
        selectedBank.name,
        selectedBank.travelTime ?? 'Unknown',
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RequestStatusScreen(requestId: widget.requestId),
        ),
      );
    } catch (e) {
      setState(() => _confirming = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Confirmation failed: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _callBank(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = LocaleHelper.strings;
    final selected = widget.matches[_selectedIndex];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(s.matchesFound),
        actions: const [LanguageToggleButton()],
      ),
      body: Column(
        children: [
          // MAP SECTION
          SizedBox(
            height: 240,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.position.latitude, widget.position.longitude),
                zoom: 12,
              ),
              markers: _markers,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                _fitBounds();
              },
            ),
          ),

          // RESULTS LIST
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BloodTypeBadge(displayType: widget.bloodType),
                      const SizedBox(width: 10),
                      Text('${widget.unitsNeeded} units requested',
                          style: Theme.of(context).textTheme.titleSmall),
                      const Spacer(),
                      Text('${widget.matches.length} matches',
                          style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...widget.matches.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BankResultCard(
                        bank: entry.value,
                        rank: entry.key + 1,
                        isSelected: entry.key == _selectedIndex,
                        onTap: () {
                          setState(() => _selectedIndex = entry.key);
                          _buildMarkers();
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(LatLng(entry.value.lat, entry.value.lng)),
                          );
                        },
                        onCall: () => _callBank(entry.value.phone),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _confirming ? null : _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _confirming
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Confirm ${selected.name}', style: const TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────

class _BankResultCard extends StatelessWidget {
  final BloodBank bank;
  final int rank;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onCall;

  const _BankResultCard({
    required this.bank,
    required this.rank,
    required this.isSelected,
    required this.onTap,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isSelected ? AppColors.primary : AppColors.bg,
                  child: Text('$rank', style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textSecondary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(bank.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _IconPill(icon: Icons.timer_outlined, label: bank.travelTime ?? 'N/A', color: AppColors.info),
                const SizedBox(width: 8),
                _IconPill(icon: Icons.location_on_outlined, label: bank.distance ?? 'N/A', color: AppColors.success),
                const Spacer(),
                IconButton(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone_in_talk, color: AppColors.success),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _IconPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}