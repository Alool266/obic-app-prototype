// Made by Dr Ali
// WeChat-style contact profile. Self edits use /v1/users/me; friends use
// GET /v1/friends/:id/profile. Remarks stay on this phone.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../../core/connectivity_service.dart';
import '../../core/obic_phrases.dart';
import '../../core/media_url.dart';
import '../../core/obic_bidi.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/obic_cached_image.dart';
import '../../widgets/offline_banner.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import '../me/friend_permissions_screen.dart';
import '../messages/call_screen.dart';
import '../messages/calls_api.dart';
import '../messages/chat_call_body.dart';
import '../messages/chat_screen.dart';
import '../moments/moment_avatar.dart';
import '../moments/moment_media_viewer.dart';
import '../channels/channel_nav.dart';
import '../moments/moments_profile_screen.dart';
import '../social/social_api.dart';
import 'add_friend_screen.dart';
import 'friend_remark_store.dart';
import 'starred_friends_store.dart';

class ContactProfileScreen extends StatefulWidget {
  const ContactProfileScreen({
    super.key,
    required this.authController,
    required this.userId,
    this.seedUser,
    this.threadId,
    this.allowCall = true,
    this.offerAddFriend = false,
  });

  final AuthController authController;
  final String userId;

  /// Friend row payload (`user` object) so the card paints before the
  /// friend-profile route answers.
  final Map<String, dynamic>? seedUser;

  /// Direct thread already open in chat. Calls use this id.
  final String? threadId;

  /// Voice/video only when a direct thread can be started with the existing call flow.
  final bool allowCall;

  /// Shown when this profile was opened from a scanned user code.
  final bool offerAddFriend;

