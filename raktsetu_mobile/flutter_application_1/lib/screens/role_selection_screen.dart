// lib/screens/role_selection_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'doctor/doctor_home_screen.dart';
import 'bloodbank/bloodbank_home_screen.dart';
import 'family/family_tracking_screen.dart';

enum UserRole { doctor, bloodBank, family }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  UserRole? _selected;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigate(UserRole role) {
    setState(() => _selected = role);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      Widget screen = switch (role) {
        UserRole.doctor    => const DoctorHomeScreen(),
        UserRole.bloodBank => const BloodBankHomeScreen(),
        UserRole.family    => const FamilyTrackingScreen(),
      };
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => screen,
          transitionsBuilder: (_, a1, a2, child) => FadeTransition(
            opacity: a1,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(a1),
              child: child,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = LocaleHelper.strings;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [

          // ── Blood drop animation — behind everything ──────────────────
          const Positioned.fill(
            child: _BloodDropBackground(),
          ),

          // ── All screen content — in front of drops ────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 52),

                  // Logo + Language toggle row
                  Row(
                    children: [
                      _buildLogo(),
                      const Spacer(),
                      const LanguageToggleButton(),
                    ],
                  ),

                  const SizedBox(height: 36),

                  // Headline
                  FadeTransition(
                    opacity: _controller,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.appName,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppColors.primary,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.tagline,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  Text(
                    s.chooseRole,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 12,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Role cards
                  ...[UserRole.doctor, UserRole.bloodBank, UserRole.family]
                      .asMap()
                      .entries
                      .map(
                        (entry) => _RoleCard(
                          role: entry.value,
                          selected: _selected == entry.value,
                          delay: entry.key * 80,
                          controller: _controller,
                          onTap: () => _navigate(entry.value),
                        ),
                      ),

                  const Spacer(),

                  // Bottom tagline
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        'Powered by Google AI · Built for India',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        const Text(
          'RaktSetu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }
}

// ── Role card ─────────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final int delay;
  final AnimationController controller;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.delay,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = LocaleHelper.strings;

    final (icon, title, subtitle, color) = switch (role) {
      UserRole.doctor    => ('🏥', s.roleDoctor,    s.roleDoctorSub,    AppColors.primary),
      UserRole.bloodBank => ('🩸', s.roleBloodBank, s.roleBloodBankSub, AppColors.danger),
      UserRole.family    => ('👨‍👩‍👧', s.roleFamily,    s.roleFamilySub,    AppColors.success),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: controller,
              curve: Interval(delay / 800, 1.0, curve: Curves.easeOut),
            ),
            child: child,
          );
        },
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha:0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : AppColors.border,
                width: selected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 1),
                      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: selected ? color : AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Blood drop animation widget ───────────────────────────────────────────────
// Used ONLY on RoleSelectionScreen. Disposed the moment user navigates away.
class _BloodDropBackground extends StatefulWidget {
  const _BloodDropBackground();

  @override
  State<_BloodDropBackground> createState() => _BloodDropBackgroundState();
}

class _BloodDropBackgroundState extends State<_BloodDropBackground>
    with TickerProviderStateMixin {

  // (x fraction, size, duration seconds, delay seconds)
  static const _drops = [
    (0.08, 8.0,  3.8, 0.0),
    (0.22, 6.0,  4.6, 1.3),
    (0.38, 11.0, 5.1, 2.7),
    (0.55, 7.0,  4.2, 0.8),
    (0.70, 9.0,  3.4, 3.5),
    (0.84, 6.0,  5.8, 1.8),
    (0.95, 8.0,  4.0, 4.1),
  ];

  final List<AnimationController> _controllers = [];
  final List<Animation<double>>   _positions   = [];
  final List<Animation<double>>   _opacities   = [];

  @override
  void initState() {
    super.initState();
    for (final drop in _drops) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: (drop.$3 * 1000).toInt()),
      );

      _positions.add(
        Tween<double>(begin: -0.05, end: 1.1).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.linear),
        ),
      );

      _opacities.add(
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0,  end: 0.13), weight: 8),
          TweenSequenceItem(tween: Tween(begin: 0.13, end: 0.09), weight: 80),
          TweenSequenceItem(tween: Tween(begin: 0.09, end: 0.0),  weight: 12),
        ]).animate(ctrl),
      );

      _controllers.add(ctrl);

      Future.delayed(
        Duration(milliseconds: (drop.$4 * 1000).toInt()),
        () { if (mounted) ctrl.repeat(); },
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (var i = 0; i < _drops.length; i++)
              AnimatedBuilder(
                animation: _controllers[i],
                builder: (context, _) {
                  final drop    = _drops[i];
                  final x       = drop.$1 * constraints.maxWidth;
                  final size    = drop.$2;
                  final y       = _positions[i].value * constraints.maxHeight;
                  final opacity = _opacities[i].value;

                  return Positioned(
                    left: x,
                    top: y,
                    child: Opacity(
                      opacity: opacity,
                      child: _DropShape(size: size),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

// ── Drop shape ────────────────────────────────────────────────────────────────
class _DropShape extends StatelessWidget {
  final double size;
  const _DropShape({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.4),
      painter: _DropPainter(),
    );
  }
}

class _DropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..cubicTo(
        size.width * 1.1, size.height * 0.4,
        size.width * 1.1, size.height * 0.75,
        size.width / 2,   size.height,
      )
      ..cubicTo(
        -size.width * 0.1, size.height * 0.75,
        -size.width * 0.1, size.height * 0.4,
        size.width / 2,    0,
      )
      ..close();

    canvas.drawPath(path, paint);

    // Tiny highlight inside drop
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.18,
        size.width * 0.22,
        size.height * 0.28,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha:0.3)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_DropPainter oldDelegate) => false;
}