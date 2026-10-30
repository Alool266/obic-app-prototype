// Made by Dr Ali
// Company tags on the contacts assigned to this employee.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class CompanyTagsScreen extends StatefulWidget {
  const CompanyTagsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CompanyTagsScreen> createState() => _CompanyTagsScreenState();
}

class _CompanyTagsScreenState extends State<CompanyTagsScreen> {
  final _api = SocialApi();
  List<Map<String, dynamic>> _tags = [];
  List<Map<String, dynamic>> _assignments = [];
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
      final home = await _api.companyContactTagsHome(token);
      if (!mounted) return;
      setState(() {
        _tags = _maps(home['tags']);
        _assignments = _maps(home['assignments']);
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

  List<String> _namesFor(String tagId) {
    final names = <String>[];
    for (final row in _assignments) {
      final ids = row['tagIds'];
      if (ids is! List || !ids.map((item) => item.toString()).contains(tagId)) continue;
      final name = row['name']?.toString() ?? '';
      if (name.isNotEmpty) names.add(name);
    }
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.companyTagsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.companyTagsHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.companyTagsLoadFailed),
                  ),
                if (_tags.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l10n.companyTagsNone),
                  ),
                for (final tag in _tags)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tag['name']?.toString() ?? ''),
                    subtitle: Text(
                      _namesFor(tag['id']?.toString() ?? '').join(', ').isEmpty
                          ? (tag['active'] == true ? l10n.companyTagsActive : l10n.companyTagsPaused)
                          : _namesFor(tag['id']?.toString() ?? '').join(', '),
                    ),
                  ),
              ],
            ),
    );
  }
}
