// Made by Dr Ali
// An employee sees their own join and can ask to leave. The desk confirms it.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final _api = SocialApi();
  final _note = TextEditingController();
  Map<String, dynamic>? _home;
  DateTime? _lastDay;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final home = await _api.rosterHome(token);
      if (!mounted) return;
      setState(() {
        _home = home;
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

  String _day(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _send() async {
    final lastDay = _lastDay;
    if (lastDay == null || _sending) return;
    setState(() => _sending = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) return;
      await _api.requestRosterLeave(
        accessToken: token,
        lastDay: _day(lastDay),
        note: _note.text,
      );
      _note.clear();
      _lastDay = null;
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'active':
        return l10n.rosterActive;
      case 'leaving':
        return l10n.rosterLeaving;
      case 'left':
        return l10n.rosterLeft;
      case 'unrecorded':
        return l10n.rosterUnrecorded;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = _home?['status']?.toString() ?? 'unrecorded';
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.rosterTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.rosterHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.rosterLoadFailed),
                  ),
                const SizedBox(height: 16),
                Text(_statusLabel(l10n, status), style: Theme.of(context).textTheme.titleMedium),
                if (status == 'unrecorded')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(l10n.rosterMissing),
                  ),
                if (_home?['joinedOn'] != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.rosterJoined),
                    subtitle: Text(_home!['joinedOn'].toString()),
                  ),
                if (_home?['lastDay'] != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.rosterLastDay),
                    subtitle: Text(_home!['lastDay'].toString()),
                  ),
                if (status == 'active') ...[
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.rosterLastDay),
                    subtitle: Text(_lastDay == null ? l10n.roomsPick : _day(_lastDay!)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _lastDay ?? now,
                        firstDate: DateTime(now.year, now.month, now.day),
                        lastDate: now.add(const Duration(days: 365)),
                      );
                      if (picked == null || !mounted) return;
                      setState(() => _lastDay = picked);
                    },
                  ),
                  TextField(
                    controller: _note,
                    maxLength: 500,
                    decoration: InputDecoration(labelText: l10n.rosterNote),
                  ),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: Text(l10n.rosterAsk),
                  ),
                ],
                if (status == 'leaving')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(l10n.rosterPending),
                  ),
                if (status == 'left')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(l10n.rosterRecorded),
                  ),
              ],
            ),
    );
  }
}
