// Made by Dr Ali
// Company Registration entry (boss W1, Non-VIP): eligibility check first,
// then start the application. Customers only ever see approved outcomes —
// anything unapproved honestly says "to be verified".

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import 'registration_api.dart';
import 'registration_detail_page.dart';
import 'registration_strings.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({
    super.key,
    required this.authController,
    required this.langCode,
  });

  final AuthController authController;
  final String langCode;

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _api = RegistrationApi();
  RegistrationStrings get s => RegistrationStrings(widget.langCode);

  String _city = kRegistrationCities.first;
  final _activity = TextEditingController();
  final _nationality = TextEditingController();
  final _qualification = TextEditingController();
  bool _insideChina = false;
  String? _tier;
  bool _workResidence = false;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _eligibility;
  List<RegistrationApplication> _mine = [];

  @override
  void initState() {
    super.initState();
    _loadMine();
  }

  @override
  void dispose() {
    _activity.dispose();
    _nationality.dispose();
    _qualification.dispose();
    super.dispose();
  }

  Future<String> _token() async {
    final token = await widget.authController.accessToken();
    if (token == null) throw Exception('Login required');
    return token;
  }

  Future<void> _loadMine() async {
    try {
      final token = await _token();
      final rows = await _api.myApplications(token);
      if (mounted) setState(() => _mine = rows);
    } catch (_) {
      // List is best-effort; the form below stays usable.
    }
  }

  Future<void> _run(Future<void> Function(String token) fn) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await _token();
      await fn(token);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    await _run((token) async {
      final result = await _api.checkEligibility(
        accessToken: token,
        city: _city,
        activity: _activity.text.trim(),
        nationality: _nationality.text.trim(),
        insideChina: _insideChina,
      );
      if (mounted) setState(() => _eligibility = result);
    });
  }

  Future<void> _start() async {
    if (_tier == null) {
      setState(() => _error = s.chooseTierFirst);
      return;
    }
    await _run((token) async {
      final app = await _api.createApplication(
        accessToken: token,
        city: _city,
        activity: _activity.text.trim(),
        nationality: _nationality.text.trim(),
        insideChina: _insideChina,
        qualification: _qualification.text.trim(),
        accountantTier: _tier,
        includeWorkResidence: _workResidence,
      );
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => RegistrationDetailPage(
            authController: widget.authController,
            langCode: widget.langCode,
            applicationId: app.id,
          ),
        ),
      );
      _loadMine();
    });
  }

  Widget _eligibilityCard() {
    final e = _eligibility!;
    final outcome = e['outcome'] as String? ?? 'to_be_verified';
    final label = outcome == 'eligible'
        ? s.eligible
        : outcome == 'ineligible'
        ? s.ineligible
        : s.toBeVerified;
    final color = outcome == 'eligible'
        ? Colors.green
        : outcome == 'ineligible'
        ? Colors.red
        : Colors.orange;
    final alternatives = e['alternatives'];
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(label),
              backgroundColor: color.withValues(alpha: 0.15),
              side: BorderSide(color: color),
            ),
            if (e['reason'] is String) ...[
              const SizedBox(height: 8),
              Text(e['reason'] as String),
            ],
            if (alternatives is List && alternatives.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                s.alternatives,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final alt in alternatives)
                if (alt is Map<String, dynamic>) Text('• ${alt['city']}'),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(title: Text(s.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.startNew, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _city,
            decoration: InputDecoration(labelText: s.city),
            items: [
              for (final city in kRegistrationCities)
                DropdownMenuItem(value: city, child: Text(city)),
            ],
            onChanged: (v) => setState(() {
              _city = v ?? _city;
              _eligibility = null;
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _activity,
            decoration: InputDecoration(
              labelText: s.activity,
              hintText: s.activityHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nationality,
            decoration: InputDecoration(labelText: s.nationality),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qualification,
            decoration: InputDecoration(labelText: s.qualification),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.insideChina),
            value: _insideChina,
            onChanged: (v) => setState(() => _insideChina = v),
          ),
          const SizedBox(height: 8),
          Text(
            s.accountantTier,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(s.tierHint, style: Theme.of(context).textTheme.bodySmall),
          RadioGroup<String>(
            groupValue: _tier,
            onChanged: (v) => setState(() => _tier = v),
            child: Column(
              children: [
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.tierNone),
                  value: 'no_tax',
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.tierLt20),
                  value: 'tax_lt20',
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.tier2050),
                  value: 'tax_20_50',
                ),
              ],
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.workResidence),
            value: _workResidence,
            onChanged: (v) => setState(() => _workResidence = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy || _activity.text.trim().isEmpty
                      ? null
                      : _check,
                  child: Text(s.checkEligibility),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ObicColors.blue,
                  ),
                  onPressed: _busy ? null : _start,
                  child: Text(s.startApplication),
                ),
              ),
            ],
          ),
          if (_eligibility != null) _eligibilityCard(),
          const SizedBox(height: 24),
          Text(
            s.myApplications,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_mine.isEmpty) Text(s.noApplications),
          for (final app in _mine)
            Card(
              child: ListTile(
                title: Text('${app.trackingId} · ${app.city}'),
                subtitle: Text('${app.activity} — ${app.status}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => RegistrationDetailPage(
                        authController: widget.authController,
                        langCode: widget.langCode,
                        applicationId: app.id,
                      ),
                    ),
                  );
                  _loadMine();
                },
              ),
            ),
        ],
      ),
    );
  }
}
