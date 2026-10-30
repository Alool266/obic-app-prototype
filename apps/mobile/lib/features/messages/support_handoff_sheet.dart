// Made by Dr Ali
// Support handoff form — branch + desk/service before request-staff.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/obic_branches.dart';
import '../../core/obic_org.dart';
import '../../core/region_controller.dart';
import '../../theme/obic_colors.dart';

/// Result of the customer handoff form (support threads).
class SupportHandoffResult {
  const SupportHandoffResult({
    required this.branch,
    required this.serviceKey,
    this.orderRef,
    this.note,
  });

  final String branch;
  final String serviceKey;
  final String? orderRef;
  final String? note;
}

/// Form1 mega / Form2 service keys shown in the handoff picker.
class SupportHandoffServiceOption {
  const SupportHandoffServiceOption({
    required this.key,
    required this.labelEn,
    required this.labelAr,
    required this.labelZh,
  });

  final String key;
  final String labelEn;
  final String labelAr;
  final String labelZh;

  String label(String lang) {
    if (lang.startsWith('ar')) return labelAr;
    if (lang.startsWith('zh')) return labelZh;
    return labelEn;
  }
}

/// Aligns with order-routing SERVICE_DESK / Form2 mega catalog.
const kSupportHandoffServices = <SupportHandoffServiceOption>[
  SupportHandoffServiceOption(
    key: 'government',
    labelEn: 'Visas & government docs',
    labelAr: 'تأشيرات ومستندات حكومية',
    labelZh: '签证与政务文件',
  ),
  SupportHandoffServiceOption(
    key: 'business',
    labelEn: 'Business & company',
    labelAr: 'أعمال وتأسيس شركات',
    labelZh: '商务与公司',
  ),
  SupportHandoffServiceOption(
    key: 'travel',
    labelEn: 'Travel · hotels · flights',
    labelAr: 'سفر · فنادق · طيران',
    labelZh: '旅行 · 酒店 · 机票',
  ),
  SupportHandoffServiceOption(
    key: 'education',
    labelEn: 'Education & scholarships',
    labelAr: 'تعليم ومنح',
    labelZh: '教育与奖学金',
  ),
  SupportHandoffServiceOption(
    key: 'logistics',
    labelEn: 'Shipping & logistics',
    labelAr: 'شحن ولوجستيات',
    labelZh: '物流与货运',
  ),
  SupportHandoffServiceOption(
    key: 'property',
    labelEn: 'Property',
    labelAr: 'عقارات',
    labelZh: '房产',
  ),
  SupportHandoffServiceOption(
    key: 'shopping',
    labelEn: 'Shopping / purchasing',
    labelAr: 'تسوق / مشتريات',
    labelZh: '采购 / 购物',
  ),
  SupportHandoffServiceOption(
    key: 'healthcare',
    labelEn: 'Healthcare',
    labelAr: 'رعاية صحية',
    labelZh: '医疗健康',
  ),
  SupportHandoffServiceOption(
    key: 'consultations',
    labelEn: 'General support',
    labelAr: 'دعم عام',
    labelZh: '一般咨询',
  ),
];

/// Shows branch + service handoff sheet. Returns null if cancelled.
Future<SupportHandoffResult?> showSupportHandoffSheet(
  BuildContext context, {
  String? initialOrderRef,
  String? initialServiceKey,
  String? initialBranch,
}) {
  return showModalBottomSheet<SupportHandoffResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: ObicColors.surfaceOf(context),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _SupportHandoffForm(
        initialOrderRef: initialOrderRef,
        initialServiceKey: initialServiceKey,
        initialBranch: initialBranch,
      ),
    ),
  );
}

class _SupportHandoffForm extends StatefulWidget {
  const _SupportHandoffForm({
    this.initialOrderRef,
    this.initialServiceKey,
    this.initialBranch,
  });

  final String? initialOrderRef;
  final String? initialServiceKey;
  final String? initialBranch;

  @override
  State<_SupportHandoffForm> createState() => _SupportHandoffFormState();
}

