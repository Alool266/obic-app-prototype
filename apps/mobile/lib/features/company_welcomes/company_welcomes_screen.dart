// Made by Dr Ali
// The greeting this employee should use. The app shows it and does not send it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class CompanyWelcomesScreen extends StatefulWidget {
  const CompanyWelcomesScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CompanyWelcomesScreen> createState() => _CompanyWelcomesScreenState();
}

class _CompanyWelcomesScreenState extends State<CompanyWelcomesScreen> {
  final _api = SocialApi();
  Map<String, dynamic>? _welcome;
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
      final home = await _api.companyWelcomesHome(token);
      if (!mounted) return;
      final welcome = home['welcome'];
      setState(() {
        _welcome = welcome is Map ? Map<String, dynamic>.from(welcome) : null;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final welcome = _welcome;
    final body = welcome?['body']?.toString() ?? '';
    final source = welcome?['source']?.toString();
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.companyWelcomesTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.companyWelcomesHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.companyWelcomesLoadFailed),
                  ),
                if (welcome == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l10n.companyWelcomesNone),
                  ),
                if (welcome != null) ...[
                  const SizedBox(height: 16),
                  Text(welcome['title']?.toString() ?? '', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(source == 'assigned' ? l10n.companyWelcomesAssigned : l10n.companyWelcomesDefault),
                  const SizedBox(height: 12),
                  SelectableText(body),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: body.isEmpty
                        ? null
                        : () async {
                            await Clipboard.setData(ClipboardData(text: body));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.companyWelcomesCopied)),
                            );
                          },
                    child: Text(l10n.companyWelcomesCopy),
                  ),
                ],
              ],
            ),
    );
  }
}
