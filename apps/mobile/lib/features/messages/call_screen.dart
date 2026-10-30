// Made by Dr Ali
// In-app voice / video — Phase 5 Agora RTC (tokens from API; no certificate in app).

import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/device_alerts.dart';
import '../../core/obic_phrases.dart';
import '../../core/realtime_client.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_api.dart';
import '../me/voice_video_settings_screen.dart';
import '../moments/moment_avatar.dart';
import 'call_float.dart';
import 'call_ringtone.dart';
import 'calls_api.dart';

enum ObicCallMode { voice, video }

/// Result when leaving [ObicCallScreen] — used for WeChat-style chat bubbles.
class ObicCallFinish {
  const ObicCallFinish({
    required this.connected,
    required this.durationSeconds,
    this.joinFailed = false,
    this.errorMessage,
  });

  /// True when local join succeeded and a remote peer was seen (or group time).
  final bool connected;
  final int durationSeconds;
  final bool joinFailed;
  final String? errorMessage;
}

/// Join payload from POST /v1/calls or POST /v1/calls/:id/token.
class ObicCallJoin {
  const ObicCallJoin({
    required this.callId,
    required this.appId,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.mode,
    this.isGroup = false,
    this.conversationTitle,
    this.conversationId,
  });

  factory ObicCallJoin.fromJson(Map<String, dynamic> json) {
    final kind = json['conversationKind'] as String?;
    final isGroup = json['isGroup'] == true || kind == 'group';
    return ObicCallJoin(
      callId: json['callId'] as String,
      appId: json['appId'] as String,
      channelName: json['channelName'] as String,
      token: json['token'] as String,
      uid: (json['uid'] as num).toInt(),
      mode: (json['mode'] as String?) == 'video'
          ? ObicCallMode.video
          : ObicCallMode.voice,
      isGroup: isGroup,
      conversationTitle: json['conversationTitle'] as String?,
      conversationId: json['conversationId'] as String?,
    );
  }

  final String callId;
  final String appId;
  final String channelName;
  final String token;
  final int uid;
  final ObicCallMode mode;
  final bool isGroup;
  final String? conversationTitle;
  final String? conversationId;
}

class ObicCallScreen extends StatefulWidget {
  const ObicCallScreen({
    super.key,
    required this.peerName,
    this.peerSubtitle,
    this.avatarUrl,
    required this.mode,
    this.arabic = false,
    this.isGroup = false,
    this.join,
    this.pendingJoin,
    this.callId,
    this.onHangup,
    this.accessToken,
    this.members = const [],
    this.onAddPeople,
  });

  final String peerName;
  final String? peerSubtitle;
  final String? avatarUrl;
  final ObicCallMode mode;
  final bool arabic;
  /// Group channel — hangup leaves locally; peers stay on the call.
  final bool isGroup;
  /// When null, UI-only demo (no Agora) unless [pendingJoin] is set.
  final ObicCallJoin? join;
  /// Incoming accept: screen is shown immediately; token arrives on this future.
  final Future<ObicCallJoin>? pendingJoin;
  /// Known before the token arrives, so a remote hang-up can close a ringing screen.
  final String? callId;
  final Future<void> Function()? onHangup;
  /// Used to notice a remote hang-up when the socket event never arrives.
  final Future<String?> Function()? accessToken;
  final List<Map<String, dynamic>> members;
  final Future<void> Function()? onAddPeople;

  @override
  State<ObicCallScreen> createState() => _ObicCallScreenState();
}

