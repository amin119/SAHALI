import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_palette.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    final sections = [
      (l10n.privacy1Title, l10n.privacy1Body),
      (l10n.privacy2Title, l10n.privacy2Body),
      (l10n.privacy3Title, l10n.privacy3Body),
      (l10n.privacy4Title, l10n.privacy4Body),
      (l10n.privacy5Title, l10n.privacy5Body),
      (l10n.privacy6Title, l10n.privacy6Body),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.privacyPolicy),
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.privacyIntro,
            style: TextStyle(fontSize: 14, color: p.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 24),
          for (final (title, body) in sections) ...[
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary)),
            const SizedBox(height: 6),
            Text(body, style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.6)),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
