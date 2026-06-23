import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

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

  List<_Section> _sections(AppLocalizations l) => [
        _Section(
          title: l.emergencyCatSOS,
          color: AppColors.error,
          entries: [
            _Entry(name: l.svcPolice,         desc: l.svcPoliceDesc,         number: '197',         icon: Icons.local_police_rounded,       color: AppColors.error),
            _Entry(name: l.svcGardeNationale,  desc: l.svcGardeDesc,          number: '193',         icon: Icons.security_rounded,            color: AppColors.error),
            _Entry(name: l.svcSamu,            desc: l.svcSamuDesc,           number: '190',         icon: Icons.emergency_rounded,           color: const Color(0xFFE55300)),
            _Entry(name: l.svcPompiers,        desc: l.svcPompiersDesc,       number: '198',         icon: Icons.local_fire_department_rounded, color: AppColors.warning),
          ],
        ),
        _Section(
          title: l.emergencyCatMedical,
          color: AppColors.statusInProgress,
          entries: [
            _Entry(name: l.svcAntiPoison,  desc: l.svcAntiPoisonDesc,  number: '71 578 000', icon: Icons.coronavirus_outlined,   color: AppColors.statusInProgress),
          ],
        ),
        _Section(
          title: l.emergencyCatSocial,
          color: const Color(0xFF9333EA),
          entries: [
            _Entry(name: l.svcSosFemmes, desc: l.svcSosFemmesDesc, number: '1899', icon: Icons.support_agent_rounded,         color: const Color(0xFF9333EA)),
            _Entry(name: l.svcEnfance,   desc: l.svcEnfanceDesc,   number: '116',  icon: Icons.child_care_rounded,            color: const Color(0xFFDB2777)),
          ],
        ),
        _Section(
          title: l.emergencyCatServices,
          color: AppColors.statusReceived,
          entries: [
            _Entry(name: l.svcSteg,              desc: l.svcStegDesc,              number: '7000',       icon: Icons.bolt_rounded,              color: AppColors.catLighting),
            _Entry(name: l.svcSonede,            desc: l.svcSonedeDesc,            number: '1882',       icon: Icons.water_drop_rounded,        color: AppColors.catWater),
            _Entry(name: l.svcPoliceMunicipale,  desc: l.svcPoliceMunicipaleDesc,  number: '1819',       icon: Icons.account_balance_rounded,   color: AppColors.textSecondary),
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
    final sections = _sections(l);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Collapsible hero header ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.go(AppRoutes.home),
            ),
            backgroundColor: AppColors.error,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB91C1C), AppColors.error],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.emergency_rounded,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.emergencyTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    l.emergencySubtitle,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.80),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              l.emergencyTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
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
    return GestureDetector(
      onTap: onCall,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB91C1C), AppColors.error],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.30),
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
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_rounded, color: Colors.white, size: 26),
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
          decoration: BoxDecoration(
            color: section.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
          ),
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
        ...section.entries.map((e) => _EntryTile(
              entry: e,
              l: l,
              onCall: () => onCall(e.number),
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
  });
  final _Entry entry;
  final AppLocalizations l;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  entry.desc,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
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
                  decoration: BoxDecoration(
                    color: entry.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.call_rounded, color: entry.color, size: 12),
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
    );
  }
}
