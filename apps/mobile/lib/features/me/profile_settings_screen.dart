// Made by Dr Ali
// Profile — WeChat-style rows: photo, name, gender, region, mobile, ID, QR, What's Up.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;

import '../../core/api_errors.dart';
import '../../core/obic_bidi.dart';
import '../../core/profile_locations.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import '../friends/add_friend_screen.dart';
import '../moments/moment_avatar.dart';
import '../social/social_api.dart';
import 'addresses_screen.dart';
import 'settings_widgets.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({
    super.key,
    required this.authController,
    this.focusField,
  });

  final AuthController authController;

  /// Optional: `whatsUp` | `obicId` | `name` | `gender` | `region`
  final String? focusField;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _api = SocialApi();
  late String _name;
  late String _phone;
  late String _obicId;
  String? _countryCode;
  String? _city;
  String? _gender;
  late String _whatsUp;
  bool _locating = false;
  bool _saving = false;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _hydrateFromUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focus = widget.focusField;
      if (focus == 'whatsUp') {
        unawaited(_editWhatsUp());
      } else if (focus == 'obicId') {
        unawaited(_editObicId());
      } else if (focus == 'name') {
        unawaited(_editName());
      } else if (focus == 'gender') {
        unawaited(_pickGender());
      } else if (focus == 'region') {
        unawaited(_pickCountry());
      }
    });
  }

  void _hydrateFromUser() {
    final u = widget.authController.user;
    _name = u?.name ?? '';
    _phone = u?.phone ?? '';
    _obicId = u?.obicId ?? '';
    _gender = u?.gender;
    _whatsUp = u?.whatsUp ?? '';
    _countryCode =
        matchCountryCode(countryName: u?.country) ??
        (u?.country?.trim().length == 2
            ? u!.country!.trim().toUpperCase()
            : null);
    _city = u?.city;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return phone;
    final head = digits.substring(0, 3);
    final tail = digits.substring(digits.length - 2);
    return '$head${'*' * (digits.length - 5)}$tail';
  }

  String _genderLabel(AppLocalizations l10n, String? g) {
    switch (g) {
      case 'male':
        return l10n.profileGenderMale;
      case 'female':
        return l10n.profileGenderFemale;
      case 'other':
        return l10n.profileGenderOther;
      default:
        return '';
    }
  }

  String _regionLabel(String lang) {
    final country = findCountryByCode(_countryCode);
    final parts = <String>[
      if (country != null) country.label(lang),
      if (_city != null && _city!.isNotEmpty) _city!,
    ];
    return parts.join(' ');
  }

  Future<void> _copyObicId(String id) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: id));
    if (!mounted) return;
    _toast(l10n.profileObicIdCopied);
  }

  Future<void> _openMyQr() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddFriendScreen(
          authController: widget.authController,
          demoInitialTab: 1,
        ),
      ),
    );
  }

  Future<void> _changeAvatar() async {
    final shot = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (shot == null || !mounted) return;
    setState(() => _uploadingAvatar = true);
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
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      _toast(l10n.errorUploadFailed);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _editName() async {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: _name);
    final ok = await _showEditSheet(
      title: l10n.profileName,
      child: TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: 120,
        decoration: InputDecoration(
          filled: true,
          fillColor: ObicColors.surfaceRaisedOf(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
    if (ok == true) {
      setState(() => _name = ctrl.text.trim());
      await _save(silent: true);
    }
    ctrl.dispose();
  }

  Future<void> _editWhatsUp() async {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: _whatsUp);
    final ok = await _showEditSheet(
      title: l10n.profileWhatsUp,
      hint: l10n.profileWhatsUpHint,
      child: TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: 120,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: l10n.profileWhatsUpHint,
          filled: true,
          fillColor: ObicColors.surfaceRaisedOf(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
    if (ok == true) {
      setState(() => _whatsUp = ctrl.text.trim());
      await _save(silent: true);
    }
    ctrl.dispose();
  }

  Future<void> _pickGender() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ObicColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Text(
                l10n.profileGender,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ObicColors.inkOf(ctx),
                ),
              ),
              ListTile(
                title: Text(l10n.profileGenderMale),
                onTap: () => Navigator.pop(ctx, 'male'),
              ),
              ListTile(
                title: Text(l10n.profileGenderFemale),
                onTap: () => Navigator.pop(ctx, 'female'),
              ),
              ListTile(
                title: Text(l10n.profileGenderOther),
                onTap: () => Navigator.pop(ctx, 'other'),
              ),
              ListTile(
                title: Text(l10n.profileGenderUnset),
                onTap: () => Navigator.pop(ctx, ''),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _gender = picked.isEmpty ? null : picked);
    await _save(silent: true);
  }

  Future<void> _editObicId() async {
    final l10n = AppLocalizations.of(context);
    final user = widget.authController.user;
    final canChange = user?.canChangeObicId ?? true;
    final hasId = (user?.obicId ?? '').isNotEmpty;
    if (hasId && !canChange) {
      final when = user?.obicIdNextChangeAt
          ?.toLocal()
          .toString()
          .split(' ')
          .first;
      _toast(
        when != null
            ? l10n.profileObicIdCooldownData(when)
            : l10n.profileObicIdCooldownHint,
      );
      return;
    }

    final ctrl = TextEditingController(text: _obicId);
    final ok = await _showEditSheet(
      title: hasId ? l10n.profileChangeObicId : l10n.profileSetObicId,
      hint: hasId ? l10n.profileObicIdYearHint : l10n.profileObicIdFirstHint,
      child: TextField(
        controller: ctrl,
        autofocus: true,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
          LengthLimitingTextInputFormatter(20),
        ],
        decoration: InputDecoration(
          hintText: l10n.profileObicIdHint,
          filled: true,
          fillColor: ObicColors.surfaceRaisedOf(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
    if (ok == true) {
      setState(() => _obicId = ctrl.text.trim());
      await _save(silent: true);
    }
    ctrl.dispose();
  }

  Future<bool?> _showEditSheet({
    required String title,
    String? hint,
    required Widget child,
  }) {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ObicColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ObicColors.lineOf(ctx),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ObicColors.inkOf(ctx),
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 8),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 13,
                    color: ObicColors.mutedOf(ctx),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              child,
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: ObicColors.navy,
                  minimumSize: const Size.fromHeight(46),
                ),
                child: Text(l10n.profileSave),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickCountry() async {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final picked = await showModalBottomSheet<ProfileCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ObicColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SearchPickSheet<ProfileCountry>(
        title: l10n.profilePickCountry,
        searchHint: l10n.profileSearchCountry,
        items: kProfileCountries,
        labelOf: (c) => '${c.label(lang)} (${c.code})',
        filter: (c, q) {
          final l = c.label(lang).toLowerCase();
          return l.contains(q) || c.code.toLowerCase().contains(q);
        },
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _countryCode = picked.code;
      final cities = citiesForCountry(picked.code);
      if (_city == null || !cities.contains(_city)) {
        _city = cities.isNotEmpty ? cities.first : null;
      }
    });
    await _pickCity(autoSave: true);
  }

  Future<void> _pickCity({bool autoSave = false}) async {
    final l10n = AppLocalizations.of(context);
    final cities = citiesForCountry(_countryCode);
    if (cities.isEmpty) {
      _toast(l10n.profilePickCountry);
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ObicColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SearchPickSheet<String>(
        title: l10n.profilePickCity,
        searchHint: l10n.profileSearchCity,
        items: cities,
        labelOf: (c) => c,
        filter: (c, q) => c.toLowerCase().contains(q),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _city = picked);
    if (autoSave) await _save(silent: true);
  }

  Future<void> _useCurrentLocation() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _locating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _toast(l10n.profileLocationFailed);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _toast(l10n.profileLocationFailed);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final places = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (places.isEmpty) {
        _toast(l10n.profileLocationFailed);
        return;
      }
      final place = places.first;
      final code = matchCountryCode(
        isoCountryCode: place.isoCountryCode,
        countryName: place.country,
      );
      final city = matchCityName(
        countryCode: code,
        locality: place.locality,
        subAdministrativeArea: place.subAdministrativeArea,
        administrativeArea: place.administrativeArea,
      );
      if (!mounted) return;
      setState(() {
        if (code != null) _countryCode = code;
        if (city != null) _city = city;
      });
      await _save(silent: true);
    } catch (_) {
      if (mounted) _toast(l10n.profileLocationFailed);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save({bool silent = false}) async {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final token = await widget.authController.ensureAccessToken();
    if (token == null || !mounted) return;
    final user = widget.authController.user;
    final nextId = _obicId.trim();
    final prevId = (user?.obicId ?? '').trim();
    final idChanged =
        nextId.isNotEmpty && nextId.toLowerCase() != prevId.toLowerCase();

    if (idChanged && user != null && !user.canChangeObicId) {
      final when = user.obicIdNextChangeAt
          ?.toLocal()
          .toString()
          .split(' ')
          .first;
      _toast(
        when != null
            ? l10n.profileObicIdCooldownData(when)
            : l10n.profileObicIdCooldownHint,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await AuthApi().updateMe(
        accessToken: token,
        name: _name.trim(),
        city: _city ?? '',
        country: _countryCode ?? '',
        gender: _gender ?? '',
        whatsUp: _whatsUp,
        obicId: nextId.isEmpty ? null : nextId,
      );
      await widget.authController.applyUser(updated);
      if (!mounted) return;
      _hydrateFromUser();
      setState(() {});
      if (!silent) _toast(l10n.profileSaved);
    } catch (e) {
      if (!mounted) return;
      _toast(friendlyApiError(e, l10n: l10n, langCode: lang));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final user = widget.authController.user;
    final displayId = _obicId.trim().isNotEmpty
        ? _obicId.trim()
        : (user?.obicId ?? '');
    final hasId = displayId.isNotEmpty;
    final genderText = _genderLabel(l10n, _gender);
    final region = _regionLabel(lang);
    final whatsUp = _whatsUp.trim();
    final muted = ObicColors.mutedOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        title: Text(l10n.settingsProfile),
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          SettingsGroup(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: Text(
                  l10n.profilePhoto,
                  style: TextStyle(
                    fontSize: 16,
                    color: ObicColors.inkOf(context),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        MomentAvatar(
                          name: _name.isNotEmpty ? _name : (user?.name ?? '?'),
                          avatarUrl: user?.avatarUrl,
                          size: 56,
                          borderRadius: 6,
                        ),
                        if (_uploadingAvatar)
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Icon(Icons.chevron_right_rounded, color: muted, size: 20),
                  ],
                ),
                onTap: _uploadingAvatar ? null : _changeAvatar,
              ),
              SettingsNavTile(
                title: l10n.profileName,
                value: _name,
                onTap: _editName,
              ),
              SettingsNavTile(
                title: l10n.profileGender,
                value: genderText.isEmpty ? null : genderText,
                onTap: _pickGender,
              ),
              SettingsNavTile(
                title: l10n.profileRegion,
                value: region.isEmpty ? null : region,
                onTap: _pickCountry,
              ),
              SettingsNavTile(
                title: l10n.profileMobile,
                identifierValue: true,
                value: _maskPhone(_phone.isNotEmpty ? _phone : user?.phone),
                onTap: () {
                  // China mobile changes go through OTP verification gates.
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                title: rtl && hasId
                    ? Row(
                        children: [
                          Text(
                            l10n.profileId,
                            style: TextStyle(
                              fontSize: 16,
                              color: ObicColors.inkOf(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: ObicIdentifierText(
                              displayId,
                              style: TextStyle(fontSize: 13, color: muted),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        l10n.profileId,
                        style: TextStyle(
                          fontSize: 16,
                          color: ObicColors.inkOf(context),
                        ),
                      ),
                trailing: rtl && hasId
                    ? Icon(Icons.chevron_right_rounded, color: muted, size: 20)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasId)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 140),
                              child: ObicIdentifierText(
                                displayId,
                                style: TextStyle(fontSize: 13, color: muted),
                              ),
                            ),
                          if (!hasId)
                            Text(
                              l10n.meObicIdUnset,
                              style: TextStyle(fontSize: 13, color: muted),
                            ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: muted,
                            size: 20,
                          ),
                        ],
                      ),
                onTap: _editObicId,
                onLongPress: hasId ? () => _copyObicId(displayId) : null,
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                title: Text(
                  l10n.profileMyQr,
                  style: TextStyle(
                    fontSize: 16,
                    color: ObicColors.inkOf(context),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_2_rounded, color: muted, size: 22),
                    Icon(Icons.chevron_right_rounded, color: muted, size: 20),
                  ],
                ),
                onTap: _openMyQr,
              ),
              SettingsNavTile(
                title: l10n.profileWhatsUp,
                value: whatsUp.isEmpty
                    ? null
                    : (whatsUp.length > 28
                          ? '${whatsUp.substring(0, 28)}…'
                          : whatsUp),
                onTap: _editWhatsUp,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SettingsGroup(
            children: [
              ListTile(
                title: Text(
                  l10n.profileUseCurrentLocation,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ObicColors.blue,
                  ),
                ),
                leading: _locating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.my_location, color: ObicColors.blue),
                onTap: _locating ? null : _useCurrentLocation,
              ),
              SettingsNavTile(
                title: l10n.addressesTitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AddressesScreen(
                        authController: widget.authController,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SearchPickSheet<T> extends StatefulWidget {
  const _SearchPickSheet({
    required this.title,
    required this.searchHint,
    required this.items,
    required this.labelOf,
    required this.filter,
  });

  final String title;
  final String searchHint;
  final List<T> items;
  final String Function(T) labelOf;
  final bool Function(T, String) filter;

  @override
  State<_SearchPickSheet<T>> createState() => _SearchPickSheetState<T>();
}

class _SearchPickSheetState<T> extends State<_SearchPickSheet<T>> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _q.trim().isEmpty
        ? widget.items
        : widget.items
              .where((i) => widget.filter(i, _q.trim().toLowerCase()))
              .toList();
    final h = MediaQuery.sizeOf(context).height * 0.65;
    return SizedBox(
      height: h,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: ObicColors.lineOf(context),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ObicColors.inkOf(context),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: ObicColors.surfaceRaisedOf(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item = filtered[i];
                return ListTile(
                  title: Text(
                    widget.labelOf(item),
                    style: TextStyle(color: ObicColors.inkOf(context)),
                  ),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
