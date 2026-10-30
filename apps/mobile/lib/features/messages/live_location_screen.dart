// Made by Dr Ali
// Live location map. Only people in this chat are on it.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/api_errors.dart';
import '../../core/connectivity_service.dart';
import '../../core/obic_phrases.dart';
import '../../core/realtime_client.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../moments/moment_avatar.dart';
import '../social/social_api.dart';
import 'obic_map_view.dart';

Future<int?> pickLiveShareMinutes(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: ObicColors.surfaceOf(context),
    builder: (ctx) {
      Widget row(int minutes, String ar, String en, String zh) {
        return ListTile(
          title: Text(
            obicPhrase(ctx, ar: ar, en: en, zh: zh),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => Navigator.pop(ctx, minutes),
        );
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                obicPhrase(
                  ctx,
                  ar: 'كم من الوقت؟',
                  en: 'How long?',
                  zh: '共享多久？',
                ),
                style: TextStyle(
                  color: ObicColors.titleOf(ctx),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            row(15, '15 دقيقة', '15 minutes', '15分钟'),
            row(60, 'ساعة واحدة', '1 hour', '1小时'),
            row(480, '8 ساعات', '8 hours', '8小时'),
          ],
        ),
      );
    },
  );
}

class LiveShare {
  LiveShare({
    required this.userId,
    required this.name,
    required this.lat,
    required this.lng,
    this.avatarUrl,
    this.accuracy,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final double lat;
  final double lng;
  final double? accuracy;

  static LiveShare? fromJson(Map<String, dynamic> json) {
    final lat = json['lat'];
    final lng = json['lng'];
    final id = json['userId']?.toString() ?? '';
    if (id.isEmpty || lat is! num || lng is! num) return null;
    return LiveShare(
      userId: id,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'OBIC',
      avatarUrl: json['avatarUrl'] as String?,
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      accuracy: json['accuracy'] is num ? (json['accuracy'] as num).toDouble() : null,
    );
  }
}

class LiveLocationScreen extends StatefulWidget {
  const LiveLocationScreen({
    super.key,
    required this.authController,
    required this.conversationId,
    this.minutes,
    this.preferChina = false,
  });

  final AuthController authController;
  final String conversationId;
  final int? minutes;
  final bool preferChina;

  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  final _api = SocialApi();
  final _map = MapController();
  final _distance = const Distance();
  List<LiveShare> _shares = [];
  StreamSubscription<Position>? _gps;
  StreamSubscription<Map<String, dynamic>>? _socket;
  String? _banner;
  bool _sharing = false;
  bool _busy = false;
  bool _sentStart = false;
  bool _needsSettings = false;
  int? _minutes;
  LatLng? _lastFix;
  bool _startFailed = false;

  @override
  void initState() {
    super.initState();
    _minutes = widget.minutes;
    _socket = RealtimeClient.instance.onLiveLocation.listen(_onSocket);
    ConnectivityService.instance.addListener(_onNet);
    _load();
    if (widget.minutes != null) {
      _sharing = true;
      unawaited(_begin());
    }
  }

  @override
  void dispose() {
    _gps?.cancel();
    _socket?.cancel();
    ConnectivityService.instance.removeListener(_onNet);
    super.dispose();
  }

  void _onNet() {
    if (!mounted) return;
    if (ConnectivityService.instance.isOffline) {
      setState(() {
        _banner = obicPhrase(
          context,
          ar: 'لا يوجد اتصال. سنحدّث الموقع عندما يعود.',
          en: 'No internet. Location will update when it comes back.',
          zh: '没有网络。恢复后会继续更新位置。',
        );
      });
      return;
    }
    setState(() => _banner = null);
  }

  void _onSocket(Map<String, dynamic> event) {
    if (event['conversationId']?.toString() != widget.conversationId) return;
    final raw = event['shares'];
    if (raw is! List || !mounted) return;
    setState(() {
      _shares = raw
          .whereType<Map>()
          .map((row) => LiveShare.fromJson(Map<String, dynamic>.from(row)))
          .whereType<LiveShare>()
          .toList();
    });
  }

  Future<void> _load() async {
    final token = await widget.authController.accessToken();
    if (token == null) return;
    try {
      final rows = await _api.listLiveLocation(
        accessToken: token,
        conversationId: widget.conversationId,
      );
      if (!mounted) return;
      setState(() {
        _shares = rows.map(LiveShare.fromJson).whereType<LiveShare>().toList();
      });
    } catch (_) {}
  }

  Future<void> _begin() async {
    final permission = await Geolocator.checkPermission();
    var next = permission;
    if (permission == LocationPermission.denied) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(obicPhrase(ctx, ar: 'الموقع', en: 'Location', zh: '位置')),
            content: Text(
              obicPhrase(
                ctx,
                ar: 'أوبيك يحتاج موقعك ليراه الأشخاص في هذه المحادثة فقط، وللمدة التي تختارها.',
                en: 'OBIC needs your location so only people in this chat can see you, for the time you choose.',
                zh: 'OBIC 需要你的位置，只有本聊天里的人能看到，并且只在你选择的时间内。',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(obicPhrase(ctx, ar: 'متابعة', en: 'Continue', zh: '继续')),
              ),
            ],
          ),
        );
      }
      next = await Geolocator.requestPermission();
    }
    if (next == LocationPermission.denied || next == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() {
        _sharing = false;
        _needsSettings = true;
        _banner = obicPhrase(
          context,
          ar: 'لم يُسمح بالموقع.',
          en: 'Location permission was denied.',
          zh: '没有位置权限。',
        );
      });
      return;
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled && mounted) {
      setState(() {
        _banner = obicPhrase(
          context,
          ar: 'خدمة الموقع متوقفة على الهاتف.',
          en: 'Location is turned off on this phone.',
          zh: '手机的定位服务已关闭。',
        );
      });
    }
    _gps = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPosition, onError: (_) {
      if (!mounted) return;
      setState(() {
        _banner = obicPhrase(
          context,
          ar: 'إشارة الموقع ضعيفة. سنحدّث عندما تتحسن.',
          en: 'GPS is weak. It will update when the signal improves.',
          zh: '定位信号弱。信号恢复后会继续更新。',
        );
      });
    });
  }

  Future<void> _onPosition(Position position) async {
    if (!mounted || !_sharing) return;
    _lastFix = LatLng(position.latitude, position.longitude);
    final weak = position.accuracy > 80;
    setState(() {
      _banner = weak
          ? obicPhrase(
              context,
              ar: 'إشارة الموقع ضعيفة.',
              en: 'GPS signal is weak.',
              zh: '定位信号弱。',
            )
          : ConnectivityService.instance.isOffline
          ? obicPhrase(
              context,
              ar: 'لا يوجد اتصال. سنحدّث الموقع عندما يعود.',
              en: 'No internet. Location will update when it comes back.',
              zh: '没有网络。恢复后会继续更新位置。',
            )
          : null;
    });
    if (ConnectivityService.instance.isOffline) return;
    final token = await widget.authController.accessToken();
    if (token == null) return;
    try {
      final json = await _api.liveLocation(
        accessToken: token,
        conversationId: widget.conversationId,
        lat: position.latitude,
        lng: position.longitude,
        accuracy: position.accuracy,
        minutes: _sentStart ? null : _minutes,
      );
      _sentStart = true;
      _startFailed = false;
      final shares = json['shares'];
      if (!mounted || shares is! List) return;
      setState(() {
        _shares = shares
            .whereType<Map>()
            .map((row) => LiveShare.fromJson(Map<String, dynamic>.from(row)))
            .whereType<LiveShare>()
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _startFailed = true;
        _banner = _err(e);
      });
    }
  }

  Future<void> _join() async {
    final minutes = await pickLiveShareMinutes(context);
    if (minutes == null || !mounted) return;
    setState(() {
      _minutes = minutes;
      _sharing = true;
      _sentStart = false;
      _busy = false;
    });
    await _begin();
  }

  Future<void> _stop() async {
    setState(() => _busy = true);
    _sharing = false;
    await _gps?.cancel();
    final token = await widget.authController.accessToken();
    if (token != null) {
      try {
        await _api.stopLiveLocation(
          accessToken: token,
          conversationId: widget.conversationId,
        );
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _centreMe() async {
    if (_lastFix != null) {
      _map.move(_lastFix!, 16);
      return;
    }
    final me = widget.authController.user?.id;
    final mine = _shares.where((row) => row.userId == me);
    if (mine.isNotEmpty) {
      _map.move(LatLng(mine.first.lat, mine.first.lng), 16);
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() => _lastFix = point);
      _map.move(point, 16);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _banner = obicPhrase(
          context,
          ar: 'ما قدرنا نحدد موقعك. حاول مرة أخرى.',
          en: 'Could not find your location. Please try again.',
          zh: '无法确定你的位置，请重试。',
        );
      });
    }
  }

  void _showAll() {
    if (_shares.isEmpty) return;
    final points = _shares.map((row) => LatLng(row.lat, row.lng)).toList();
    if (points.length == 1) {
      _map.move(points.first, 16);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _map.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(64)));
  }

  String _err(Object e) {
    final raw = e.toString().toLowerCase();
    final friendly = friendlyApiError(
      classifyTransportError(e),
      l10n: AppLocalizations.of(context),
      langCode: Localizations.localeOf(context).languageCode,
    );
    final both = '$raw ${friendly.toLowerCase()}';
    if (both.contains('cannot ') ||
        both.contains('/v1/') ||
        both.contains('not found') ||
        both.contains('404') ||
        both.contains('statuscode')) {
      return obicPhrase(
        context,
        ar: 'تعذّر بدء الموقع المباشر. حاول مرة أخرى.',
        en: "Couldn't start live location, please try again",
        zh: '无法开始共享位置，请重试。',
      );
    }
    return friendly;
  }

  String _away(LiveShare row) {
    final me = widget.authController.user?.id;
    final mine = _shares.where((item) => item.userId == me);
    if (mine.isEmpty || row.userId == me) return '';
    final meters = _distance.as(
      LengthUnit.Meter,
      LatLng(mine.first.lat, mine.first.lng),
      LatLng(row.lat, row.lng),
    );
    if (meters >= 1000) {
      final km = (meters / 1000).toStringAsFixed(1);
      return obicPhrase(context, ar: '$km كم', en: '$km km', zh: '$km 公里');
    }
    final m = meters.round();
    return obicPhrase(context, ar: '$m م', en: '$m m', zh: '$m 米');
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.authController.user?.id;
    final center = _shares.isEmpty
        ? const LatLng(29.3, 120.07)
        : LatLng(_shares.first.lat, _shares.first.lng);
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.arrow_forward_ios
                : Icons.arrow_back_ios_new,
            color: ObicColors.inkOf(context),
            size: 20,
          ),
        ),
        title: Text(
          obicPhrase(context, ar: 'موقع مباشر', en: 'Live location', zh: '共享实时位置'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ObicColors.inkOf(context),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_banner != null)
            Material(
              color: ObicColors.surfaceOf(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: ObicColors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _banner!,
                        style: TextStyle(color: ObicColors.inkOf(context), fontSize: 13),
                      ),
                    ),
                    if (_needsSettings)
                      TextButton(
                        onPressed: openAppSettings,
                        child: Text(
                          obicPhrase(context, ar: 'الإعدادات', en: 'Settings', zh: '设置'),
                        ),
                      )
                    else if (_startFailed)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _startFailed = false;
                            _banner = null;
                            _sentStart = false;
                          });
                          unawaited(_begin());
                        },
                        child: Text(
                          obicPhrase(context, ar: 'إعادة المحاولة', en: 'Retry', zh: '重试'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ObicMapView(
              mapController: _map,
              initialCenter: center,
              preferChina: widget.preferChina,
              children: [
                MarkerLayer(
                  markers: [
                    for (final row in _shares)
                      Marker(
                        point: LatLng(row.lat, row.lng),
                        width: 64,
                        height: 78,
                        child: Column(
                          children: [
                            MomentAvatar(
                              name: row.name,
                              avatarUrl: row.avatarUrl,
                              size: 40,
                              borderRadius: 20,
                            ),
                            Text(
                              _away(row),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: [
                                  Shadow(blurRadius: 3, color: Colors.black),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => unawaited(_centreMe()),
                          icon: const Icon(Icons.my_location, size: 18),
                          label: Text(
                            obicPhrase(context, ar: 'موقعي', en: 'Centre on me', zh: '回到我'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showAll,
                          icon: const Icon(Icons.groups_outlined, size: 18),
                          label: Text(
                            obicPhrase(context, ar: 'الكل', en: 'Show everyone', zh: '所有人'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_sharing || _shares.any((row) => row.userId == me))
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _stop,
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD92D20)),
                        child: Text(
                          obicPhrase(
                            context,
                            ar: 'إيقاف المشاركة',
                            en: 'Stop sharing',
                            zh: '停止共享',
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _join,
                        style: FilledButton.styleFrom(backgroundColor: ObicColors.blue),
                        child: Text(
                          obicPhrase(
                            context,
                            ar: 'مشاركة الموقع المباشر',
                            en: 'Share live location',
                            zh: '共享实时位置',
                          ),
                        ),
                      ),
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