class _ObicCallScreenState extends State<ObicCallScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _muted = false;
  bool _speaker = true;
  bool _cameraOff = false;
  bool _joining = false;
  String? _error;
  RtcEngine? _engine;
  ObicCallJoin? _join;
  /// Multi-participant remotes (1:1 keeps 0–1; group can grow).
  final Set<int> _remoteUids = {};
  bool _localJoined = false;
  bool _talked = false;
  bool _joinFailed = false;
  bool _reconnecting = false;
  bool _rejoining = false;
  int _rejoinAttempts = 0;
  String? _lastErrorDetail;
  Timer? _joinWatchdog;
  StreamSubscription<Map<String, dynamic>>? _endedSub;
  Timer? _aliveTimer;
  bool _closing = false;
  int? _loudUid;
  int? _focusUid;
  final Map<int, bool> _weak = {};

  bool get _video => widget.mode == ObicCallMode.video;
  String? get _callId => widget.callId ?? _join?.callId;
  bool get _live => _join != null;
  bool get _isGroup => widget.isGroup || (_join?.isGroup ?? false);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _localJoined && _remoteUids.isNotEmpty) {
        setState(() => _seconds++);
        CallFloatController.instance.note(seconds: _seconds);
      }
    });
    _join = widget.join;
    _endedSub = RealtimeClient.instance.onCallEnded.listen(_onRemoteEnded);
    _aliveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_checkRemoteHungUp());
    });
    unawaited(_loadCallPrefs());
    if (_join != null) {
      unawaited(_startAgora());
    } else if (widget.pendingJoin != null) {
      _joining = true;
      unawaited(_awaitPendingJoin());
    } else {
      _localJoined = true;
    }
  }

  Future<void> _awaitPendingJoin() async {
    try {
      final join = await widget.pendingJoin!;
      if (!mounted) return;
      setState(() => _join = join);
      await _startAgora();
    } catch (e) {
      if (!mounted) return;
      final soft = _friendlyCallError(e.toString(), lang: _phraseLang());
      setState(() {
        _joining = false;
        _joinFailed = true;
        _error = soft;
      });
    }
  }

  String _phraseLang() {
    if (!mounted) return widget.arabic ? 'ar' : 'en';
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'ar' || code == 'zh') return code;
    return 'en';
  }

  String _t(String ar, String en, String zh) {
    final code = _phraseLang();
    if (code == 'ar') return ar;
    if (code == 'zh') return zh;
    return en;
  }

  Future<void> _loadCallPrefs() async {
    final speaker = await CallSettingsPrefs.speakerDefault();
    if (!mounted || _engine != null) return;
    setState(() => _speaker = speaker || _video);
  }

  Future<void> _releaseIncomingAudio() async {
    await CallRingtone.instance.stop();
    await DeviceAlerts.instance.dismissIncomingCall(_callId);
  }

  /// The ringtone leaves the phone on a playback-only session. Voice stays
  /// silent until this runs, before Agora starts.
  Future<void> _claimCallAudioSession() async {
    await CallRingtone.instance.stop();
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.videoChat,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );
    await session.setActive(true);
  }

  Future<void> _openCallAudio() async {
    final engine = _engine;
    if (engine == null) return;
    await CallRingtone.instance.stop();
    try {
      await engine.enableAudio();
      await engine.enableLocalAudio(true);
      await engine.muteLocalAudioStream(_muted);
      await engine.muteAllRemoteAudioStreams(false);
      await engine.adjustRecordingSignalVolume(_muted ? 0 : 100);
      await engine.adjustPlaybackSignalVolume(100);
      await engine.setEnableSpeakerphone(_speaker);
      await engine.setDefaultAudioRouteToSpeakerphone(_speaker);
    } catch (_) {}
  }

  Future<void> _rejoinChannel() async {
    if (_rejoining || _closing || !mounted) return;
    if (_rejoinAttempts >= 5) {
      setState(() {
        _reconnecting = false;
        _error = _t(
          'تعذّر الاتصال. حاول مرة أخرى.',
          'Could not connect. Please try again.',
          '无法接通，请重试。',
        );
      });
      return;
    }
    final engine = _engine;
    final join = _join;
    if (engine == null || join == null) return;
    _rejoining = true;
    _rejoinAttempts++;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted || _closing) return;
      await engine.joinChannel(
        token: join.token,
        channelId: join.channelName,
        uid: join.uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: !_muted,
          publishCameraTrack: _video && !_cameraOff,
          autoSubscribeAudio: true,
          autoSubscribeVideo: _video,
        ),
      );
      await _openCallAudio();
    } catch (_) {
      // The next connection event retries until the attempt cap.
    } finally {
      _rejoining = false;
    }
  }

  Future<void> _applySpeaker(bool on) async {
    await _engine?.setEnableSpeakerphone(on);
    try {
      await _engine?.setDefaultAudioRouteToSpeakerphone(on);
    } catch (_) {}
  }

  Future<void> _startAgora() async {
    final join = _join!;
    _joinWatchdog?.cancel();
    await _leaveEngine();
    await _releaseIncomingAudio();
    _speaker = true;
    try {
      await _claimCallAudioSession();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _joining = true;
      _reconnecting = false;
      _error = null;
    });
    // Hard stop "Connecting…" if join never completes (bad token / network).
    _joinWatchdog = Timer(const Duration(seconds: 25), () {
      if (!mounted || _localJoined || !_joining) return;
      _joinWatchdog = null;
      setState(() {
        _joining = false;
        _error = _t(
          'تعذّر الاتصال. حاول مرة أخرى.',
          'Could not connect. Please try again.',
          '无法接通，请重试。',
        );
      });
      _toastSoft(_error!);
    });
    try {
      final ok = await _ensureCallPermissions();
      if (!ok) {
        _joinWatchdog?.cancel();
        _joinWatchdog = null;
        return;
      }

      final engine = createAgoraRtcEngine();
      // Communication supports small multi-party; same path for 1:1 + group.
      await engine.initialize(
        RtcEngineContext(
          appId: join.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      _engine = engine;

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            _joinWatchdog?.cancel();
            _joinWatchdog = null;
            if (!mounted) return;
            setState(() {
              _localJoined = true;
              _joining = false;
              _error = null;
            });
            // Outgoing / waiting: loop ringtone until peer joins.
            unawaited(_openCallAudio());
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (!mounted) return;
            CallRingtone.instance.releaseOutgoing();
            unawaited(_openCallAudio());
            setState(() {
              _remoteUids.add(remoteUid);
              _talked = true;
            });
            final name = _nameFor(remoteUid);
            if (name.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    obicPhrase(
                      context,
                      ar: 'انضم $name',
                      en: '$name joined',
                      zh: '$name 已加入',
                    ),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (!mounted || _closing || remoteUid == 0) return;
            // 1:1: the other person left the channel. Close now, even if we
            // were still on "ringing" and never marked the call connected.
            if (!_isGroup) {
              unawaited(_dismissRemote());
              return;
            }
            final name = _nameFor(remoteUid);
            setState(() {
              _remoteUids.remove(remoteUid);
              if (_focusUid == remoteUid) _focusUid = null;
            });
            if (name.isNotEmpty && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    obicPhrase(
                      context,
                      ar: 'غادر $name',
                      en: '$name left',
                      zh: '$name 已离开',
                    ),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          onError: (err, msg) {
            _joinWatchdog?.cancel();
            _joinWatchdog = null;
            if (!mounted) return;
            final detail = msg.isNotEmpty ? msg : err.toString();
            debugPrint('Agora onError: $err $msg');
            final soft = _friendlyCallError(detail, lang: _phraseLang());
            setState(() {
              _error = soft;
              _joining = false;
              _joinFailed = true;
              _lastErrorDetail = detail;
            });
            _toastSoft(soft);
          },
          onAudioVolumeIndication: (connection, speakers, speakerNumber, totalVolume) {
            if (!mounted || speakers.isEmpty) return;
            var best = speakers.first;
            for (final row in speakers) {
              if ((row.volume ?? 0) > (best.volume ?? 0)) best = row;
            }
            if ((best.volume ?? 0) < 18) return;
            final raw = best.uid ?? 0;
            final uid = raw == 0 ? null : raw;
            if (_loudUid == uid) return;
            setState(() => _loudUid = uid);
          },
          onNetworkQuality: (connection, uid, tx, rx) {
            if (!mounted) return;
            final weak = rx.index >= 4 || tx.index >= 4;
            if (_weak[uid] == weak) return;
            setState(() => _weak[uid] = weak);
          },
          onConnectionStateChanged: (connection, state, reason) {
            debugPrint('Agora connection: $state reason=$reason');
            if (!mounted) return;
            if (state == ConnectionStateType.connectionStateReconnecting) {
              setState(() => _reconnecting = true);
              return;
            }
            if (state == ConnectionStateType.connectionStateConnected) {
              _rejoinAttempts = 0;
              setState(() {
                _reconnecting = false;
                if (_localJoined) _error = null;
              });
              return;
            }
            if (state == ConnectionStateType.connectionStateDisconnected ||
                state == ConnectionStateType.connectionStateFailed) {
              if (_localJoined && !_closing) {
                setState(() => _reconnecting = true);
                unawaited(_rejoinChannel());
                return;
              }
              if (state != ConnectionStateType.connectionStateFailed) return;
              _joinWatchdog?.cancel();
              _joinWatchdog = null;
              final soft = _friendlyCallError(
                reason.toString(),
                lang: _phraseLang(),
              );
              setState(() {
                _reconnecting = false;
                _error = soft;
                _joining = false;
                if (!_localJoined) _joinFailed = true;
                _lastErrorDetail = reason.toString();
              });
            }
          },
        ),
      );

      await engine.enableAudio();
      await engine.enableLocalAudio(true);
      await engine.muteLocalAudioStream(false);
      try {
        await engine.setAudioProfile(
          profile: AudioProfileType.audioProfileSpeechStandard,
          scenario: AudioScenarioType.audioScenarioDefault,
        );
      } catch (_) {}
      if (_video) {
        await engine.enableVideo();
        // Phone-call size, not a broadcast. Keeps the picture moving on a weak link.
        try {
          await engine.setVideoEncoderConfiguration(
            const VideoEncoderConfiguration(
              dimensions: VideoDimensions(width: 640, height: 360),
              frameRate: 15,
              bitrate: 400,
              minBitrate: 200,
              orientationMode: OrientationMode.orientationModeAdaptive,
              degradationPreference: DegradationPreference.maintainFramerate,
            ),
          );
        } catch (_) {}
        await engine.enableLocalVideo(true);
        await engine.muteLocalVideoStream(false);
        try {
          await engine.setCameraCapturerConfiguration(
            const CameraCapturerConfiguration(
              cameraDirection: CameraDirection.cameraFront,
            ),
          );
        } catch (_) {}
        // Preview before join so the local face is published with the channel.
        await engine.startPreview();
      } else {
        await engine.disableVideo();
      }
      try {
        await engine.enableAudioVolumeIndication(
          interval: 400,
          smooth: 3,
          reportVad: false,
        );
      } catch (_) {}
      await engine.joinChannel(
        token: join.token,
        channelId: join.channelName,
        uid: join.uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          // Voice-only must not publish camera (Agora can fail/refuse join).
          publishCameraTrack: _video,
          autoSubscribeAudio: true,
          autoSubscribeVideo: _video,
        ),
      );
      await engine.updateChannelMediaOptions(
        ChannelMediaOptions(
          publishMicrophoneTrack: true,
          publishCameraTrack: _video,
          autoSubscribeAudio: true,
          autoSubscribeVideo: _video,
        ),
      );
      if (_video) await engine.muteLocalVideoStream(false);
      await _openCallAudio();
    } catch (e) {
      _joinWatchdog?.cancel();
      _joinWatchdog = null;
      if (!mounted) return;
      final soft = _friendlyCallError(e.toString(), lang: _phraseLang());
      setState(() {
        _joining = false;
        _error = soft;
      });
      _toastSoft(soft);
    }
  }

  /// Mic (+ camera for video). Explain first, then the system prompt.
  /// Denied stays on an error with Settings — the call is not "connected".
  Future<bool> _ensureCallPermissions() async {
    final micOk = await _ensureOnePermission(
      permission: Permission.microphone,
      title: _t('الميكروفون', 'Microphone', '麦克风'),
      why: _t(
        'أوبيك يحتاج الميكروفون حتى يسمعك الطرف الآخر في هذه المكالمة.',
        'OBIC needs the microphone so the other person can hear you on this call.',
        'OBIC 需要麦克风，对方才能在这通电话里听到你。',
      ),
      denied: _t(
        'يلزم إذن الميكروفون للمكالمة.',
        'Microphone access is required for this call.',
        '通话需要麦克风权限。',
      ),
    );
    if (!micOk) return false;
    if (!_video) return true;
    return _ensureOnePermission(
      permission: Permission.camera,
      title: _t('الكاميرا', 'Camera', '相机'),
      why: _t(
        'أوبيك يحتاج الكاميرا حتى يراك الطرف الآخر في مكالمة الفيديو.',
        'OBIC needs the camera so the other person can see you on this video call.',
        'OBIC 需要相机，对方才能在视频通话里看到你。',
      ),
      denied: _t(
        'يلزم إذن الكاميرا لمكالمة الفيديو.',
        'Camera access is required for this video call.',
        '视频通话需要相机权限。',
      ),
    );
  }

  Future<bool> _ensureOnePermission({
    required Permission permission,
    required String title,
    required String why,
    required String denied,
  }) async {
    final current = await permission.status;
    if (current.isGranted) return true;
    if (!mounted) return false;
    if (!current.isPermanentlyDenied) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(why),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(obicPhrase(ctx, ar: 'إلغاء', en: 'Cancel', zh: '取消')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(obicPhrase(ctx, ar: 'متابعة', en: 'Continue', zh: '继续')),
            ),
          ],
        ),
      );
      if (go != true) {
        if (mounted) {
          setState(() {
            _joining = false;
            _localJoined = false;
            _error = denied;
          });
        }
        return false;
      }
      final next = await permission.request();
      if (next.isGranted) return true;
    }
    if (!mounted) return false;
    await _showPermissionDenied(why);
    if (mounted) {
      setState(() {
        _joining = false;
        _localJoined = false;
        _error = denied;
      });
    }
    return false;
  }

  Future<void> _showPermissionDenied(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          obicPhrase(
            ctx,
            ar: 'إذن مطلوب',
            en: 'Permission needed',
            zh: '需要权限',
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(obicPhrase(ctx, ar: 'حسناً', en: 'OK', zh: '好')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              unawaited(openAppSettings());
            },
            child: Text(
              obicPhrase(ctx, ar: 'الإعدادات', en: 'Settings', zh: '设置'),
            ),
          ),
        ],
      ),
    );
  }

  void _toastSoft(String msg) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF2A2A2A),
      ),
    );
  }

  Future<void> _leaveEngine() async {
    CallRingtone.instance.releaseOutgoing();
    final eng = _engine;
    _engine = null;
    if (eng == null) return;
    try {
      await eng.leaveChannel();
      await eng.release();
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _aliveTimer?.cancel();
    _joinWatchdog?.cancel();
    unawaited(_endedSub?.cancel());
    unawaited(_leaveEngine());
    super.dispose();
  }

  void _onRemoteEnded(Map<String, dynamic> payload) {
    if (_closing || _isGroup) return;
    final id = payload['callId']?.toString() ?? '';
    final mine = _callId ?? '';
    final conv = payload['conversationId']?.toString() ?? '';
    final mineConv = _join?.conversationId ?? '';
    final sameCall = id.isNotEmpty && mine.isNotEmpty && id == mine;
    final sameChat = id.isEmpty &&
        conv.isNotEmpty &&
        mineConv.isNotEmpty &&
        conv == mineConv;
    if (!sameCall && !sameChat) return;
    unawaited(_dismissRemote(alreadyEnded: true));
  }

  /// Server session is gone (other person hung up or declined) even if Agora
  /// never delivered "user left" — common while the screen still says ringing.
  Future<void> _checkRemoteHungUp() async {
    if (_closing || _isGroup) return;
    final id = _callId;
    final tokenFn = widget.accessToken;
    if (id == null || id.isEmpty || tokenFn == null) return;
    final token = await tokenFn();
    if (token == null || _closing) return;
    try {
      await CallsApi().mintToken(accessToken: token, callId: id);
    } on AuthApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 410) {
        await _dismissRemote(alreadyEnded: true);
      }
    } catch (_) {}
  }

  /// Peer hung up, declined, cancelled, or left Agora. Close immediately.
  Future<void> _dismissRemote({bool alreadyEnded = false}) async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    _aliveTimer?.cancel();
    _joinWatchdog?.cancel();
    final finish = ObicCallFinish(
      connected: _talked,
      durationSeconds: _talked ? _seconds : 0,
      joinFailed: _joinFailed && !_localJoined,
      errorMessage: _lastErrorDetail ?? _error,
    );
    final hang = alreadyEnded ? null : widget.onHangup;
    _closeUi(finish);
    unawaited(_leaveEngine());
    if (hang != null) {
      unawaited(() async {
        try {
          await hang();
        } catch (_) {}
      }());
    }
  }

  String _fmt(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _endCall() async {
    if (_closing) return;
    _closing = true;
    await _leaveEngine();
    final hang = widget.onHangup;
    if (hang != null) {
      try {
        await hang();
      } catch (_) {}
    }
    if (!mounted && !CallFloatController.instance.visible) return;
    final finish = ObicCallFinish(
      connected: _talked,
      durationSeconds: _talked ? _seconds : 0,
      joinFailed: _joinFailed && !_localJoined,
      errorMessage: _lastErrorDetail ?? _error,
    );
    _closeUi(finish);
  }

  void _closeUi(ObicCallFinish finish) {
    if (CallFloatController.instance.visible) {
      CallFloatController.instance.close(finish);
      return;
    }
    if (mounted) Navigator.of(context).pop(finish);
  }

  String _nameFor(int uid) {
    final row = _memberFor(uid);
    final name = (row?['name'] as String?)?.trim() ?? '';
    return name;
  }

  String? _avatarFor(int uid) => _memberFor(uid)?['avatarUrl'] as String?;

  Map<String, dynamic>? _memberFor(int uid) {
    for (final row in widget.members) {
      final id = row['userId']?.toString() ?? row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      if (_agoraUid(id) == uid) return row;
    }
    return null;
  }

  int _agoraUid(String userId) {
    var h = 0;
    for (final code in userId.codeUnits) {
      h = _imul(31, h) + code;
      h = h.toSigned(32);
    }
    final u = (h & 0x7fffffff) % 2147483647;
    return u == 0 ? 1 : u;
  }

  int _imul(int a, int b) {
    final product = (a & 0xffffffff) * (b & 0xffffffff);
    return (product & 0xffffffff).toSigned(32);
  }

  Future<void> _toggleMute() async {
    final next = !_muted;
    setState(() => _muted = next);
    await _engine?.muteLocalAudioStream(next);
    try {
      await _engine?.adjustRecordingSignalVolume(next ? 0 : 100);
    } catch (_) {}
  }

  Future<void> _toggleSpeaker() async {
    final next = !_speaker;
    setState(() => _speaker = next);
    await _applySpeaker(next);
  }

  Future<void> _toggleCamera() async {
    final next = !_cameraOff;
    setState(() => _cameraOff = next);
    await _engine?.enableLocalVideo(!next);
    await _engine?.muteLocalVideoStream(next);
  }

  Future<void> _switchCamera() async {
    await _engine?.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return _video ? _buildVideo() : _buildVoice();
  }

  Widget _statusLine(bool ar) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _joining
                  ? null
                  : () {
                      setState(() => _error = null);
                      unawaited(_startAgora());
                    },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text(
                obicPhrase(
                  context,
                  ar: 'إعادة المحاولة',
                  en: 'Try again',
                  zh: '重试',
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_reconnecting) {
      return Text(
        obicPhrase(
          context,
          ar: 'جاري إعادة الاتصال…',
          en: 'Reconnecting…',
          zh: '正在重新连接…',
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (_joining) {
      return Text(
        obicPhrase(
          context,
          ar: 'جارٍ الاتصال…',
          en: 'Connecting…',
          zh: '正在连接…',
        ),
        style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
      );
    }
    if (_live && _remoteUids.isEmpty) {
      return Text(
        _isGroup
            ? obicPhrase(
                context,
                ar: 'بانتظار الأعضاء…',
                en: 'Waiting for members…',
                zh: '等待成员…',
              )
            : obicPhrase(context, ar: 'يرن…', en: 'Ringing…', zh: '正在呼叫…'),
        style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
      );
    }
    if (_isGroup && _remoteUids.isNotEmpty) {
      final n = _remoteUids.length + 1;
      return Text(
        '${_fmt(_seconds)} · ${ar ? '$n مشاركين' : '$n in call'}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      );
    }
    return Text(
      _fmt(_seconds),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildVoice() {
    final ar = widget.arabic;
    final label = _isGroup
        ? (ar ? 'مكالمة جماعية' : 'Group voice')
        : (ar ? 'مكالمة صوتية' : 'Voice call');
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1F3A), Color(0xFF1A6DFF), Color(0xFF0E7490)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: CallFloatController.instance.minimize,
                      icon: const Icon(
                        Icons.picture_in_picture_alt_rounded,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isGroup
                    ? _buildGroupVoiceBody(ar)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PulsingAvatar(
                            name: widget.peerName,
                            avatarUrl: widget.avatarUrl,
                            size: 112,
                          ),
                          const SizedBox(height: 22),
                          Text(
                            widget.peerName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (widget.peerSubtitle != null &&
                              widget.peerSubtitle!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              widget.peerSubtitle!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 15,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          _statusLine(ar),
                          const SizedBox(height: 22),
                          _VoiceWave(active: !_muted && _localJoined),
                        ],
                      ),
              ),
              _LiveStrip(arabic: ar, live: _live),
              if (_isGroup && widget.onAddPeople != null)
                TextButton.icon(
                  onPressed: () => unawaited(widget.onAddPeople!.call()),
                  icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                  label: Text(
                    obicPhrase(
                      context,
                      ar: 'إضافة أشخاص',
                      en: 'Add people',
                      zh: '添加成员',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              _CallControls(
                muted: _muted,
                speaker: _speaker,
                onMute: () => unawaited(_toggleMute()),
                onSpeaker: () => unawaited(_toggleSpeaker()),
                onEnd: () => unawaited(_endCall()),
                arabic: ar,
                leaveLabel: _isGroup,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupVoiceBody(bool ar) {
    final remotes = _remoteUids.toList()..sort();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.peerName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (widget.peerSubtitle != null &&
            widget.peerSubtitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            widget.peerSubtitle!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 14,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          runSpacing: 16,
          children: [
            _GroupPeerTile(
              label: obicPhrase(context, ar: 'أنت', en: 'You', zh: '我'),
              avatarUrl: widget.avatarUrl,
              speaking: _loudUid == null && !_muted && _localJoined,
              weak: _weak[0] == true,
            ),
            for (final uid in remotes)
              _GroupPeerTile(
                label: _nameFor(uid).isEmpty ? '#$uid' : _nameFor(uid),
                avatarUrl: _avatarFor(uid),
                speaking: _loudUid == uid,
                weak: _weak[uid] == true,
              ),
          ],
        ),
        const SizedBox(height: 22),
        _statusLine(ar),
        const SizedBox(height: 18),
        _VoiceWave(active: !_muted && _localJoined),
      ],
    );
  }

  Widget _buildVideo() {
    final ar = widget.arabic;
    final join = _join;
    final videoRemotes = _remoteUids.toList()..sort();
    final multi = _isGroup || videoRemotes.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_live &&
              _engine != null &&
              join != null &&
              videoRemotes.isNotEmpty)
            multi
                ? _GroupVideoGrid(
                    engine: _engine!,
                    channelName: join.channelName,
                    remoteUids: videoRemotes,
                    showLocal: !_cameraOff,
                    loudUid: _loudUid,
                    focusUid: _focusUid,
                    weak: _weak,
                    nameOf: _nameFor,
                    onFocus: (uid) => setState(() => _focusUid = uid),
                  )
                : AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine!,
                      canvas: VideoCanvas(uid: videoRemotes.first),
                      connection: RtcConnection(channelId: join.channelName),
                    ),
                  )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E3A5F),
                    Color(0xFF0B1F3A),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MomentAvatar(
                      name: widget.peerName,
                      avatarUrl: widget.avatarUrl,
                      size: 112,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.peerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _statusLine(ar),
                  ],
                ),
              ),
            ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: CallFloatController.instance.minimize,
                  icon: const Icon(
                    Icons.picture_in_picture_alt_rounded,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isGroup
                      ? obicPhrase(
                          context,
                          ar: 'فيديو جماعي',
                          en: 'Group video',
                          zh: '群视频',
                        )
                      : 'OBIC',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _localJoined ? _fmt(_seconds) : (ar ? '…' : '…'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!multi)
            Positioned(
              right: 16,
              top: MediaQuery.paddingOf(context).top + 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 108,
                  height: 148,
                  child: _engine != null && !_cameraOff
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      : Container(
                          color: ObicColors.navy.withValues(alpha: 0.85),
                          child: Center(
                            child: Icon(
                              Icons.videocam_off_outlined,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 32,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.paddingOf(context).bottom + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.88),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LiveStrip(arabic: ar, live: _live, onDark: true),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _VideoBtn(
                        icon: _muted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        active: _muted,
                        onTap: () => unawaited(_toggleMute()),
                      ),
                      _VideoBtn(
                        icon: _speaker
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        active: _speaker,
                        onTap: () => unawaited(_toggleSpeaker()),
                      ),
                      _VideoBtn(
                        icon: _cameraOff
                            ? Icons.videocam_off_rounded
                            : Icons.videocam_rounded,
                        active: _cameraOff,
                        onTap: () => unawaited(_toggleCamera()),
                      ),
                      _VideoBtn(
                        icon: Icons.cameraswitch_rounded,
                        onTap: () => unawaited(_switchCamera()),
                      ),
                      if (_isGroup && widget.onAddPeople != null)
                        _VideoBtn(
                          icon: Icons.person_add_alt_1_rounded,
                          onTap: () => unawaited(widget.onAddPeople!.call()),
                        ),
                      _VideoBtn(
                        icon: Icons.call_end_rounded,
                        end: true,
                        onTap: () => unawaited(_endCall()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupPeerTile extends StatelessWidget {
  const _GroupPeerTile({
    required this.label,
    this.avatarUrl,
    this.speaking = false,
    this.weak = false,
  });

  final String label;
  final String? avatarUrl;
  final bool speaking;
  final bool weak;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: speaking ? ObicColors.blue : Colors.white24,
                  width: speaking ? 3 : 1.5,
                ),
                boxShadow: speaking
                    ? [
                        BoxShadow(
                          color: ObicColors.blue.withValues(alpha: 0.7),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: MomentAvatar(name: label, avatarUrl: avatarUrl, size: 64),
            ),
            if (weak)
              PositionedDirectional(
                end: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.signal_cellular_alt_2_bar_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 88,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// WeChat-style multi-participant video grid (local + remotes).
class _GroupVideoGrid extends StatelessWidget {
  const _GroupVideoGrid({
    required this.engine,
    required this.channelName,
    required this.remoteUids,
    required this.showLocal,
    required this.loudUid,
    required this.focusUid,
    required this.weak,
    required this.nameOf,
    required this.onFocus,
  });

  final RtcEngine engine;
  final String channelName;
  final List<int> remoteUids;
  final bool showLocal;
  final int? loudUid;
  final int? focusUid;
  final Map<int, bool> weak;
  final String Function(int uid) nameOf;
  final void Function(int? uid) onFocus;

  Widget _tile(int uid) {
    final local = uid < 0;
    final speaking = local ? loudUid == null : loudUid == uid;
    final view = local
        ? (showLocal
            ? AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              )
            : ColoredBox(
                color: ObicColors.navy,
                child: Center(
                  child: Icon(
                    Icons.videocam_off_outlined,
                    color: Colors.white.withValues(alpha: 0.65),
                    size: 36,
                  ),
                ),
              ))
        : AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: engine,
              canvas: VideoCanvas(uid: uid),
              connection: RtcConnection(channelId: channelName),
            ),
          );
    final name = local ? '' : nameOf(uid);
    final isWeak = local ? weak[0] == true : weak[uid] == true;
    return GestureDetector(
      onTap: () => onFocus(focusUid == uid ? null : uid),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: speaking ? ObicColors.blue : Colors.transparent,
            width: 3,
          ),
          boxShadow: speaking
              ? [
                  BoxShadow(
                    color: ObicColors.blue.withValues(alpha: 0.55),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            view,
            if (name.isNotEmpty)
              PositionedDirectional(
                start: 6,
                bottom: 6,
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ),
            if (isWeak)
              const PositionedDirectional(
                end: 6,
                top: 6,
                child: Icon(
                  Icons.signal_cellular_alt_2_bar_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ids = <int>[-1, ...remoteUids];
    if (focusUid != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _tile(focusUid!),
          PositionedDirectional(
            start: 8,
            top: MediaQuery.paddingOf(context).top + 48,
            child: IconButton(
              onPressed: () => onFocus(null),
              icon: const Icon(
                Icons.close_fullscreen_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
    final count = ids.length;
    final cross = count <= 1
        ? 1
        : count <= 4
            ? 2
            : 3;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.paddingOf(context).top + 56,
        4,
        160,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: count,
      itemBuilder: (context, i) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: _tile(ids[i]),
      ),
    );
  }
}

class _PulsingAvatar extends StatefulWidget {
  const _PulsingAvatar({
    required this.name,
    this.avatarUrl,
    required this.size,
  });

  final String name;
  final String? avatarUrl;
  final double size;

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final scale = 1 + (_ctrl.value * 0.08);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
        child: MomentAvatar(
          name: widget.name,
          avatarUrl: widget.avatarUrl,
          size: widget.size,
        ),
      ),
    );
  }
}

class _VoiceWave extends StatelessWidget {
  const _VoiceWave({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final h = active ? 12.0 + (i % 3) * 10 : 6.0;
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + i * 80),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 5,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: active ? 0.85 : 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _LiveStrip extends StatelessWidget {
  const _LiveStrip({
    required this.arabic,
    required this.live,
    this.onDark = false,
  });
  final bool arabic;
  final bool live;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        live
            ? (arabic ? 'مكالمة مباشرة · Agora' : 'Live call · Agora')
            : (arabic
                ? 'واجهة تجريبية · فعّل Agora على الخادم'
                : 'Demo UI · enable Agora on the API'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: onDark ? Colors.white70 : Colors.white.withValues(alpha: 0.88),
          fontSize: 11.5,
          height: 1.35,
        ),
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  const _CallControls({
    required this.muted,
    required this.speaker,
    required this.onMute,
    required this.onSpeaker,
    required this.onEnd,
    required this.arabic,
    this.leaveLabel = false,
  });

  final bool muted;
  final bool speaker;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onEnd;
  final bool arabic;
  final bool leaveLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CallBtn(
            icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: arabic ? 'كتم' : 'Mute',
            active: muted,
            onTap: onMute,
          ),
          _CallBtn(
            icon: speaker ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            label: arabic ? 'سماعة' : 'Speaker',
            active: speaker,
            onTap: onSpeaker,
          ),
          _CallBtn(
            icon: Icons.call_end_rounded,
            label: leaveLabel
                ? (arabic ? 'مغادرة' : 'Leave')
                : (arabic ? 'إنهاء' : 'End'),
            end: true,
            onTap: onEnd,
          ),
        ],
      ),
    );
  }
}

class _CallBtn extends StatelessWidget {
  const _CallBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.end = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final bg = end
        ? const Color(0xFFEF4444)
        : active
            ? Colors.white
            : Colors.white.withValues(alpha: 0.18);
    final fg = end
        ? Colors.white
        : active
            ? ObicColors.navy
            : Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: end ? 64 : 56,
              height: end ? 64 : 56,
              child: Icon(icon, color: fg, size: end ? 30 : 26),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VideoBtn extends StatelessWidget {
  const _VideoBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.end = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final bg = end
        ? const Color(0xFFEF4444)
        : active
            ? Colors.white
            : Colors.white.withValues(alpha: 0.16);
    final fg = end
        ? Colors.white
        : active
            ? ObicColors.navy
            : Colors.white;
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: fg),
        ),
      ),
    );
  }
}

/// Incoming ring — WeChat-style full-screen overlay (avatar, name, Accept/Decline).
/// Ringtone is handled by [CallRingtone] while [CallRingController] has a payload.
class IncomingCallOverlay extends StatelessWidget {
  const IncomingCallOverlay({
    super.key,
    required this.fromName,
    this.fromAvatarUrl,
    required this.mode,
    required this.arabic,
    required this.onAccept,
    required this.onDecline,
    this.isGroup = false,
    this.groupTitle,
  });

  final String fromName;
  final String? fromAvatarUrl;
  final ObicCallMode mode;
  final bool arabic;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isGroup;
  final String? groupTitle;

  @override
  Widget build(BuildContext context) {
    final video = mode == ObicCallMode.video;
    final headline = isGroup
        ? (video
            ? obicPhrase(context, ar: 'مكالمة فيديو جماعية', en: 'Group video call', zh: '群视频通话')
            : obicPhrase(context, ar: 'مكالمة صوتية جماعية', en: 'Group voice call', zh: '群语音通话'))
        : (video
            ? obicPhrase(context, ar: 'مكالمة فيديو واردة', en: 'Incoming video call', zh: '视频来电')
            : obicPhrase(context, ar: 'مكالمة صوتية واردة', en: 'Incoming voice call', zh: '语音来电'));
    final title = (groupTitle != null && groupTitle!.trim().isNotEmpty)
        ? groupTitle!.trim()
        : fromName;
    final subtitle = isGroup
        ? obicPhrase(context, ar: 'من $fromName', en: 'From $fromName', zh: '来自 $fromName')
        : null;

    return Material(
      color: const Color(0xE6121A24),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 40),
          child: Column(
            children: [
              Text(
                headline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(flex: 2),
              MomentAvatar(
                name: title,
                avatarUrl: isGroup ? null : fromAvatarUrl,
                size: 112,
                borderRadius: 16,
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 15,
                  ),
                ),
              ],
              const Spacer(flex: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _IncomingAction(
                    color: const Color(0xFFFA5151),
                    icon: Icons.call_end_rounded,
                    label: obicPhrase(context, ar: 'رفض', en: 'Decline', zh: '拒绝'),
                    onTap: onDecline,
                  ),
                  _IncomingAction(
                    color: const Color(0xFF07C160),
                    icon: video
                        ? Icons.videocam_rounded
                        : Icons.call_rounded,
                    label: isGroup
                        ? obicPhrase(context, ar: 'انضمام', en: 'Join', zh: '加入')
                        : obicPhrase(context, ar: 'قبول', en: 'Accept', zh: '接听'),
                    onTap: onAccept,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomingAction extends StatelessWidget {
  const _IncomingAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 68,
              height: 68,
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// WeChat-style contact card for chat panel.
class ChatContactSheet extends StatelessWidget {
  const ChatContactSheet({
    super.key,
    required this.name,
    this.role,
    this.avatarUrl,
    this.arabic = false,
    this.onVoiceCall,
    this.onVideoCall,
  });

  final String name;
  final String? role;
  final String? avatarUrl;
  final bool arabic;
  final VoidCallback? onVoiceCall;
  final VoidCallback? onVideoCall;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ObicColors.lineOf(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            MomentAvatar(name: name, avatarUrl: avatarUrl, size: 80),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: ObicColors.titleOf(context),
              ),
            ),
            if (role != null && role!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                role!,
                style: TextStyle(color: ObicColors.mutedOf(context)),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onVoiceCall,
                  icon: const Icon(Icons.call_outlined),
                  label: Text(arabic ? 'صوت' : 'Voice'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onVideoCall,
                  icon: const Icon(Icons.videocam_outlined),
                  label: Text(arabic ? 'فيديو' : 'Video'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _friendlyCallError(String raw, {required String lang}) {
  String t(String ar, String en, String zh) {
    if (lang == 'ar') return ar;
    if (lang == 'zh') return zh;
    return en;
  }

  final s = raw.toLowerCase();
  if (s.contains('permission') ||
      s.contains('إذن') ||
      s.contains('microphone') ||
      s.contains('camera') ||
      s.contains('ميكروفون') ||
      s.contains('كاميرا')) {
    return t(
      'يلزم إذن الكاميرا أو الميكروفون.',
      'Camera or microphone access is required.',
      '需要相机或麦克风权限。',
    );
  }
  return t(
    'تعذّر الاتصال. حاول مرة أخرى.',
    'Could not connect. Please try again.',
    '无法接通，请重试。',
  );
}