  @override
  State<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends State<ContactProfileScreen> {
  final _api = SocialApi();
  final _calls = CallsApi();

  String _name = '';
  String? _avatarUrl;
  String? _city;
  String? _country;
  String? _whatsUp;
  String? _obicId;
  List<String> _photos = const [];
  String? _channelName;
  String? _channelThumb;
  bool _loading = true;
  bool _busy = false;
  bool _uploading = false;

  bool get _isSelf => widget.authController.user?.id == widget.userId;

  @override
  void initState() {
    super.initState();
    _applySeed(widget.seedUser);
    if (_isSelf) _applySelf(widget.authController.user);
    FriendRemarkStore.instance.addListener(_onStore);
    StarredFriendsStore.instance.addListener(_onStore);
    widget.authController.addListener(_onAuth);
    unawaited(_load());
  }

  @override
  void dispose() {
    FriendRemarkStore.instance.removeListener(_onStore);
    StarredFriendsStore.instance.removeListener(_onStore);
    widget.authController.removeListener(_onAuth);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  void _onAuth() {
    if (!_isSelf || !mounted) return;
    _applySelf(widget.authController.user);
    setState(() {});
  }

  void _applySeed(Map<String, dynamic>? user) {
    if (user == null) return;
    _name = (user['name'] as String?)?.trim() ?? _name;
    _avatarUrl = user['avatarUrl'] as String? ?? _avatarUrl;
    _city = user['city'] as String? ?? _city;
    _country = user['country'] as String? ?? _country;
    _whatsUp = user['whatsUp'] as String? ?? _whatsUp;
    _obicId = user['obicId'] as String? ?? _obicId;
  }

  void _applySelf(ObicUser? user) {
    if (user == null) return;
    _name = user.name;
    _avatarUrl = user.avatarUrl;
    _city = user.city;
    _country = user.country;
    _whatsUp = user.whatsUp;
    _obicId = user.obicId;
  }

  void _applyCard(Map<String, dynamic> card) {
    _name = (card['name'] as String?)?.trim() ?? _name;
    _avatarUrl = card['avatarUrl'] as String?;
    _city = card['city'] as String?;
    _country = card['country'] as String?;
    _whatsUp = card['whatsUp'] as String?;
    _obicId = card['obicId'] as String?;
  }

  Future<void> _load() async {
    final owner = widget.authController.user?.id;
    if (owner != null && owner.isNotEmpty) {
      await FriendRemarkStore.instance.loadFor(owner);
      await StarredFriendsStore.instance.loadFor(owner);
    }
    if (_isSelf) {
      await widget.authController.refreshProfile();
      if (mounted) _applySelf(widget.authController.user);
    } else {
      try {
        final token = await widget.authController.accessToken();
        if (token != null) {
          final card = await _api.getFriendProfile(
            accessToken: token,
            userId: widget.userId,
          );
          if (mounted) _applyCard(card);
        }
      } catch (_) {
        // Seed from the friends list stays until the trial API has this route.
      }
    }
    await Future.wait([_loadPhotos(), _loadChannel()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPhotos() async {
    try {
      final token = await widget.authController.accessToken();
      final rows = await _api.listMomentsForUser(
        userId: widget.userId,
        accessToken: token,
      );
      if (!mounted) return;
      setState(() => _photos = _latestPhotoUrls(rows));
    } catch (_) {
      if (mounted) setState(() => _photos = const []);
    }
  }

  Future<void> _loadChannel() async {
    try {
      final token = await widget.authController.accessToken();
      final channel = await lookupPersonalChannel(
        api: _api,
        userId: widget.userId,
        accessToken: token,
      );
      if (!mounted || channel == null) return;
      setState(() {
        _channelName = channel.name;
        _channelThumb = channel.thumbUrl;
      });
    } catch (_) {
      // Missing channel stays hidden. This lookup does not create one.
    }
  }

  String? get _remark => FriendRemarkStore.instance.remarkFor(widget.userId);

  String get _displayName {
    final remark = _remark;
    if (!_isSelf && remark != null && remark.isNotEmpty) return remark;
    final name = _name.trim();
    return name.isEmpty ? '—' : name;
  }

  String? get _region {
    final parts = <String>[
      if (_city != null && _city!.trim().isNotEmpty) _city!.trim(),
      if (_country != null && _country!.trim().isNotEmpty) _country!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  Future<void> _openAvatar() async {
    final raw = _avatarUrl;
    final url = resolveMediaUrl(raw);
    if (url.isEmpty) {
      if (_isSelf) await _changeAvatar();
      return;
    }
    await openMomentPhotoViewer(context, urls: [url], initialIndex: 0);
  }

  Future<void> _changeAvatar() async {
    final shot = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (shot == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null) return;
      final items = await _api.uploadFiles(
        accessToken: token,
        files: [(path: shot.path, filename: p.basename(shot.path))],
      );
      if (items.isEmpty) return;
      final url = items.first['url'] as String?;
      if (url == null || url.isEmpty) return;
      final json = await _api.updateAvatar(accessToken: token, avatarUrl: url);
      await widget.authController.applyUser(ObicUser.fromJson(json));
    } catch (e) {
      if (!mounted) return;
      _toast(AppLocalizations.of(context).errorUploadFailed);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<String?> _askText({
    required String title,
    required String initial,
    String? hint,
    int maxLength = 120,
  }) async {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: maxLength,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.friendsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(l10n.profileSave),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  Future<void> _saveMe({
    String? name,
    String? city,
    String? country,
    String? whatsUp,
  }) async {
    final token = await widget.authController.accessToken();
    if (token == null) return;
    setState(() => _busy = true);
    try {
      final updated = await AuthApi().updateMe(
        accessToken: token,
        name: name,
        city: city,
        country: country,
        whatsUp: whatsUp,
      );
      await widget.authController.applyUser(updated);
      if (!mounted) return;
      _toast(AppLocalizations.of(context).contactProfileSaved);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editName() async {
    final l10n = AppLocalizations.of(context);
    final next = await _askText(title: l10n.profileName, initial: _name);
    if (next == null || !mounted) return;
    if (next.length < 2) return;
    await _saveMe(name: next);
  }

  Future<void> _editRegion() async {
    final l10n = AppLocalizations.of(context);
    final cityCtrl = TextEditingController(text: _city ?? '');
    final countryCtrl = TextEditingController(text: _country ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileRegion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cityCtrl,
              autofocus: true,
              maxLength: 120,
              decoration: InputDecoration(labelText: l10n.profileCity),
            ),
            TextField(
              controller: countryCtrl,
              maxLength: 120,
              decoration: InputDecoration(labelText: l10n.profileCountry),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.friendsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.profileSave),
          ),
        ],
      ),
    );
    final city = cityCtrl.text.trim();
    final country = countryCtrl.text.trim();
    cityCtrl.dispose();
    countryCtrl.dispose();
    if (ok != true || !mounted) return;
    await _saveMe(city: city, country: country);
  }

  Future<void> _editWhatsUp() async {
    final l10n = AppLocalizations.of(context);
    final next = await _askText(
      title: l10n.profileWhatsUp,
      initial: _whatsUp ?? '',
      maxLength: 120,
    );
    if (next == null || !mounted) return;
    await _saveMe(whatsUp: next);
  }

  Future<void> _editRemark() async {
    final l10n = AppLocalizations.of(context);
    final next = await _askText(
      title: l10n.contactProfileSetRemark,
      initial: _remark ?? '',
      hint: l10n.contactProfileRemarkHint,
      maxLength: 40,
    );
    if (next == null || !mounted) return;
    await FriendRemarkStore.instance.setRemark(widget.userId, next);
    if (!mounted) return;
    _toast(l10n.contactProfileSaved);
  }

  Future<void> _openChannel() async {
    await openUserChannel(
      context,
      widget.authController,
      userId: widget.userId,
    );
  }

  Future<void> _openAlbum() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MomentsProfileScreen(
          authController: widget.authController,
          userId: widget.userId,
          initialName: _name.isEmpty ? null : _name,
          initialAvatarUrl: _avatarUrl,
        ),
      ),
    );
    if (mounted) await _loadPhotos();
  }

  Future<void> _openQr() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddFriendScreen(
          authController: widget.authController,
          demoInitialTab: 1,
        ),
      ),
    );
  }

  Future<void> _addFromScan() async {
    final token = await widget.authController.ensureAccessToken();
    if (token == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _api.sendFriendRequest(accessToken: token, userId: widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            obicPhrase(
              context,
              ar: 'تم إرسال طلب الصداقة',
              en: 'Friend request sent',
              zh: '已发送好友请求',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            obicPhrase(
              context,
              ar: 'تعذّر إرسال الطلب. حاول مرة أخرى.',
              en: 'Could not send the request. Please try again.',
              zh: '无法发送请求，请重试。',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _message() async {
    try {
      final token = await widget.authController.accessToken();
      if (token == null || !mounted) return;
      final thread = await _api.openDirectThread(
        accessToken: token,
        peerUserId: widget.userId,
      );
      final id = thread['id'] as String?;
      if (id == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            authController: widget.authController,
            threadId: id,
            title: _displayName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString());
    }
  }

  Future<void> _startCall({required bool video}) async {
    if (ConnectivityService.instance.isOffline) {
      await showNetworkUnavailableDialog(context);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (!mounted) return;
      _toast(l10n.callErrorPermission);
      if (mic.isPermanentlyDenied || mic.isRestricted) {
        unawaited(openAppSettings());
      }
      return;
    }
    if (video) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) {
        if (!mounted) return;
        _toast(l10n.callErrorPermission);
        if (cam.isPermanentlyDenied || cam.isRestricted) {
          unawaited(openAppSettings());
        }
        return;
      }
    }
    final token = await widget.authController.accessToken();
    if (token == null || !mounted) return;
    setState(() => _busy = true);
    try {
      var threadId = widget.threadId;
      if (threadId == null || threadId.isEmpty) {
        final thread = await _api.openDirectThread(
          accessToken: token,
          peerUserId: widget.userId,
        );
        threadId = thread['id'] as String?;
      }
      if (threadId == null || threadId.isEmpty || !mounted) return;
      final joinMap = await _calls.createCall(
        accessToken: token,
        conversationId: threadId,
        mode: video ? 'video' : 'voice',
      );
      if (!mounted) return;
      final join = ObicCallJoin.fromJson(joinMap);
      final arabic = Localizations.localeOf(context).languageCode == 'ar';
      final finish = await Navigator.of(context).push<ObicCallFinish>(
        MaterialPageRoute(
          builder: (_) => ObicCallScreen(
            peerName: _displayName,
            peerSubtitle: 'OBIC',
            avatarUrl: _avatarUrl,
            mode: join.mode,
            arabic: arabic,
            isGroup: false,
            callId: join.callId,
            join: join,
            onHangup: () async {
              final t = await widget.authController.accessToken();
              if (t == null) return;
              try {
                await _calls.endCall(accessToken: t, callId: join.callId);
              } catch (_) {}
            },
            accessToken: widget.authController.ensureAccessToken,
          ),
        ),
      );
      if (finish?.joinFailed == true) return;
      final outcome =
          finish != null && finish.connected && finish.durationSeconds > 0
          ? ObicCallRecordOutcome.ended
          : ObicCallRecordOutcome.cancelled;
      final body = buildCallRecordBody(
        ObicCallRecord(
          mode: join.mode == ObicCallMode.video
              ? ObicCallRecordMode.video
              : ObicCallRecordMode.voice,
          outcome: outcome,
          durationSeconds: outcome == ObicCallRecordOutcome.ended
              ? (finish?.durationSeconds ?? 0)
              : 0,
          endedByUserId: widget.authController.user?.id,
          side: ObicCallRecordSide.outgoing,
        ),
      );
      final fresh = await widget.authController.accessToken();
      if (fresh == null) return;
      await _api.sendMessage(
        accessToken: fresh,
        threadId: threadId,
        body: body,
      );
    } catch (_) {
      if (!mounted) return;
      _toast(l10n.contactProfileCallFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseCall() async {
    final l10n = AppLocalizations.of(context);
    final video = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: ObicColors.surfaceOf(context),
      builder: (ctx) {
        final sheetInk = ObicColors.inkOf(ctx);
        final sheetMuted = ObicColors.mutedOf(ctx);
        final sheetLine = ObicColors.lineOf(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.call_outlined,
                  color: ObicColors.blue,
                ),
                title: Text(
                  l10n.contactProfileVoice,
                  style: TextStyle(color: sheetInk, fontSize: 16),
                ),
                onTap: () => Navigator.pop(ctx, false),
              ),
              Divider(height: 0.5, thickness: 0.5, color: sheetLine),
              ListTile(
                leading: const Icon(
                  Icons.videocam_outlined,
                  color: ObicColors.blue,
                ),
                title: Text(
                  l10n.contactProfileVideo,
                  style: TextStyle(color: sheetInk, fontSize: 16),
                ),
                onTap: () => Navigator.pop(ctx, true),
              ),
              ColoredBox(
                color: ObicColors.canvasOf(ctx),
                child: const SizedBox(height: 8, width: double.infinity),
              ),
              ListTile(
                title: Text(
                  l10n.friendsCancel,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: sheetMuted, fontSize: 16),
                ),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
    if (video == null || !mounted) return;
    await _startCall(video: video);
  }

  Future<void> _more() async {
    final l10n = AppLocalizations.of(context);
    final starred = StarredFriendsStore.instance.isStarred(widget.userId);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: ObicColors.surfaceOf(context),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(starred ? l10n.friendsUnstar : l10n.friendsStar),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(StarredFriendsStore.instance.toggle(widget.userId));
              },
            ),
            ListTile(
              title: Text(l10n.settingsFriendsPermissions),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FriendPermissionsScreen(
                      authController: widget.authController,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              title: Text(l10n.contactProfileSetRemark),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(_editRemark());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = ObicColors.surfaceOf(context);
    final ink = ObicColors.inkOf(context);
    final muted = ObicColors.mutedOf(context);
    final line = ObicColors.lineOf(context);
    final remark = _remark;
    final region = _region;
    final status = _whatsUp?.trim();
    final obicId = _obicId?.trim();
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (!_isSelf)
            IconButton(
              tooltip: l10n.contactProfileRemark,
              onPressed: _busy ? null : _more,
              icon: const Icon(Icons.more_horiz),
            ),
        ],
      ),
      body: _loading && _name.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ColoredBox(
                  color: surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _uploading ? null : _openAvatar,
                          onLongPress: _isSelf && !_uploading
                              ? _changeAvatar
                              : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                MomentAvatar(
                                  name: _displayName,
                                  avatarUrl: _avatarUrl,
                                  size: 64,
                                  borderRadius: 8,
                                ),
                                if (_uploading)
                                  const Positioned.fill(
                                    child: ColoredBox(
                                      color: Color(0x66000000),
                                      child: Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 22,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                ),
                              ),
                              if (_isSelf) ...[
                                const SizedBox(height: 4),
                                Text(
                                  l10n.contactProfileYou,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (!_isSelf &&
                                  remark != null &&
                                  _name.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  l10n.contactProfileRealName(_name.trim()),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14, color: muted),
                                ),
                              ],
                              if (obicId != null && obicId.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      '${l10n.meObicId}: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: muted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Flexible(
                                      child: ObicIdentifierText(
                                        obicId,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (region != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${l10n.profileRegion}: $region',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: muted),
                                ),
                              ],
                              if (status != null && status.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  status,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.3,
                                    color: ink,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!_isSelf) ...[
                  const SizedBox(height: 8),
                  _remarkRow(l10n, surface, ink, muted, rtl, remark),
                ],
                const SizedBox(height: 8),
                _albumRow(l10n, surface, ink, muted, rtl),
                if (_channelName != null)
                  _channelRow(l10n, surface, ink, muted, rtl),
                const SizedBox(height: 8),
                if (_isSelf)
                  _selfFields(l10n, surface, ink, muted, line)
                else ...[
                  if (widget.offerAddFriend)
                    _actionRow(
                      icon: Icons.person_add_alt_1,
                      label: obicPhrase(
                        context,
                        ar: 'إضافة صديق',
                        en: 'Add friend',
                        zh: '添加朋友',
                      ),
                      onTap: _busy ? null : _addFromScan,
                    ),
                  if (widget.offerAddFriend)
                    Divider(height: 0.5, thickness: 0.5, color: line),
                  _actionRow(
                    icon: Icons.chat_bubble_outline,
                    label: l10n.friendsMessage,
                    onTap: _busy ? null : _message,
                  ),
                  if (widget.allowCall) ...[
                    Divider(height: 0.5, thickness: 0.5, color: line),
                    _actionRow(
                      icon: Icons.call_outlined,
                      label: l10n.contactProfileVoiceOrVideo,
                      onTap: _busy ? null : _chooseCall,
                    ),
                  ],
                ],
              ],
            ),
    );
  }

  Widget _remarkRow(
    AppLocalizations l10n,
    Color surface,
    Color ink,
    Color muted,
    bool rtl,
    String? remark,
  ) {
    final hasRemark = remark != null && remark.isNotEmpty;
    return Material(
      color: surface,
      child: InkWell(
        onTap: _busy ? null : _editRemark,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.contactProfileRemark,
                      style: TextStyle(
                        fontSize: 16,
                        color: ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasRemark ? remark : l10n.contactProfileRemarkHint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: hasRemark ? ink : muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                rtl ? Icons.chevron_left : Icons.chevron_right,
                color: muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _albumRow(
    AppLocalizations l10n,
    Color surface,
    Color ink,
    Color muted,
    bool rtl,
  ) {
    final emptyLine = _photos.isEmpty
        ? (_isSelf
              ? l10n.contactMomentsNoneSelf
              : l10n.contactMomentsNone(_displayName))
        : null;
    return Material(
      color: surface,
      child: InkWell(
        onTap: _openAlbum,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 4, 10),
            child: Row(
              children: [
                if (emptyLine != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSelf ? l10n.meMyPosts : l10n.momentsTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            color: ink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          emptyLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      _isSelf ? l10n.meMyPosts : l10n.momentsTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (_photos.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRect(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final url in _photos)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 4,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: ObicCachedImage(
                                    resolveMediaUrl(url),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                Icon(
                  rtl ? Icons.chevron_left : Icons.chevron_right,
                  color: muted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _channelRow(
    AppLocalizations l10n,
    Color surface,
    Color ink,
    Color muted,
    bool rtl,
  ) {
    final name = _channelName;
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    final thumb = _channelThumb;
    return Material(
      color: surface,
      child: InkWell(
        onTap: _openChannel,
        child: Column(
          children: [
            Divider(
              height: 0.5,
              thickness: 0.5,
              indent: 16,
              color: ObicColors.lineOf(context),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 4, 10),
                child: Row(
                  children: [
                    Text(
                      l10n.channelTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 15, color: ink),
                      ),
                    ),
                    if (thumb != null && thumb.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: ObicCachedImage(
                          resolveMediaUrl(thumb),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    Icon(
                      rtl ? Icons.chevron_left : Icons.chevron_right,
                      color: muted,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selfFields(
    AppLocalizations l10n,
    Color surface,
    Color ink,
    Color muted,
    Color line,
  ) {
    Widget row({
      required String title,
      required String value,
      required VoidCallback onTap,
      bool identifier = false,
    }) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final valueStyle = TextStyle(fontSize: 16, color: muted);
      final besideLabel = identifier && rtl && value.isNotEmpty;
      final valueChild = identifier
          ? ObicIdentifierText(value, style: valueStyle)
          : Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: valueStyle,
            );
      return Material(
        color: surface,
        child: InkWell(
          onTap: _busy ? null : onTap,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(title, style: TextStyle(fontSize: 16, color: ink)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: identifier
                        ? Align(
                            alignment: besideLabel
                                ? AlignmentDirectional.centerStart
                                : AlignmentDirectional.centerEnd,
                            child: valueChild,
                          )
                        : valueChild,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final id = _obicId?.trim() ?? '';
    return Column(
      children: [
        row(title: l10n.profileName, value: _name, onTap: _editName),
        Divider(height: 0.5, thickness: 0.5, indent: 20, color: line),
        row(
          title: l10n.profileRegion,
          value: _region ?? '',
          onTap: _editRegion,
        ),
        Divider(height: 0.5, thickness: 0.5, indent: 20, color: line),
        row(
          title: l10n.profileWhatsUp,
          value: _whatsUp?.trim() ?? '',
          onTap: _editWhatsUp,
        ),
        const SizedBox(height: 8),
        row(title: l10n.meMyQr, value: id, identifier: true, onTap: _openQr),
      ],
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: ObicColors.surfaceOf(context),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: Center(
            child: Opacity(
              opacity: enabled ? 1 : 0.45,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: ObicColors.blue),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: ObicColors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<String> _latestPhotoUrls(List<Map<String, dynamic>> moments) {
  final urls = <String>[];
  for (final moment in moments) {
    final media = moment['media'];
    if (media is List) {
      for (final item in media) {
        if (item is! Map) continue;
        final kind = item['kind'] as String? ?? 'image';
        if (kind == 'video') continue;
        final url = item['url'] as String?;
        if (url == null || url.isEmpty) continue;
        urls.add(url);
        if (urls.length >= 4) return urls;
      }
    }
    final legacy = moment['imageUrl'] as String?;
    if (legacy != null && legacy.isNotEmpty) {
      urls.add(legacy);
      if (urls.length >= 4) return urls;
    }
  }
  return urls;
}
