// Made by Dr Ali
// Staff invite sheet — add same-branch desk employees to support/order chat.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../moments/moment_avatar.dart';
import '../social/social_api.dart';

Future<bool> showAddStaffSheet({
  required BuildContext context,
  required AuthController authController,
  required String threadId,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ObicColors.surfaceOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _AddStaffSheet(
      authController: authController,
      threadId: threadId,
    ),
  );
  return result == true;
}

class _AddStaffSheet extends StatefulWidget {
  const _AddStaffSheet({
    required this.authController,
    required this.threadId,
  });

  final AuthController authController;
  final String threadId;

  @override
  State<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<_AddStaffSheet> {
  final _api = SocialApi();
  final Set<String> _selected = {};
  List<Map<String, dynamic>> _candidates = [];
  String? _branch;
  bool _loading = true;
  bool _saving = false;
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
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw AuthApiException('Not signed in');
      final data = await _api.listInviteCandidates(
        accessToken: token,
        threadId: widget.threadId,
      );
      if (!mounted) return;
      final rows = data['candidates'];
      setState(() {
        _branch = data['branch'] as String?;
        _candidates = rows is List
            ? rows.whereType<Map<String, dynamic>>().toList()
            : <Map<String, dynamic>>[];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _submit() async {
    if (_selected.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw AuthApiException('Not signed in');
      await _api.addParticipants(
        accessToken: token,
        threadId: widget.threadId,
        userIds: _selected.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.chatAddPeopleTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: ObicColors.titleOf(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _branch == null
                          ? l10n.chatAddPeopleHint
                          : '${l10n.chatAddPeopleHint} ($_branch)',
                      style: TextStyle(
                        color: ObicColors.mutedOf(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  ),
                )
              else if (_candidates.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.chatAddPeopleEmpty,
                      style: TextStyle(color: ObicColors.mutedOf(context)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _candidates.length,
                    itemBuilder: (ctx, i) {
                      final u = _candidates[i];
                      final id = u['userId'] as String? ?? '';
                      final name = (u['name'] as String?)?.trim().isNotEmpty == true
                          ? (u['name'] as String).trim()
                          : (u['email'] as String?) ?? id;
                      final title = (u['staffTitle'] as String?)?.trim();
                      final selected = _selected.contains(id);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(id);
                            } else {
                              _selected.remove(id);
                            }
                          });
                        },
                        secondary: MomentAvatar(
                          name: name,
                          avatarUrl: u['avatarUrl'] as String?,
                          size: 40,
                        ),
                        title: Text(name),
                        subtitle: title == null || title.isEmpty
                            ? null
                            : Text(title),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: Text(l10n.chatHandoffCancel),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            _saving || _selected.isEmpty ? null : _submit,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.chatAddPeopleSubmit),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
