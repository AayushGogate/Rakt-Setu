import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/role_selection_screen.dart';
import 'l10n/strings.dart';
 
// Global locale notifier — used by all screens for Marathi toggle
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
 
  // Firebase init
  await Firebase.initializeApp();
 
  // Load saved locale
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('locale') ?? 'en';
  localeNotifier.value = Locale(savedLocale);
 
  runApp(const RaktSetuApp());
}
 
class RaktSetuApp extends StatelessWidget {
  const RaktSetuApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'RaktSetu',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          locale: locale,
          home: const RoleSelectionScreen(),
        );
      },
    );
  }
}
 
// ── Locale helper ─────────────────────────────────────────────────────────────
class LocaleHelper {
  static bool get isMarathi => localeNotifier.value.languageCode == 'mr';
 
  static AppStrings get strings => AppStrings(localeNotifier.value.languageCode);
 
  static Future<void> toggle() async {
    final newLocale = isMarathi ? const Locale('en') : const Locale('mr');
    localeNotifier.value = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', newLocale.languageCode);
  }
}
 
// ── Language toggle button — used in all AppBars ──────────────────────────────
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});
 
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final isMr = locale.languageCode == 'mr';
        return GestureDetector(
          onTap: LocaleHelper.toggle,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryFade,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              isMr ? 'ENG' : 'मर',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontFamily: 'Outfit',
              ),
            ),
          ),
        );
      },
    );
  }
}