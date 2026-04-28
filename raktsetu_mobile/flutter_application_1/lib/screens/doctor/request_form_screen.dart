// lib/screens/doctor/request_form_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'result_screen.dart';

class RequestFormScreen extends StatefulWidget {
  final Position? position;
  final String? preselectedType;

  const RequestFormScreen({super.key, this.position, this.preselectedType});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  String _selectedType = 'O+';
  int _units = 1;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null) {
      _selectedType = widget.preselectedType!;
    }
  }

  Future<void> _search() async {
    if (widget.position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available. Please enable GPS.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await ApiService.findMatches(
      bloodType:   _selectedType,
      unitsNeeded: _units,
      hospitalLat: widget.position!.latitude,
      hospitalLng: widget.position!.longitude,
      hospitalId:  'hospital_${DateTime.now().millisecondsSinceEpoch}',
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (result.isNoMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No $_selectedType blood available nearby right now.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result.error}'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          requestId:   result.requestId!,
          bloodType:   _selectedType,
          unitsNeeded: _units,
          matches:     result.banks,
          position:    widget.position!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = LocaleHelper.strings;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text(s.raiseRequest),
            actions: const [LanguageToggleButton()],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Blood type selector
                  Text(s.bloodType,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 12, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  _BloodTypeGrid(
                    selected: _selectedType,
                    onSelect: (t) => setState(() => _selectedType = t),
                  ),

                  const SizedBox(height: 28),

                  // Units selector
                  Text(s.unitsNeeded,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 12, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  _UnitsSelector(
                    value: _units,
                    onChange: (v) => setState(() => _units = v),
                  ),

                  const SizedBox(height: 28),

                  // Summary card
                  _SummaryCard(bloodType: _selectedType, units: _units),

                  const Spacer(),

                  // Search button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _search,
                      icon: const Icon(Icons.search, size: 18),
                      label: Text(s.findingBlood),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'AI matching · ${widget.position != null ? "GPS ready" : "No GPS"}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),

        // Loading overlay
        if (_loading)
          LoadingOverlay(message: LocaleHelper.strings.findingBlood),
      ],
    );
  }
}

// ── Blood type grid selector ──────────────────────────────────────────────────
class _BloodTypeGrid extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _BloodTypeGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: BloodTypeHelper.allDisplay.map((bt) {
        final isSelected = bt == selected;
        final key = BloodTypeHelper.key(bt);
        final bg   = AppColors.bloodTypeBg[key]   ?? AppColors.primaryFade;
        final fg   = AppColors.bloodTypeText[key]  ?? AppColors.primary;

        return GestureDetector(
          onTap: () => onSelect(bt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? fg : bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? fg : fg.withOpacity(0.3),
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(bt,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : fg,
                fontFamily: 'Outfit',
              )),
          ),
        );
      }).toList(),
    );
  }
}

// ── Units stepper ─────────────────────────────────────────────────────────────
class _UnitsSelector extends StatelessWidget {
  final int value;
  final void Function(int) onChange;

  const _UnitsSelector({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Text('Units needed',
            style: Theme.of(context).textTheme.bodyLarge),
          const Spacer(),
          _StepBtn(
            icon: Icons.remove,
            onTap: () { if (value > 1) onChange(value - 1); },
            enabled: value > 1,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('$value',
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700,
                fontFamily: 'Outfit', color: AppColors.textPrimary,
              )),
          ),
          _StepBtn(
            icon: Icons.add,
            onTap: () { if (value < 10) onChange(value + 1); },
            enabled: value < 10,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepBtn({required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryFade : AppColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? AppColors.primary.withOpacity(0.3) : AppColors.border,
          ),
        ),
        child: Icon(icon,
          size: 18,
          color: enabled ? AppColors.primary : AppColors.disabled),
      ),
    );
  }
}

// ── Summary card before searching ─────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String bloodType;
  final int units;

  const _SummaryCard({required this.bloodType, required this.units});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryFade,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                children: [
                  const TextSpan(text: 'Looking for '),
                  TextSpan(text: '$units unit${units > 1 ? "s" : ""} ',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                  const TextSpan(text: 'of '),
                  TextSpan(text: bloodType,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    )),
                  const TextSpan(text: ' blood nearby'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}