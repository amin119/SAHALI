import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'fr';

  static const _languages = [
    {'code': 'fr', 'label': 'Français', 'sub': 'Continuer en français', 'flag': '🇫🇷'},
    {'code': 'ar', 'label': 'العربية', 'sub': 'تابع باللغة العربية', 'flag': '🇹🇳'},
    {'code': 'en', 'label': 'English', 'sub': 'Continue in English', 'flag': '🇬🇧'},
  ];

  @override
  void initState() {
    super.initState();
    _selected = context.read<LanguageProvider>().languageCode;
  }

  void _confirm() {
    context.read<LanguageProvider>().setLocale(_selected);
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 56,
                height: 56,
                decoration: AppShapes.card(color: Colors.white.withValues(alpha: 0.55), radius: AppShapes.radiusMd),
                child: Icon(PhosphorIconsDuotone.translate,
                    color: p.ink, size: 28),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.chooseLanguage,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.languageHint,
                style: TextStyle(fontSize: 14, color: p.textSecondary),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Column(
                  children: _languages.asMap().entries.map((entry) {
                    final i = entry.key;
                    final lang = entry.value;
                    final isSelected = _selected == lang['code'];
                    return GestureDetector(
                      onTap: () => setState(() => _selected = lang['code']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
                        decoration: AppShapes.card(
                          color: isSelected ? p.infoSoft : p.surface,
                          radius: AppShapes.radiusLg,
                          borderColor: isSelected ? p.info : p.divider,
                          borderWidth: isSelected ? 2 : 1,
                        ),
                        child: Row(
                          children: [
                            Text(lang['flag']!,
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang['label']!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? p.info : p.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lang['sub']!,
                                    style: TextStyle(fontSize: 13, color: p.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(PhosphorIconsFill.checkCircle,
                                  color: p.info, size: 22),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 280.ms, delay: (60 * i).ms).slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
                  }).toList(),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _confirm,
                  child: Text(l10n.continueBtn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
