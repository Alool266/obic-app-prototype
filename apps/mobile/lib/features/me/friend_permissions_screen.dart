// Made by Dr Ali
// Friends' permissions — two WeChat rows. Each opens a searchable checkmark picker.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../moments/moment_friend_picker.dart';
import '../moments/moments_notify_prefs.dart';
import '../social/social_api.dart';
import 'settings_widgets.dart';

class FriendPermissionsScreen extends StatefulWidget {
  const FriendPermissionsScreen({
    super.key,
    required this.authController,
    this.onChanged,
  });

  final AuthController authController;
  final Future<void> Function()? onChanged;

  @override
  State<FriendPermissionsScreen> createState() =>
      _FriendPermissionsScreenState();
}

class _FriendPermissionsScreenState extends State<FriendPermissionsScreen> {
  final _api = SocialApi();
  Set<String> _muted = {};
  Set<String> _hiddenFrom = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final muted = await MomentsNotifyPrefs.mutedFriendIds();
    final hidden = await MomentsNotifyPrefs.hiddenFromFriendIds();
    if (!mounted) return;
    setState(() {
      _muted = muted.toSet();
      _hiddenFrom = hidden.toSet();
      _loading = false;
    });
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      final prefs = await MomentsNotifyPrefs.syncFromServer(
        accessToken: token,
        api: _api,
      );
      if (!mounted) return;
      setState(() {
        _muted = prefs.mutedFriendIds.toSet();
        _hiddenFrom = prefs.hiddenFromFriendIds.toSet();
      });
    } catch (_) {}
  }

  Future<bool> _toggleMute(String friendId, bool mute) async {
    final token = await widget.authController.ensureAccessToken();
    if (token == null) return false;
    setState(() {
      if (mute) {
        _muted.add(friendId);
      } else {
        _muted.remove(friendId);
      }
    });
    try {
      if (mute) {
        await MomentsNotifyPrefs.muteFriend(
          accessToken: token,
          friendId: friendId,
          api: _api,
        );
      } else {
        await MomentsNotifyPrefs.unmuteFriend(
          accessToken: token,
          friendId: friendId,
          api: _api,
        );
      }
      await widget.onChanged?.call();
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        if (mute) {
          _muted.remove(friendId);
        } else {
          _muted.add(friendId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return false;
    }
  }

  Future<bool> _toggleHideFrom(String friendId, bool hide) async {
    final token = await widget.authController.ensureAccessToken();
    if (token == null) return false;
    setState(() {
      if (hide) {
        _hiddenFrom.add(friendId);
      } else {
        _hiddenFrom.remove(friendId);
      }
    });
    try {
      if (hide) {
        await MomentsNotifyPrefs.hideFromFriend(
          accessToken: token,
          friendId: friendId,
          api: _api,
        );
      } else {
        await MomentsNotifyPrefs.unhideFromFriend(
          accessToken: token,
          friendId: friendId,
          api: _api,
        );
      }
      await widget.onChanged?.call();
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        if (hide) {
          _hiddenFrom.remove(friendId);
        } else {
          _hiddenFrom.add(friendId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return false;
    }
  }

  Future<void> _openPicker({
    required String title,
    required Set<String> selected,
    required Future<bool> Function(String friendId, bool next) onToggle,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MomentFriendPickerScreen(
          authController: widget.authController,
          title: title,
          selectedIds: selected,
          onToggle: onToggle,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  String? _countLabel(AppLocalizations l10n, int count) {
    if (count <= 0) return null;
    return l10n.meFriendsCount(count);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        title: Text(l10n.settingsFriendsPermissions),
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 12),
                SettingsGroup(
                  children: [
                    SettingsNavTile(
                      title: l10n.friendsHideMyMoments,
                      value: _countLabel(l10n, _hiddenFrom.length),
                      onTap: () => _openPicker(
                        title: l10n.friendsHideMyMoments,
                        selected: _hiddenFrom,
                        onToggle: _toggleHideFrom,
                      ),
                    ),
                    SettingsNavTile(
                      title: l10n.friendsMuteMoments,
                      value: _countLabel(l10n, _muted.length),
                      onTap: () => _openPicker(
                        title: l10n.friendsMuteMoments,
                        selected: _muted,
                        onToggle: _toggleMute,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
