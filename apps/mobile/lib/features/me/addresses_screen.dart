// Made by Dr Ali
// Saved delivery addresses — add, edit, delete, set default.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import '../auth/require_auth.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _api = AuthApi();
  bool _saving = false;

  List<ObicAddress> get _addresses =>
      widget.authController.user?.addresses ?? const [];

  Future<void> _save(List<ObicAddress> next) async {
    final token = await widget.authController.accessToken();
    if (token == null) return;
    setState(() => _saving = true);
    try {
      final user = await _api.updateAddresses(
        accessToken: token,
        addresses: next,
      );
      await widget.authController.applyUser(user);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openEditor({ObicAddress? existing}) async {
    final result = await showModalBottomSheet<ObicAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ObicColors.scaffoldOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddressEditorSheet(existing: existing),
    );
    if (result == null || !mounted) return;

    final list = List<ObicAddress>.from(_addresses);
    final idx = list.indexWhere((a) => a.id == result.id);
    if (idx >= 0) {
      list[idx] = result;
    } else {
      if (result.isDefault) {
        for (var i = 0; i < list.length; i++) {
          list[i] = list[i].copyWith(isDefault: false);
        }
      }
      list.add(result);
    }
    await _save(list);
  }

  Future<void> _setDefault(ObicAddress address) async {
    final list = _addresses
        .map((a) => a.copyWith(isDefault: a.id == address.id))
        .toList();
    await _save(list);
  }

  Future<void> _delete(ObicAddress address) async {
    final l10n = AppLocalizations.of(context);
    final ar = Directionality.of(context) == TextDirection.rtl;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addressesDeleteTitle),
        content: Text(l10n.addressesDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.addressesDeleteConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    var list = _addresses.where((a) => a.id != address.id).toList();
    if (list.isNotEmpty && !list.any((a) => a.isDefault)) {
      list = [list.first.copyWith(isDefault: true), ...list.skip(1)];
    }
    await _save(list);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final addresses = _addresses;

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(l10n.addressesTitle),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _openEditor(),
        backgroundColor: ObicColors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(l10n.addressesAdd),
      ),
      body: addresses.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 56,
                      color: ObicColors.mutedOf(context).withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.addressesEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ObicColors.mutedOf(context),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemCount: addresses.length,
              itemBuilder: (context, i) {
                final a = addresses[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: ObicColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _saving ? null : () => _openEditor(existing: a),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: a.isDefault
                                ? ObicColors.blue.withValues(alpha: 0.45)
                                : ObicColors.lineOf(context).withValues(alpha: 0.85),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: ObicColors.blueSoftOf(context),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _iconForLabel(a.label),
                                  color: ObicColors.blueDeep,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            a.label,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: ObicColors.titleOf(context),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (a.isDefault)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: ObicColors.blueSoftOf(context),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              l10n.addressesDefaultBadge,
                                              style: const TextStyle(
                                                color: ObicColors.blueDeep,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      a.formatted(),
                                      style: TextStyle(
                                        color: ObicColors.inkOf(context),
                                        height: 1.35,
                                      ),
                                    ),
                                    if (a.notes != null &&
                                        a.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        a.notes!,
                                        style: TextStyle(
                                          color: ObicColors.mutedOf(context),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        if (!a.isDefault)
                                          TextButton(
                                            onPressed: _saving
                                                ? null
                                                : () => _setDefault(a),
                                            child: Text(l10n.addressesSetDefault),
                                          ),
                                        TextButton(
                                          onPressed: _saving
                                              ? null
                                              : () => _delete(a),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red.shade700,
                                          ),
                                          child: Text(l10n.addressesDeleteConfirm),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _saving
                                    ? null
                                    : () => _openEditor(existing: a),
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                color: ObicColors.mutedOf(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _iconForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('home') || lower.contains('منزل') || lower.contains('家')) {
      return Icons.home_outlined;
    }
    if (lower.contains('work') || lower.contains('office') || lower.contains('عمل')) {
      return Icons.work_outline_rounded;
    }
    if (lower.contains('hotel') || lower.contains('فندق')) {
      return Icons.hotel_outlined;
    }
    return Icons.place_outlined;
  }
}

class _AddressEditorSheet extends StatefulWidget {
  const _AddressEditorSheet({this.existing});

  final ObicAddress? existing;

  @override
  State<_AddressEditorSheet> createState() => _AddressEditorSheetState();
}

class _AddressEditorSheetState extends State<_AddressEditorSheet> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _line1Ctrl;
  late final TextEditingController _line2Ctrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _notesCtrl;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelCtrl = TextEditingController(text: e?.label ?? '');
    _line1Ctrl = TextEditingController(text: e?.line1 ?? '');
    _line2Ctrl = TextEditingController(text: e?.line2 ?? '');
    _cityCtrl = TextEditingController(text: e?.city ?? '');
    _districtCtrl = TextEditingController(text: e?.district ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _isDefault = e?.isDefault ?? widget.existing == null;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _line1Ctrl.dispose();
    _line2Ctrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final label = _labelCtrl.text.trim();
    final line1 = _line1Ctrl.text.trim();
    final city = _cityCtrl.text.trim();
    if (label.isEmpty || line1.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addressesRequiredFields)),
      );
      return;
    }

    final id = widget.existing?.id ??
        'addr_${DateTime.now().microsecondsSinceEpoch}';
    Navigator.pop(
      context,
      ObicAddress(
        id: id,
        label: label,
        line1: line1,
        line2: _line2Ctrl.text.trim(),
        city: city,
        district: _districtCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        isDefault: _isDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ObicColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existing == null ? l10n.addressesAdd : l10n.addressesEdit,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ObicColors.titleOf(context),
              ),
            ),
            const SizedBox(height: 16),
            _Field(label: l10n.addressesLabel, controller: _labelCtrl),
            const SizedBox(height: 10),
            _Field(label: l10n.addressesLine1, controller: _line1Ctrl),
            const SizedBox(height: 10),
            _Field(
              label: l10n.addressesLine2,
              controller: _line2Ctrl,
              optional: true,
            ),
            const SizedBox(height: 10),
            _Field(label: l10n.addressesCity, controller: _cityCtrl),
            const SizedBox(height: 10),
            _Field(
              label: l10n.addressesDistrict,
              controller: _districtCtrl,
              optional: true,
            ),
            const SizedBox(height: 10),
            _Field(
              label: l10n.addressesNotes,
              controller: _notesCtrl,
              optional: true,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              title: Text(l10n.addressesSetDefault),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: ObicColors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.addressesSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.optional = false,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final bool optional;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final optionalSuffix =
        optional ? ' (${AppLocalizations.of(context).addressesOptional})' : '';
    return TextField(
      controller: controller,
      maxLines: maxLines,
      cursorColor: ObicColors.blue,
      style: TextStyle(color: ObicColors.inkOf(context), fontSize: 16),
      decoration: InputDecoration(
        labelText: '$label$optionalSuffix',
        labelStyle: TextStyle(color: ObicColors.mutedOf(context)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: ObicColors.surfaceRaisedOf(context),
      ),
    );
  }
}

/// Pick a saved address (food delivery / orders). Returns null if dismissed.
Future<ObicAddress?> pickSavedAddress(
  BuildContext context, {
  required AuthController authController,
}) async {
  final ok = await requireAuth(context, authController);
  if (!context.mounted || !ok) return null;

  final addresses = authController.user?.addresses ?? const [];
  if (addresses.isEmpty) {
    final l10n = AppLocalizations.of(context);
    final add = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addressesTitle),
        content: Text(l10n.addressesEmpty),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(Directionality.of(context) == TextDirection.rtl
                ? 'إلغاء'
                : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.addressesAdd),
          ),
        ],
      ),
    );
    if (add == true && context.mounted) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => AddressesScreen(authController: authController),
        ),
      );
    }
    return authController.user?.defaultAddress;
  }

  return showModalBottomSheet<ObicAddress>(
    context: context,
    backgroundColor: ObicColors.scaffoldOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final l10n = AppLocalizations.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.addressesPickTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ObicColors.titleOf(context),
                ),
              ),
              const SizedBox(height: 12),
              ...addresses.map((a) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: ObicColors.line),
                    ),
                    tileColor: ObicColors.card,
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: a.isDefault ? ObicColors.blue : ObicColors.muted,
                    ),
                    title: Text(
                      a.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      a.formatted(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: a.isDefault
                        ? Text(
                            l10n.addressesDefaultBadge,
                            style: const TextStyle(
                              color: ObicColors.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                    onTap: () => Navigator.pop(ctx, a),
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) =>
                          AddressesScreen(authController: authController),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addressesAdd),
              ),
            ],
          ),
        ),
      );
    },
  );
}
