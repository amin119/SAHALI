import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/step_bar.dart';
import '../../../shared/widgets/sa_button.dart';
import '../viewmodels/report_form_provider.dart';

class DescriptionScreen extends StatefulWidget {
  const DescriptionScreen({super.key});
  @override
  State<DescriptionScreen> createState() => _DescriptionScreenState();
}

class _DescriptionScreenState extends State<DescriptionScreen> {
  late final TextEditingController _ctrl;
  static const _max = 500;
  static const _min = 20;

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

  bool get _valid => _ctrl.text.trim().length >= _min;

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.newReport),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.reportLocation),
        ),
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.describeIssueSub,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _ctrl,
                  maxLength: _max,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.descriptionPlaceholder,
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint, height: 1.6),
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
                if (count > 0 && count < _min)
                  Text(
                    l10n.atLeastNChars(_min),
                    style: const TextStyle(fontSize: 12, color: AppColors.error),
                  ),
                const Spacer(),
                Text(
                  '$count / $_max',
                  style: TextStyle(
                    fontSize: 12,
                    color: count >= _max ? AppColors.error : AppColors.textHint,
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
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(tip, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            SaButton(
              label: l10n.nextReviewReport,
              onPressed: _valid ? _next : null,
            ),
          ],
        ),
      ),
    );
  }
}
