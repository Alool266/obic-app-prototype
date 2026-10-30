// Made by Dr Ali
// An employee opens their own payslip and confirms they have seen it.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class PayslipsScreen extends StatefulWidget {
  const PayslipsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<PayslipsScreen> createState() => _PayslipsScreenState();
}

class _PayslipsScreenState extends State<PayslipsScreen> {
  final _api = SocialApi();
  List<Map<String, dynamic>> _rows = [];
  String? _openId;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final home = await _api.payslipsHome(token);
      if (!mounted) return;
      setState(() {
        _rows = _maps(home['rows']);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'failed';
      });
    }
  }

  List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  String _money(Object? cents) {
    final value = cents is int ? cents : int.tryParse('$cents') ?? 0;
    final sign = value < 0 ? '-' : '';
    final abs = value.abs();
    final whole = abs ~/ 100;
    final frac = (abs % 100).toString().padLeft(2, '0');
    return '$sign$whole.$frac';
  }

  Future<void> _acknowledge(String id) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) return;
      await _api.acknowledgePayslip(accessToken: token, payslipId: id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.payslipsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.payslipsHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.payslipsLoadFailed),
                  ),
                if (_rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l10n.payslipsNone),
                  ),
                for (final row in _rows) _card(l10n, row),
              ],
            ),
    );
  }

  Widget _card(AppLocalizations l10n, Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';
    final open = _openId == id;
    final lines = _maps(row['lines']);
    final seen = row['acknowledgedAt'] != null;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${row['period']} · CNY ${_money(row['netCents'])}'),
              subtitle: Text(seen ? l10n.payslipsConfirmed : l10n.payslipsOpen),
              onTap: () => setState(() => _openId = open ? null : id),
            ),
            if (open) ...[
              for (final line in lines)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(line['label']?.toString() ?? ''),
                  subtitle: Text(
                    line['kind'] == 'deduction' ? l10n.payslipsDeduction : l10n.payslipsEarning,
                  ),
                  trailing: Text(_money(line['cents'])),
                ),
              if ((row['note']?.toString() ?? '').isNotEmpty)
                Text('${l10n.payslipsNote}: ${row['note']}'),
              if (!seen)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton(
                    onPressed: _sending ? null : () => _acknowledge(id),
                    child: Text(l10n.payslipsSeen),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