class _SupportHandoffFormState extends State<_SupportHandoffForm> {
  late String _branch;
  late String _serviceKey;
  late final TextEditingController _refCtrl;
  late final TextEditingController _noteCtrl;
  List<ObicBranch> _branches = List<ObicBranch>.from(kObicBranchRecords);
  double? _userLat;
  double? _userLng;
  bool _hasLocation = false;

  @override
  void initState() {
    super.initState();
    _branch = widget.initialBranch?.trim().isNotEmpty == true
        ? widget.initialBranch!.trim()
        : kObicBranches.first;
    final sk = widget.initialServiceKey?.trim();
    if (sk != null && kSupportHandoffServices.any((s) => s.key == sk)) {
      _serviceKey = sk;
    } else if (sk == 'visa' || sk == 'visas') {
      _serviceKey = 'government';
    } else {
      _serviceKey = 'consultations';
    }
    _refCtrl = TextEditingController(text: widget.initialOrderRef ?? '');
    _noteCtrl = TextEditingController();
    unawaited(_loadNearestBranch());
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNearestBranch() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(kRegionLatKey);
    final lng = prefs.getDouble(kRegionLngKey);
    final country = prefs.getString(kRegionCountryKey);
    final sorted = branchesSortedByDistance(lat, lng, countryCode: country);
    if (!mounted) return;
    final hasLoc = lat != null && lng != null;
    setState(() {
      _userLat = lat;
      _userLng = lng;
      _branches = sorted;
      _hasLocation = hasLoc;
      // Only auto-pick nearest when caller did not pre-set a branch.
      if ((widget.initialBranch == null ||
              widget.initialBranch!.trim().isEmpty) &&
          hasLoc &&
          sorted.isNotEmpty) {
        _branch = sorted.first.name;
      }
    });
  }

  void _useNearest() {
    if (_branches.isEmpty) return;
    setState(() => _branch = _branches.first.name);
  }

  void _submit() {
    final ref = _refCtrl.text.trim();
    final note = _noteCtrl.text.trim();
    Navigator.of(context).pop(
      SupportHandoffResult(
        branch: _branch,
        serviceKey: _serviceKey,
        orderRef: ref.isEmpty ? null : ref,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.chatHandoffTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ObicColors.titleOf(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.chatHandoffHint,
              style: TextStyle(
                fontSize: 13,
                color: ObicColors.titleOf(context).withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.chatHandoffBranch,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ObicColors.titleOf(context),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: ValueKey('handoff-branch-$_branch-$_hasLocation'),
              initialValue: _branches.any((b) => b.name == _branch)
                  ? _branch
                  : (_branches.isNotEmpty
                      ? _branches.first.name
                      : kObicBranches.first),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _branches
                  .map(
                    (b) => DropdownMenuItem(
                      value: b.name,
                      child: Text(
                        _hasLocation
                            ? b.distanceLabel(
                                _userLat,
                                _userLng,
                                langCode: lang,
                              )
                            : branchDisplayName(b.name, lang),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _branch = v);
              },
            ),
            if (_hasLocation) ...[
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _useNearest,
                  icon: const Icon(Icons.near_me_outlined, size: 16),
                  label: Text(l10n.chatHandoffUseNearest),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              l10n.chatHandoffService,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ObicColors.titleOf(context),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _serviceKey,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: kSupportHandoffServices
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.key,
                      child: Text(s.label(lang)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _serviceKey = v);
              },
            ),
            const SizedBox(height: 14),
            Text(
              l10n.chatHandoffOrderRef,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ObicColors.titleOf(context),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _refCtrl,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: l10n.chatHandoffOrderRefHint,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.chatHandoffNote,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ObicColors.titleOf(context),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              maxLength: 500,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: l10n.chatHandoffNoteHint,
                counterText: '',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: ObicColors.navy,
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(l10n.chatHandoffSubmit),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.chatHandoffCancel),
            ),
          ],
        ),
      ),
    );
  }
}
