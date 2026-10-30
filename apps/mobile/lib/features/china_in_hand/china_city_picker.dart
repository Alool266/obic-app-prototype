// Made by Dr Ali
// Searchable China city picker (AR + ZH + Pinyin) + GPS nearest city.

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_back_button.dart';
import 'china_cities.dart';
import 'china_city_store.dart';
import 'china_in_hand_strings.dart';
import 'china_visit_places.dart';

Future<ChinaCity?> showChinaCityPicker({
  required BuildContext context,
  required String langCode,
  ChinaCity? selected,
}) {
  return Navigator.of(context).push<ChinaCity>(
    MaterialPageRoute(
      builder: (_) => ChinaCityPickerPage(
        langCode: langCode,
        selected: selected,
      ),
    ),
  );
}

class ChinaCityPickerPage extends StatefulWidget {
  const ChinaCityPickerPage({
    super.key,
    required this.langCode,
    this.selected,
  });

  final String langCode;
  final ChinaCity? selected;

  @override
  State<ChinaCityPickerPage> createState() => _ChinaCityPickerPageState();
}

class _ChinaCityPickerPageState extends State<ChinaCityPickerPage> {
  final _search = TextEditingController();
  late final ChinaInHandStrings s = ChinaInHandStrings(widget.langCode);
  List<ChinaCity> _all = const [];
  bool _loading = true;
  bool _gpsBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    final list = await ChinaCitiesCatalog.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  Future<void> _useGps() async {
    if (_gpsBusy) return;
    setState(() => _gpsBusy = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.visitGpsOff)),
        );
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.visitGpsDenied)),
        );
        if (perm == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      await ChinaCitiesCatalog.instance.ensureLoaded();
      final city = isRoughlyInOrNearChina(pos.latitude, pos.longitude)
          ? ChinaCitiesCatalog.instance.nearestTo(pos.latitude, pos.longitude)
          : ChinaCitiesCatalog.instance.yiwuFallback;
      await ChinaCityStore.instance.saveCityId(city.id);
      if (!mounted) return;
      Navigator.of(context).pop(city);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.visitGpsFail)),
      );
    } finally {
      if (mounted) setState(() => _gpsBusy = false);
    }
  }

  Future<void> _select(ChinaCity c) async {
    await ChinaCityStore.instance.saveCityId(c.id);
    if (!mounted) return;
    Navigator.of(context).pop(c);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text;
    final hits = _all.where((c) => c.matches(q)).toList();
    final rtl = widget.langCode.startsWith('ar');

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        leading: const ObicBackButton(),
        title: Text(s.cityPickerTitle),
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: s.visitRefresh,
            onPressed: _gpsBusy ? null : _useGps,
            icon: _gpsBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, color: Color(0xFFC9A227)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: s.cityPickerHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: ObicColors.surfaceOf(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ObicColors.navy,
                  foregroundColor: const Color(0xFFC9A227),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _gpsBusy ? null : _useGps,
                icon: const Icon(Icons.gps_fixed_rounded),
                label: Text(
                  s.cityUseGps,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.separated(
                itemCount: hits.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: ObicColors.mutedOf(context).withValues(alpha: 0.2),
                ),
                itemBuilder: (context, i) {
                  final c = hits[i];
                  final selected = widget.selected?.id == c.id;
                  return ListTile(
                    selected: selected,
                    leading: CircleAvatar(
                      backgroundColor: ObicColors.navy,
                      child: Text(
                        c.nameZh.isNotEmpty ? c.nameZh.substring(0, 1) : '?',
                        style: const TextStyle(
                          color: Color(0xFFC9A227),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Text(
                      c.name(widget.langCode),
                      style: TextStyle(
                        color: ObicColors.inkOf(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${c.nameZh} · ${c.nameEn} · ${c.pinyin}',
                      style: TextStyle(
                        color: ObicColors.mutedOf(context),
                        fontSize: 12,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFFC9A227),
                          )
                        : null,
                    onTap: () => _select(c),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
