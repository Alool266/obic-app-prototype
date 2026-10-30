// Made by Dr Ali
// In-app SuperAdmin prices + eligibility rules (boss M02/M03/M15) — the
// same Draft → Review → Approved → Active → Retired workflow as Admin Web,
// with TOTP step-up when the server requires it.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import 'admin_boss_api.dart';
import 'admin_boss_strings.dart';

class AdminPricesScreen extends StatefulWidget {
  const AdminPricesScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AdminPricesScreen> createState() => _AdminPricesScreenState();
}

class _AdminPricesScreenState extends State<AdminPricesScreen> {
  final _api = AdminBossApi();
  List<Map<String, dynamic>> _prices = [];
  List<Map<String, dynamic>> _rules = [];
  bool _loading = true;
  String? _error;

  AdminBossStrings get s =>
      AdminBossStrings(Localizations.localeOf(context).languageCode);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String> _token() async {
    final token = await widget.authController.ensureAccessToken();
    if (token == null) throw Exception('session_expired');
    return token;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _token();
      final prices = await _api.prices(token);
      final rules = await _api.eligibilityRules(token);
      if (!mounted) return;
      setState(() {
        _prices = prices;
        _rules = rules;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<String?> _prompt(String title, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  List<String> _next(String status) {
    switch (status) {
      case 'Draft':
        return ['Review', 'Retired'];
      case 'Review':
        return ['Approved', 'Draft', 'Retired'];
      case 'Approved':
        return ['Active', 'Retired'];
      case 'Active':
        return ['Retired'];
      default:
        return [];
    }
  }

  Future<void> _transition({
    required bool isRule,
    required Map<String, dynamic> row,
    required String to,
  }) async {
    try {
      final token = await _token();
      String? effective;
      if (to == 'Active') {
        effective = await _prompt(
          s.effectivePrompt,
          initial: DateTime.now().toIso8601String().substring(0, 10),
        );
        if (effective == null || effective.isEmpty) return;
      }
      final totp = await _prompt(s.totpPrompt);
      if (!mounted) return;
      if (isRule) {
        await _api.transitionRule(
          token: token,
          id: row['id'] as String,
          status: to,
          effectiveFrom: effective,
          totpCode: totp,
        );
      } else {
        await _api.transitionPrice(
          token: token,
          id: row['id'] as String,
          status: to,
          effectiveFrom: effective,
          totpCode: totp,
        );
      }
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Widget _row({
    required String title,
    required String subtitle,
    required String status,
    required void Function(String to) onGo,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                Chip(label: Text(status)),
                for (final to in _next(status))
                  ActionChip(label: Text('→ $to'), onPressed: () => onGo(to)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(s.pricesTitle),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Text(s.pricesSub, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                if (_prices.isEmpty) Text(s.none),
                for (final row in _prices)
                  _row(
                    title: '${row['priceId']} · ${row['itemName']}',
                    subtitle:
                        '${row['city'] ?? '—'} · ¥${(((row['obicFeeCents'] as num?) ?? 0) / 100).toStringAsFixed(2)} · ${row['version']}',
                    status: row['status'] as String? ?? 'Draft',
                    onGo: (to) => _transition(isRule: false, row: row, to: to),
                  ),
                const SizedBox(height: 20),
                Text(
                  s.eligibilityTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_rules.isEmpty) Text(s.none),
                for (final row in _rules)
                  _row(
                    title:
                        '${row['city']} · ${row['activity']} → ${row['outcome']}',
                    subtitle: '${row['version']} · ${row['sourceRef'] ?? ''}',
                    status: row['status'] as String? ?? 'Draft',
                    onGo: (to) => _transition(isRule: true, row: row, to: to),
                  ),
              ],
            ),
    );
  }
}
