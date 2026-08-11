import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/router/app_router.dart';
import '../../../core/tour/app_tour.dart';
import '../../../shared/widgets/step_bar.dart';
import '../../../shared/widgets/sa_button.dart';
import '../../../shared/widgets/tour_button.dart';
import '../viewmodels/report_form_provider.dart';

class DescriptionScreen extends StatefulWidget {
  const DescriptionScreen({super.key});
  @override
  State<DescriptionScreen> createState() => _DescriptionScreenState();
}

class _DescriptionScreenState extends State<DescriptionScreen> {
  late final TextEditingController _ctrl;
  static const _max = 500;
  final _fieldKey = GlobalKey();
  final _nextBtnKey = GlobalKey();

  void _showTour(AppLocalizations l10n) {
    showScreenTour(context, [
      TourStep(
        targetKey: _fieldKey,
        title: l10n.tourDescriptionFieldTitle,
        description: l10n.tourDescriptionFieldDesc,
        align: ContentAlign.bottom,
      ),
      TourStep(
        targetKey: _nextBtnKey,
        title: l10n.tourDescriptionNextTitle,
        description: l10n.tourDescriptionNextDesc,
        align: ContentAlign.top,
      ),
    ], doneLabel: l10n.tourDone);
  }

  @override
  void initState() {
    super.initState();
    final saved = context.read<ReportFormProvider>().description;
    _ctrl = TextEditingController(text: saved);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _valid => _ctrl.text.trim().isNotEmpty;

  void _appendTip(String tip) {
    final current = _ctrl.text;
    _ctrl.text = current.isEmpty ? tip : '$current $tip';
    setState(() {});
  }

  void _next() {
    context.read<ReportFormProvider>().setDescription(_ctrl.text.trim());
    context.go(AppRoutes.reportReview);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count = _ctrl.text.length;
    final tips = [
      l10n.tipRoadDamage,
      l10n.tipFlooding,
      l10n.tipBrokenLamp,
      l10n.tipTrashOverflow,
      l10n.tipNoise,
    ];
    final p = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.newReport),
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.go(AppRoutes.reportLocation),
        ),
        actions: [TourButton(onPressed: () => _showTour(l10n))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: StepBar(step: 4, total: 6),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.describeIssue,
              style: Theme.of(context).textTheme.headlineLarge,
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 4),
            Text(
              l10n.describeIssueSub,
              style: TextStyle(fontSize: 14, color: p.textSecondary),
            ).animate().fadeIn(duration: 300.ms, delay: 60.ms),
            const SizedBox(height: 24),

            Expanded(
              child: Container(
                key: _fieldKey,
                decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusLg, borderColor: p.border),
                child: TextField(
                  controller: _ctrl,
                  maxLength: _max,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.descriptionPlaceholder,
                    hintStyle: TextStyle(fontSize: 14, color: p.textHint, height: 1.6),
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Spacer(),
                Text(
                  '$count / $_max',
                  style: TextStyle(
                    fontSize: 12,
                    color: count >= _max ? p.error : p.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tips
                  .map((tip) => GestureDetector(
                        onTap: () => _appendTip(tip),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: AppShapes.card(color: p.surface, radius: AppShapes.radiusPill, borderColor: p.divider),
                          child: Text(tip, style: TextStyle(fontSize: 12, color: p.textSecondary)),
                        ),
                      ))
                  .toList(),
            ).animate().fadeIn(duration: 300.ms, delay: 120.ms),
            const SizedBox(height: 20),
            SaButton(
              key: _nextBtnKey,
              label: l10n.nextReviewReport,
              onPressed: _valid ? _next : null,
            ),
          ],
        ),
      ),
    );
  }
}
