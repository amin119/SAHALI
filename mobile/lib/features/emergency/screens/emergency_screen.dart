import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class _Entry {
  const _Entry({
    required this.name,
    required this.desc,
    required this.number,
    required this.icon,
    required this.color,
  });
  final String name, desc, number;
  final IconData icon;
  final Color color;
}

class _Section {
  const _Section({required this.title, required this.color, required this.entries});
  final String title;
  final Color color;
  final List<_Entry> entries;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  List<_Section> _sections(AppLocalizations l, AppPalette p) => [
        _Section(
          title: l.emergencyCatSOS,
          color: p.urgent,
          entries: [
            _Entry(name: l.svcPolice,         desc: l.svcPoliceDesc,         number: '197',         icon: PhosphorIconsDuotone.policeCar,   color: p.urgent),
            _Entry(name: l.svcGardeNationale,  desc: l.svcGardeDesc,          number: '193',         icon: PhosphorIconsDuotone.shieldCheck, color: p.urgent),
            _Entry(name: l.svcSamu,            desc: l.svcSamuDesc,           number: '190',         icon: PhosphorIconsDuotone.ambulance,   color: const Color(0xFFE55300)),
            _Entry(name: l.svcPompiers,        desc: l.svcPompiersDesc,       number: '198',         icon: PhosphorIconsDuotone.fireTruck,   color: p.warning),
          ],
        ),
        _Section(
          title: l.emergencyCatMedical,
          color: p.info,
          entries: [
            _Entry(name: l.svcAntiPoison,  desc: l.svcAntiPoisonDesc,  number: '71 578 000', icon: PhosphorIconsDuotone.firstAidKit,   color: p.info),
          ],
        ),
        _Section(
          title: l.emergencyCatSocial,
          color: const Color(0xFF9333EA),
          entries: [
            _Entry(name: l.svcSosFemmes, desc: l.svcSosFemmesDesc, number: '1899', icon: PhosphorIconsDuotone.handHeart,       color: const Color(0xFF9333EA)),
            _Entry(name: l.svcEnfance,   desc: l.svcEnfanceDesc,   number: '116',  icon: PhosphorIconsDuotone.babyCarriage,    color: const Color(0xFFDB2777)),
          ],
        ),
        _Section(
          title: l.emergencyCatServices,
          color: p.info,
          entries: [
            _Entry(name: l.svcSteg,              desc: l.svcStegDesc,              number: '7000',       icon: PhosphorIconsDuotone.lightning,      color: p.catLighting),
            _Entry(name: l.svcSonede,            desc: l.svcSonedeDesc,            number: '1882',       icon: PhosphorIconsDuotone.drop,           color: p.catWater),
            _Entry(name: l.svcPoliceMunicipale,  desc: l.svcPoliceMunicipaleDesc,  number: '1819',       icon: PhosphorIconsDuotone.bank,           color: p.textSecondary),
          ],
        ),
      ];

  Future<void> _dial(BuildContext context, String number, AppLocalizations l) async {
    final clean = number.replaceAll(' ', '');
    final uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(number),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = AppPalette.of(context);
    final sections = _sections(l, p);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Plain centered header ────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(PhosphorIconsRegular.arrowLeft, color: p.textPrimary),
              onPressed: () => context.go(AppRoutes.home),
            ),
            title: Text(
              l.emergencyTitle,
              style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w800),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l.emergencySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textSecondary, fontSize: 13),
              ),
            ),
          ),

          // ── Unique emergency number hero ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: _UniqueNumberCard(
                l: l,
                onCall: () => _dial(context, '1721', l),
              ),
            ),
          ),

          // ── Sections ────────────────────────────────────────────────────
          ...sections.map((section) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _SectionBlock(
                    section: section,
                    l: l,
                    onCall: (number) => _dial(context, number, l),
                  ),
                ),
              )),

          // ── Bottom padding ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ),
        ],
      ),
    );
  }
}

// ─── Unique number hero card ──────────────────────────────────────────────────

class _UniqueNumberCard extends StatelessWidget {
  const _UniqueNumberCard({required this.l, required this.onCall});
  final AppLocalizations l;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onCall,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppShapes.card(
          gradient: LinearGradient(
            colors: [const Color(0xFFB91C1C), p.urgent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          radius: AppShapes.radiusLg,
          shadows: [
            BoxShadow(
              color: p.urgent.withValues(alpha: 0.30),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.svcNumeroUnique,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '1721',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.svcNumeroUniqueDesc,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: AppShapes.card(color: Colors.white.withValues(alpha: 0.22), radius: AppShapes.radiusPill),
              child: const Icon(PhosphorIconsFill.phone, color: Colors.white, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section block ────────────────────────────────────────────────────────────

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.section,
    required this.l,
    required this.onCall,
  });
  final _Section section;
  final AppLocalizations l;
  final void Function(String number) onCall;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: AppShapes.card(color: section.color.withValues(alpha: 0.12), radius: AppShapes.radiusPill),
          child: Text(
            section.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: section.color,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Entries
        ...section.entries.asMap().entries.map((it) => _EntryTile(
              entry: it.value,
              l: l,
              onCall: () => onCall(it.value.number),
              index: it.key,
            )),
      ],
    );
  }
}

// ─── Entry tile ───────────────────────────────────────────────────────────────

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.l,
    required this.onCall,
    this.index = 0,
  });
  final _Entry entry;
  final AppLocalizations l;
  final VoidCallback onCall;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusMd, borderColor: p.divider),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: AppShapes.card(color: entry.color.withValues(alpha: 0.10), radius: AppShapes.radiusPill),
            child: Icon(entry.icon, color: entry.color, size: 20),
          ),
          const SizedBox(width: 14),
          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  entry.desc,
                  style: TextStyle(
                      fontSize: 11, color: p.textHint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Number + call button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.number,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: entry.color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onCall,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: AppShapes.card(color: entry.color.withValues(alpha: 0.10), radius: AppShapes.radiusPill),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsFill.phone, color: entry.color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        l.callBtn,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: entry.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms, delay: (30 * index).ms).slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
  }
}
