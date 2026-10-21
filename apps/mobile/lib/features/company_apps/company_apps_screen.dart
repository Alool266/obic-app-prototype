// Made by Dr Ali
// Company web tools. Staff open the page. OBIC does not host it.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class CompanyAppsScreen extends StatefulWidget {
  const CompanyAppsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CompanyAppsScreen> createState() => _CompanyAppsScreenState();
}

class _CompanyAppsScreenState extends State<CompanyAppsScreen> {
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
      final home = await _api.companyAppsHome(token);
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

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') {
      setState(() => _error = 'failed');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) setState(() => _error = 'failed');
  }

  List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.companyAppsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.companyAppsHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.companyAppsLoadFailed),
                  ),
                if (_rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l10n.companyAppsNone),
                  ),
                for (final row in _rows)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(row['name']?.toString() ?? ''),
                    subtitle: Text(row['note']?.toString() ?? ''),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _open(row['url']?.toString() ?? ''),
                  ),
              ],
            ),
    );
  }
}
