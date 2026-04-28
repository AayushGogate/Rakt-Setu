// lib/screens/bloodbank/inventory_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common_widgets.dart';

class InventoryScreen extends StatefulWidget {
  final String bankId;
  const InventoryScreen({super.key, required this.bankId});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final bt in BloodTypeHelper.allDisplay) {
      _controllers[bt] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      for (final entry in _controllers.entries) {
        final key   = BloodTypeHelper.key(entry.key);
        final units = int.tryParse(entry.value.text) ?? 0;
        await FirestoreService.updateInventoryUnit(widget.bankId, key, units);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock saved successfully'),
            backgroundColor: AppColors.success));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
            backgroundColor: AppColors.danger));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Update Stock'),
        actions: const [LanguageToggleButton()],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ...BloodTypeHelper.allDisplay.map((bt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    BloodTypeBadge(displayType: bt),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _controllers[bt],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Units of $bt',
                          suffixText: 'units',
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : const Text('Save stock'),
                ),
              ),
            ],
          ),
          if (_saving) const LoadingOverlay(message: 'Saving stock...'),
        ],
      ),
    );
  }
}