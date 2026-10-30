// Made by Dr Ali
// Handovers that give this employee company contacts, or take them away.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class CompanyHandoversScreen extends StatefulWidget {
  const CompanyHandoversScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CompanyHandoversScreen> createState() => _CompanyHandoversScreenState();
}

class _CompanyHandoversScreenState extends State<CompanyHandoversScreen> {
  final _api = SocialApi();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
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
      final home = await _api.companyHandoversHome(token);
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

  String _names(Object? value) {
    if (value is! List) return '';
    return value
        .map((item) {
          if (item is Map) return item['name']?.toString() ?? '';
          return '';
        })
        .where((name) => name.isNotEmpty)
        .join(', ');
  }

  String _when(Object? value) {
    final raw = value?.toString() ?? '';
    if (raw.length >= 10) return raw.substring(0, 10);
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.companyHandoverTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.companyHandoverHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.companyHandoverLoadFailed),
                  ),
                if (_rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l10n.companyHandoverNone),
                  ),
                for (final row in _rows)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      row['direction']?.toString() == 'received'
                          ? l10n.companyHandoverFrom(row['otherName']?.toString() ?? '')
                          : l10n.companyHandoverTo(row['otherName']?.toString() ?? ''),
                    ),
                    subtitle: Text(
                      '${l10n.companyHandoverCount(_count(row['contactCount']))} · ${_when(row['createdAt'])}\n${_names(row['contacts'])}',
                    ),
                  ),
              ],
            ),
    );
  }

  int _count(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
