import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';

const _supportEmail = 'support@sahali.tn';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});
  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  int? _expandedFaq;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(AppLocalizations l10n) async {
    if (_messageCtrl.text.trim().isEmpty) return;
    final subject = Uri.encodeComponent('[Sahali] Support — ${_nameCtrl.text.trim()}');
    final body = Uri.encodeComponent(
      'Nom: ${_nameCtrl.text.trim()}\nEmail: ${_emailCtrl.text.trim()}\n\n${_messageCtrl.text.trim()}',
    );
    final uri = Uri.parse('mailto:$_supportEmail?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_supportEmail)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    final faqs = [
      (l10n.faq1Q, l10n.faq1A),
      (l10n.faq2Q, l10n.faq2A),
      (l10n.faq3Q, l10n.faq3A),
      (l10n.faq4Q, l10n.faq4A),
      (l10n.faq5Q, l10n.faq5A),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.helpSupport),
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.faqSectionTitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary)),
          const SizedBox(height: 12),
          Container(
            decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusLg, borderColor: p.divider),
            child: Column(
              children: List.generate(faqs.length, (i) {
                final (q, a) = faqs[i];
                final expanded = _expandedFaq == i;
                return Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _expandedFaq = expanded ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(q, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary)),
                            ),
                            AnimatedRotation(
                              turns: expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(PhosphorIconsRegular.caretDown, size: 18, color: p.textHint),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      firstChild: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(a, style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.5)),
                      ),
                      secondChild: const SizedBox(width: double.infinity),
                    ),
                    if (i != faqs.length - 1) Divider(height: 1, color: p.divider),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 28),
          Text(l10n.contactSupportTitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary)),
          const SizedBox(height: 4),
          Text(l10n.contactSupportSub, style: TextStyle(fontSize: 13, color: p.textSecondary)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusLg, borderColor: p.divider),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: l10n.yourName, prefixIcon: Icon(PhosphorIconsRegular.user)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.yourEmail, prefixIcon: Icon(PhosphorIconsRegular.envelopeSimple)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _messageCtrl,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(labelText: l10n.yourMessage, alignLabelWithHint: true),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _send(l10n),
                    child: Text(l10n.sendMessage),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
