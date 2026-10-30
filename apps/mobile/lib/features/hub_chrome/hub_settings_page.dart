// Made by Dr Ali
// Hub settings: language follow app, units, city, notifies, cache, privacy, reset.

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_back_button.dart';
import '../auth/auth_controller.dart';
import '../home/home_service_layout.dart';
import 'hub_id.dart';
import 'hub_prefs.dart';
import 'hub_strings.dart';

class HubSettingsPage extends StatefulWidget {
  const HubSettingsPage({
    super.key,
    required this.hub,
    required this.langCode,
    this.authController,
    this.cityChoices = const [],
  });

  final ObicHubId hub;
  final String langCode;
  final AuthController? authController;
  final List<String> cityChoices;

  @override
  State<HubSettingsPage> createState() => _HubSettingsPageState();
}

class _HubSettingsPageState extends State<HubSettingsPage> {
  late final HubPrefs _prefs = HubPrefs(widget.hub);
  late final HubChromeStrings s =
      HubChromeStrings(widget.langCode, widget.hub);

  HubDistanceUnit _unit = HubDistanceUnit.km;
  String? _city;
  bool _deals = true;
  bool _orders = true;
  String _dietary = '';
  String _traveler = '';
  String _currency = 'CNY';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final unit = await _prefs.distanceUnit();
    final city = await _prefs.defaultCity();
    final deals = await _prefs.notifyDeals();
    final orders = await _prefs.notifyOrders();
    final dietary = await _prefs.dietaryNotes() ?? '';
    final traveler = await _prefs.defaultTraveler() ?? '';
    final currency = await _prefs.currencyDisplay();
    if (!mounted) return;
    setState(() {
      _unit = unit;
      _city = city;
      _deals = deals;
      _orders = orders;
      _dietary = dietary;
      _traveler = traveler;
      _currency = currency;
      _loading = false;
    });
  }

  Future<void> _clearCache() async {
    await _prefs.clearCache();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.cacheCleared)),
    );
  }

  Future<void> _openPrivacy() async {
    // Deep-link to OS location / app settings.
    final opened = await Geolocator.openAppSettings();
    if (!opened) {
      await openAppSettings();
    }
  }

  Future<void> _resetFavorites() async {
    await _prefs.resetHubFavorites();
    final slug = widget.hub.homeFavoriteSlug;
    final auth = widget.authController;
    if (slug != null && auth != null) {
      final uid = auth.user?.id ?? '';
      final store = HomeServiceLayoutStore(userId: uid);
      final layout = await store.loadLocal();
      if (layout.favorites.contains(slug)) {
        final next = layout.copyWith(
          favorites: {...layout.favorites}..remove(slug),
        );
        await store.saveLocal(next);
        final token = await auth.accessToken();
        if (token != null && token.isNotEmpty) {
          await store.save(next, accessToken: token);
        }
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.resetDone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        leading: const ObicBackButton(),
        title: Text(s.settingsTitle),
        backgroundColor: ObicColors.surfaceOf(context),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.languageFollowsApp),
                  subtitle: Text(
                    widget.langCode.toUpperCase(),
                    style: TextStyle(color: ObicColors.mutedOf(context)),
                  ),
                  leading: const Icon(Icons.translate_rounded),
                ),
                const Divider(),
                Text(
                  s.distanceUnit,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ObicColors.titleOf(context),
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<HubDistanceUnit>(
                  segments: [
                    ButtonSegment(
                      value: HubDistanceUnit.km,
                      label: Text(s.unitKm),
                    ),
                    ButtonSegment(
                      value: HubDistanceUnit.mi,
                      label: Text(s.unitMi),
                    ),
                  ],
                  selected: {_unit},
                  onSelectionChanged: (v) async {
                    final u = v.first;
                    setState(() => _unit = u);
                    await _prefs.setDistanceUnit(u);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  s.defaultCity,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ObicColors.titleOf(context),
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.cityChoices.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in widget.cityChoices)
                        ChoiceChip(
                          label: Text(c),
                          selected: _city == c,
                          onSelected: (sel) async {
                            final next = sel ? c : null;
                            setState(() => _city = next);
                            await _prefs.setDefaultCity(next);
                          },
                        ),
                    ],
                  )
                else
                  TextFormField(
                    initialValue: _city ?? '',
                    decoration: InputDecoration(
                      hintText: s.defaultCity,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) async {
                      _city = v.trim().isEmpty ? null : v.trim();
                      await _prefs.setDefaultCity(_city);
                    },
                  ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.notifyDeals),
                  value: _deals,
                  onChanged: (v) async {
                    setState(() => _deals = v);
                    await _prefs.setNotifyDeals(v);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.notifyOrders),
                  value: _orders,
                  onChanged: (v) async {
                    setState(() => _orders = v);
                    await _prefs.setNotifyOrders(v);
                  },
                ),
                if (widget.hub == ObicHubId.daily) ...[
                  const SizedBox(height: 8),
                  Text(
                    s.dietaryNotes,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ObicColors.titleOf(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _dietary,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) async {
                      _dietary = v;
                      await _prefs.setDietaryNotes(v);
                    },
                  ),
                ],
                if (widget.hub == ObicHubId.travel) ...[
                  const SizedBox(height: 8),
                  Text(
                    s.defaultTraveler,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ObicColors.titleOf(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _traveler,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) async {
                      _traveler = v;
                      await _prefs.setDefaultTraveler(v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.currencyDisplay,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ObicColors.titleOf(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in const ['CNY', 'USD', 'SAR', 'AED'])
                        ChoiceChip(
                          label: Text(c),
                          selected: _currency == c,
                          onSelected: (_) async {
                            setState(() => _currency = c);
                            await _prefs.setCurrencyDisplay(c);
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: Text(s.clearCache),
                  onTap: _clearCache,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(s.privacyLocation),
                  subtitle: Text(s.openSystemSettings),
                  onTap: _openPrivacy,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restart_alt_rounded),
                  title: Text(s.resetFavorites),
                  onTap: _resetFavorites,
                ),
              ],
            ),
    );
  }
}

Future<void> openHubSettings({
  required BuildContext context,
  required ObicHubId hub,
  required String langCode,
  AuthController? authController,
  List<String> cityChoices = const [],
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => HubSettingsPage(
        hub: hub,
        langCode: langCode,
        authController: authController,
        cityChoices: cityChoices,
      ),
    ),
  );
}
