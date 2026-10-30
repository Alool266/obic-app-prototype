// Made by Dr Ali
// Customer browse of staff-published hotel / flight offers.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/media_url.dart';
import '../../widgets/obic_cached_image.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../me/addresses_screen.dart';
import '../services/service_catalog.dart';
import '../services/service_request_page.dart';
import 'offers_api.dart';

List<Map<String, dynamic>> _visualMedia(dynamic raw) {
  Iterable<dynamic> list = const [];
  if (raw is List) {
    list = raw;
  } else if (raw is Map && raw['media'] is List) {
    list = raw['media'] as List;
  }
  return list
      .whereType<Map>()
      .map((m) => Map<String, dynamic>.from(m))
      .where((m) {
        final kind = '${m['kind'] ?? m['type'] ?? ''}'.toLowerCase();
        final url = m['url'];
        final isVisual = kind == 'image' ||
            kind == 'video' ||
            kind == 'photo' ||
            kind == 'img';
        return isVisual && url is String && url.isNotEmpty;
      })
      .map((m) {
        final kind = '${m['kind'] ?? m['type'] ?? 'image'}'.toLowerCase();
        m['kind'] = (kind == 'video') ? 'video' : 'image';
        return m;
      })
      .toList();
}

List<Map<String, dynamic>> _offerMedia(Map<String, dynamic> o) {
  final fromField = _visualMedia(o['media']);
  if (fromField.isNotEmpty) return fromField;
  final attrs = o['attributes'];
  if (attrs is Map) return _visualMedia(attrs['media'] ?? attrs);
  return [];
}

Map<String, dynamic>? _coverMedia(Map<String, dynamic> o) {
  final media = _offerMedia(o);
  for (final m in media) {
    if (m['kind'] == 'image') return m;
  }
  return media.isEmpty ? null : media.first;
}

bool _isFlight(String kind) => kind == 'flights';

bool _isRestaurant(String kind) => kind == 'restaurants';

/// Maps catalog navigation to staff offer kind (hotels, flights, restaurants).
String? offerBrowseKind({required String parentSlug, String? subId}) {
  if (subId == 'hotels') return 'hotels';
  if (subId == 'flights') return 'flights';
  if (parentSlug == 'food') return 'restaurants';
  return null;
}

List<String> _offerTripChipLabels(
  Map<String, dynamic> offer,
  bool arabic,
  String kind,
) {
  final attrs = offer['attributes'];
  if (attrs is! Map) return [];
  final a = Map<String, dynamic>.from(attrs);
  final flight = _isFlight(kind);
  final restaurant = _isRestaurant(kind);
  final chips = <String>[];
  if (restaurant) {
    final rating = a['rating'];
    if (rating is num && rating > 0) chips.add('${rating.toStringAsFixed(1)}★');
    final reviews = a['reviewCount'];
    if (reviews is num && reviews > 0) {
      chips.add(arabic ? '$reviews تقييم' : '$reviews reviews');
    }
    final delivery = a['deliveryMins'] as String?;
    if (delivery != null && delivery.isNotEmpty) chips.add(delivery);
    final cuisine = a['cuisineLabel'] as String? ?? a['cuisine'] as String?;
    if (cuisine != null && cuisine.isNotEmpty) chips.add(cuisine);
    final minOrder = a['minOrder'];
    if (minOrder is num && minOrder > 0) {
      chips.add(arabic ? 'حد أدنى \$$minOrder' : 'Min \$$minOrder');
    }
    final tags = a['tags'];
    if (tags is List) {
      for (final t in tags.take(2)) {
        if (t is String && t.isNotEmpty) chips.add(t);
      }
    }
  } else if (flight) {
    final airline = a['airline'] as String?;
    if (airline != null && airline.isNotEmpty) chips.add(airline);
    final cabin = a['cabin'] as String?;
    if (cabin != null && cabin.isNotEmpty) chips.add(cabin);
    final stops = a['stops'];
    if (stops == 0) {
      chips.add(arabic ? 'مباشر' : 'Direct');
    } else if (stops is num && stops > 0) {
      chips.add(arabic ? '$stops توقف' : '$stops stop${stops == 1 ? '' : 's'}');
    }
    final duration = a['duration'] as String?;
    if (duration != null && duration.isNotEmpty) chips.add(duration);
    final baggage = a['baggage'] as String?;
    if (baggage != null && baggage.isNotEmpty) chips.add(baggage);
  } else {
    final stars = a['starRating'];
    if (stars is num && stars > 0) chips.add('${stars.toInt()}★');
    final room = a['roomType'] as String?;
    if (room != null && room.isNotEmpty) chips.add(room);
    if (a['breakfast'] == true) chips.add(arabic ? 'إفطار' : 'Breakfast');
    if (a['wifi'] == true) chips.add('Wi‑Fi');
    if (a['pool'] == true) chips.add(arabic ? 'مسبح' : 'Pool');
    final nights = a['nights'];
    if (nights is num && nights > 0) {
      chips.add(arabic ? '$nights ليالي' : '$nights nights');
    }
  }
  return chips.take(5).toList();
}

class _OfferTripChipRow extends StatelessWidget {
  const _OfferTripChipRow({
    required this.labels,
    this.compact = false,
  });

  final List<String> labels;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: compact ? 8 : 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: labels
            .map(
              (label) => Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 7 : 9,
                  vertical: compact ? 3 : 5,
                ),
                decoration: BoxDecoration(
                  color: ObicColors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ObicColors.blue.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: ObicColors.blueDeep,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class OffersSection extends StatefulWidget {
  const OffersSection({
    super.key,
    required this.kind,
    required this.arabic,
    required this.authController,
    required this.service,
    this.cuisineFilter,
  });

  final String kind;
  final bool arabic;
  final AuthController authController;
  final ObicService service;
  /// When set (e.g. food sub id `arabic`), only show matching demo vendors.
  final String? cuisineFilter;

  @override
  State<OffersSection> createState() => _OffersSectionState();
}

const String _kDemoSearchQ =
    String.fromEnvironment('DEMO_SEARCH_Q', defaultValue: '');
const String _kDemoSearchCity =
    String.fromEnvironment('DEMO_SEARCH_CITY', defaultValue: '');

class _OffersSectionState extends State<OffersSection> {
  final _api = OffersApi();
  final _searchCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _hasFilters = false;

  @override
  void initState() {
    super.initState();
    if (_kDemoSearchQ.isNotEmpty) _searchCtrl.text = _kDemoSearchQ;
    if (_kDemoSearchCity.isNotEmpty) _cityCtrl.text = _kDemoSearchCity;
    _searchCtrl.addListener(_scheduleLoad);
    _cityCtrl.addListener(_scheduleLoad);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _scheduleLoad() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), _load);
  }

  void _clearFilters() {
    _searchCtrl.clear();
    _cityCtrl.clear();
    _load();
  }

  Future<void> _load() async {
    final q = _searchCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    setState(() {
      _loading = true;
      _hasFilters = q.isNotEmpty || city.isNotEmpty;
    });
    try {
      final raw = await _api.listPublished(
        kind: widget.kind,
        q: q.isEmpty ? null : q,
        city: city.isEmpty ? null : city,
      );
      final cuisine = widget.cuisineFilter?.trim().toLowerCase();
      final items = cuisine == null || cuisine.isEmpty
          ? raw
          : raw.where((o) {
              final attrs = o['attributes'];
              if (attrs is! Map) return false;
              final c = '${attrs['cuisine'] ?? ''}'.toLowerCase();
              return c == cuisine;
            }).toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.arabic;
    final flight = _isFlight(widget.kind);
    final restaurant = _isRestaurant(widget.kind);
    final sectionTitle = restaurant
        ? (ar ? 'المطاعم والتوصيل' : 'Restaurants & delivery')
        : (ar ? 'البحث في العروض' : 'Search offers');
    final listTitle = restaurant
        ? (ar ? 'مطاعم قريبة' : 'Nearby restaurants')
        : (ar ? 'العروض المتاحة' : 'Available offers');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ObicColors.titleOf(context),
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        _OffersSearchBar(
          arabic: ar,
          flight: flight,
          restaurant: restaurant,
          searchCtrl: _searchCtrl,
          cityCtrl: _cityCtrl,
          hasFilters: _hasFilters,
          onClear: _clearFilters,
          onSubmit: _load,
        ),
        const SizedBox(height: 16),
        Text(
          listTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: ObicColors.titleOf(context),
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              _hasFilters
                  ? (ar
                      ? 'لا نتائج لهذا البحث — جرّب كلمة أخرى أو مدينة مختلفة.'
                      : 'No results for this search — try another keyword or city.')
                  : restaurant
                      ? (ar
                          ? 'لا مطاعم منشورة حالياً — سيضيفها شركاء OBIC قريباً.'
                          : 'No restaurants yet — OBIC vendor partners will join soon.')
                      : (ar
                          ? 'لا عروض منشورة حالياً — سيضيفها فريق OBIC قريباً.'
                          : 'No published offers yet — OBIC staff will add them soon.'),
              style: TextStyle(color: ObicColors.mutedOf(context)),
            ),
          )
        else ...[
          if (_hasFilters)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                ar
                    ? '${_items.length} ${_items.length == 1 ? 'نتيجة' : 'نتائج'}'
                    : '${_items.length} result${_items.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: ObicColors.mutedOf(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ..._items.map((o) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _OfferListCard(
              offer: o,
              kind: widget.kind,
              arabic: ar,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OfferDetailPage(
                      offerId: o['id'] as String,
                      arabic: ar,
                      authController: widget.authController,
                      service: widget.service,
                      preview: o,
                    ),
                  ),
                );
              },
            ),
          );
          }),
        ],
      ],
    );
  }
}

class _OffersSearchBar extends StatefulWidget {
  const _OffersSearchBar({
    required this.arabic,
    required this.flight,
    required this.restaurant,
    required this.searchCtrl,
    required this.cityCtrl,
    required this.hasFilters,
    required this.onClear,
    required this.onSubmit,
  });

  final bool arabic;
  final bool flight;
  final bool restaurant;
  final TextEditingController searchCtrl;
  final TextEditingController cityCtrl;
  final bool hasFilters;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  @override
  State<_OffersSearchBar> createState() => _OffersSearchBarState();
}

class _OffersSearchBarState extends State<_OffersSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.searchCtrl.addListener(_rebuild);
    widget.cityCtrl.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.searchCtrl.removeListener(_rebuild);
    widget.cityCtrl.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final arabic = widget.arabic;
    final flight = widget.flight;
    final restaurant = widget.restaurant;
    final searchHint = restaurant
        ? (arabic
            ? 'ابحث عن مطعم، طبق، مأكولات…'
            : 'Search restaurant, dish, cuisine…')
        : flight
        ? (arabic ? 'ابحث عن رحلة، مسار، شركة طيران…' : 'Search route, airline, trip…')
        : (arabic ? 'ابحث عن فندق، مدينة، وصف…' : 'Search hotel, city, description…');
    final cityHint = restaurant
        ? (arabic ? 'المنطقة أو المدينة (اختياري)' : 'Area or city (optional)')
        : flight
        ? (arabic ? 'مدينة أو مطار (اختياري)' : 'City or airport (optional)')
        : (arabic ? 'المدينة (اختياري)' : 'City (optional)');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: ObicColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ObicColors.lineOf(context).withValues(alpha: 0.85)),
      ),
      child: Column(
        children: [
          TextField(
            controller: widget.searchCtrl,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => widget.onSubmit(),
            decoration: InputDecoration(
              isDense: true,
              hintText: searchHint,
              hintStyle: TextStyle(color: ObicColors.mutedOf(context), fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: ObicColors.blueDeep),
              suffixIcon: widget.searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: ObicColors.mutedOf(context),
                      onPressed: () {
                        widget.searchCtrl.clear();
                        widget.onSubmit();
                      },
                    ),
              filled: true,
              fillColor: ObicColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.cityCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => widget.onSubmit(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: cityHint,
                    hintStyle: TextStyle(color: ObicColors.mutedOf(context), fontSize: 13),
                    prefixIcon: Icon(
                      restaurant
                          ? Icons.restaurant_rounded
                          : flight
                              ? Icons.flight_land_rounded
                              : Icons.location_city_outlined,
                      color: ObicColors.mutedOf(context),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: ObicColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
                  ),
                ),
              ),
              if (widget.hasFilters) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: widget.onClear,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text(arabic ? 'مسح' : 'Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: ObicColors.blueDeep,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferListCard extends StatelessWidget {
  const _OfferListCard({
    required this.offer,
    required this.kind,
    required this.arabic,
    required this.onTap,
  });

  final Map<String, dynamic> offer;
  final String kind;
  final bool arabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = arabic
        ? (offer['titleAr'] as String? ?? '')
        : (offer['titleEn'] as String? ?? '');
    final price = arabic
        ? (offer['priceLabelAr'] as String?)
        : (offer['priceLabelEn'] as String?);
    final loc = offer['locationLabel'] as String?;
    final dates = offer['datesLabel'] as String?;
    final cover = _coverMedia(offer);
    final coverUrl = cover == null
        ? ''
        : resolveMediaUrl(cover['url'] as String?);
    final coverIsVideo = cover?['kind'] == 'video';
    final flight = _isFlight(kind);
    final restaurant = _isRestaurant(kind);
    final badge = restaurant
        ? (arabic ? 'مطعم' : 'Restaurant')
        : flight
            ? (arabic ? 'طيران' : 'Flight')
            : (arabic ? 'فندق' : 'Hotel');
    final attrs = offer['attributes'];
    final attrMap = attrs is Map ? Map<String, dynamic>.from(attrs) : null;
    final rating = attrMap?['rating'];

    return Material(
      color: ObicColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ObicColors.lineOf(context).withValues(alpha: 0.85)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverUrl.isEmpty)
                      _OfferMediaPlaceholder(
                        flight: flight,
                        restaurant: restaurant,
                        arabic: arabic,
                        compact: true,
                      )
                    else
                      _OfferNetworkImage(
                        url: coverUrl,
                        flight: flight,
                        restaurant: restaurant,
                        arabic: arabic,
                      ),
                    if (coverIsVideo)
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ObicColors.titleOf(context),
                        height: 1.25,
                        fontSize: 16,
                      ),
                    ),
                    if (restaurant && rating is num && rating > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: ObicColors.titleOf(context),
                              fontSize: 13,
                            ),
                          ),
                          if (attrMap?['reviewCount'] is num) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(${attrMap!['reviewCount']})',
                              style: TextStyle(
                                color: ObicColors.mutedOf(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (loc != null && loc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            flight
                                ? Icons.route_rounded
                                : Icons.place_outlined,
                            size: 15,
                            color: ObicColors.mutedOf(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              loc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ObicColors.mutedOf(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (dates != null && dates.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            flight
                                ? Icons.flight_takeoff_rounded
                                : Icons.event_outlined,
                            size: 15,
                            color: ObicColors.mutedOf(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dates,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ObicColors.mutedOf(context),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    _OfferTripChipRow(
                      labels: _offerTripChipLabels(offer, arabic, kind),
                      compact: true,
                    ),
                    if (price != null && price.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        price,
                        style: const TextStyle(
                          color: ObicColors.blue,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
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
    );
  }
}

class OfferDetailPage extends StatefulWidget {
  const OfferDetailPage({
    super.key,
    required this.offerId,
    required this.arabic,
    required this.authController,
    required this.service,
    this.preview,
  });

  final String offerId;
  final bool arabic;
  final AuthController authController;
  final ObicService service;
  final Map<String, dynamic>? preview;

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  final _api = OffersApi();
  Map<String, dynamic>? _offer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _offer = widget.preview;
    _load();
  }

  Future<void> _load() async {
    try {
      final o = await _api.getOne(widget.offerId);
      if (!mounted) return;
      setState(() {
        _offer = o;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _requestOffer(String title) async {
    final ar = widget.arabic;
    final ok = await requireAuth(context, widget.authController);
    if (!mounted || !ok) return;

    final kind = ( _offer?['kind'] as String?) ?? widget.service.slug;
    var prefill = ar ? 'اهتمام بعرض: $title' : 'Interested in offer: $title';

    if (_isRestaurant(kind)) {
      final address = await pickSavedAddress(
        context,
        authController: widget.authController,
      );
      if (!mounted) return;
      if (address == null) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ServiceRequestPage(
            service: widget.service,
            authController: widget.authController,
            langCode: widget.arabic ? 'ar' : 'en',
            offerId: widget.offerId,
            foodDelivery: true,
            restaurantTitle: title,
            deliveryAddress: address,
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ServiceRequestPage(
          service: widget.service,
          authController: widget.authController,
          langCode: widget.arabic ? 'ar' : 'en',
          offerId: widget.offerId,
          prefillRequirements: prefill,
        ),
      ),
    );
  }

  bool _offerRequestable(Map<String, dynamic> o) {
    if (o['isAvailable'] == true) return true;
    if (o['isSoldOut'] == true) return false;
    if (o['isExpired'] == true) return false;
    if (o['isPublished'] == false) return false;
    final exp = o['expiresAt'];
    if (exp is String && exp.isNotEmpty) {
      final dt = DateTime.tryParse(exp);
      if (dt != null && !dt.isAfter(DateTime.now())) return false;
    }
    return o['isSoldOut'] != true;
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.arabic;
    final o = _offer;
    if (_loading && o == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (o == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(ar ? 'العرض غير متاح' : 'Offer unavailable')),
      );
    }

    final kind = (o['kind'] as String?) ?? widget.service.slug;
    final flight = _isFlight(kind);
    final restaurant = _isRestaurant(kind);
    final title =
        ar ? (o['titleAr'] as String? ?? '') : (o['titleEn'] as String? ?? '');
    final body =
        ar ? (o['bodyAr'] as String? ?? '') : (o['bodyEn'] as String? ?? '');
    final price = ar
        ? (o['priceLabelAr'] as String?)
        : (o['priceLabelEn'] as String?);
    final loc = o['locationLabel'] as String?;
    final dates = o['datesLabel'] as String?;
    final media = _offerMedia(o);
    final size = MediaQuery.sizeOf(context);
    final heroH = (size.height * 0.46).clamp(340.0, 560.0);
    final canRequest = _offerRequestable(o);
    final soldOut = o['isSoldOut'] == true;
    final expired = o['isExpired'] == true;

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: heroH,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _OfferMediaCarousel(
                          media: media,
                          flight: flight,
                          restaurant: restaurant,
                          arabic: ar,
                        ),
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 88,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x00000000),
                                    Color(0x66000000),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.paddingOf(context).top + 8,
                          left: 12,
                          child: _CircleBackButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: ObicColors.background,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _HighlightChip(
                                icon: restaurant
                                    ? Icons.restaurant_rounded
                                    : flight
                                        ? Icons.flight_rounded
                                        : Icons.hotel_rounded,
                                label: restaurant
                                    ? (ar ? 'مطعم' : 'Restaurant')
                                    : flight
                                        ? (ar ? 'عرض طيران' : 'Flight offer')
                                        : (ar ? 'عرض فندق' : 'Hotel offer'),
                              ),
                              if (soldOut)
                                _HighlightChip(
                                  icon: Icons.event_busy_rounded,
                                  label: ar ? 'نفدت الكمية' : 'Sold out',
                                ),
                              if (expired)
                                _HighlightChip(
                                  icon: Icons.timer_off_outlined,
                                  label: ar ? 'منتهي' : 'Expired',
                                ),
                              if (loc != null && loc.isNotEmpty)
                                _HighlightChip(
                                  icon: flight
                                      ? Icons.route_rounded
                                      : Icons.place_outlined,
                                  label: loc,
                                ),
                              if (dates != null && dates.isNotEmpty)
                                _HighlightChip(
                                  icon: Icons.calendar_month_outlined,
                                  label: dates,
                                ),
                              ..._offerTripChipLabels(o, ar, kind).map(
                                (label) => _HighlightChip(
                                  icon: flight
                                      ? Icons.airlines_rounded
                                      : Icons.star_rounded,
                                  label: label,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: ObicColors.titleOf(context),
                              height: 1.25,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (price != null && price.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              price,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: ObicColors.blue,
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          Text(
                            ar ? 'التفاصيل' : 'Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: ObicColors.titleOf(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            body.isEmpty
                                ? (ar
                                    ? 'لا تفاصيل إضافية لهذا العرض.'
                                    : 'No extra details for this offer.')
                                : body,
                            style: TextStyle(
                              height: 1.55,
                              fontSize: 15,
                              color: ObicColors.inkOf(context),
                            ),
                          ),
                          if ((loc != null && loc.isNotEmpty) ||
                              (dates != null && dates.isNotEmpty)) ...[
                            const SizedBox(height: 22),
                            Text(
                              flight
                                  ? (ar ? 'معلومات الرحلة' : 'Flight info')
                                  : restaurant
                                      ? (ar ? 'معلومات التوصيل' : 'Delivery info')
                                      : (ar ? 'معلومات الإقامة' : 'Stay info'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: ObicColors.titleOf(context),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (loc != null && loc.isNotEmpty)
                              _InfoRow(
                                icon: flight
                                    ? Icons.connecting_airports_rounded
                                    : Icons.location_on_outlined,
                                label: flight
                                    ? (ar ? 'المسار' : 'Route')
                                    : (ar ? 'الموقع' : 'Location'),
                                value: loc,
                              ),
                            if (dates != null && dates.isNotEmpty)
                              _InfoRow(
                                icon: Icons.date_range_outlined,
                                label: ar ? 'التواريخ' : 'Dates',
                                value: dates,
                              ),
                            ..._offerTripChipLabels(o, ar, kind).map(
                              (label) => _InfoRow(
                                icon: flight
                                    ? Icons.airplane_ticket_outlined
                                    : Icons.check_circle_outline,
                                label: flight
                                    ? (ar ? 'تفاصيل' : 'Detail')
                                    : (ar ? 'مزايا' : 'Feature'),
                                value: label,
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (canRequest)
            _StickyRequestBar(
              arabic: ar,
              price: price,
              actionLabel: restaurant
                  ? (ar ? 'طلب من المطعم' : 'Order from restaurant')
                  : (ar ? 'طلب هذا العرض' : 'Request this offer'),
              onPressed: () => _requestOffer(title),
            )
          else
            _StickyUnavailableBar(
              arabic: ar,
              soldOut: soldOut,
              expired: expired,
            ),
        ],
      ),
    );
  }
}

class _StickyRequestBar extends StatelessWidget {
  const _StickyRequestBar({
    required this.arabic,
    required this.onPressed,
    required this.actionLabel,
    this.price,
  });

  final bool arabic;
  final VoidCallback onPressed;
  final String actionLabel;
  final String? price;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final hasPrice = price != null && price!.isNotEmpty;
    return Material(
      color: ObicColors.surfaceOf(context),
      elevation: 12,
      shadowColor: ObicColors.navy.withValues(alpha: 0.16),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
        child: Row(
          children: [
            if (hasPrice) ...[
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      arabic ? 'السعر' : 'Price',
                      style: TextStyle(
                        color: ObicColors.mutedOf(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      price!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ObicColors.titleOf(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: hasPrice ? 5 : 1,
              child: FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: ObicColors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyUnavailableBar extends StatelessWidget {
  const _StickyUnavailableBar({
    required this.arabic,
    required this.soldOut,
    required this.expired,
  });

  final bool arabic;
  final bool soldOut;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final msg = soldOut
        ? (arabic ? 'هذا العرض نفد' : 'This offer is sold out')
        : expired
            ? (arabic ? 'انتهت صلاحية هذا العرض' : 'This offer has expired')
            : (arabic ? 'العرض غير متاح للطلب' : 'Offer not available');
    return Material(
      color: ObicColors.surfaceOf(context),
      elevation: 8,
      shadowColor: ObicColors.navy.withValues(alpha: 0.12),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: ObicColors.lineOf(context).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: ObicColors.mutedOf(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ObicColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ObicColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: ObicColors.blueDeep),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ObicColors.titleOf(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ObicColors.blueSoftOf(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ObicColors.blueDeep, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ObicColors.mutedOf(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: ObicColors.titleOf(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _OfferMediaPlaceholder extends StatelessWidget {
  const _OfferMediaPlaceholder({
    required this.flight,
    this.restaurant = false,
    this.arabic = false,
    this.compact = false,
  });

  final bool flight;
  final bool restaurant;
  final bool arabic;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = restaurant
        ? (arabic ? 'مطعم' : 'Restaurant')
        : flight
            ? (arabic ? 'عرض طيران' : 'Flight offer')
            : (arabic ? 'عرض فندق' : 'Hotel offer');
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: restaurant
              ? const [Color(0xFFC45C26), Color(0xFF8B3A12)]
              : flight
                  ? const [Color(0xFF1A4A8C), ObicColors.navy]
                  : const [Color(0xFF2A5F9E), Color(0xFF163A66)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            restaurant
                ? Icons.restaurant_rounded
                : flight
                    ? Icons.flight_rounded
                    : Icons.hotel_rounded,
            size: compact ? 40 : 64,
            color: Colors.white.withValues(alpha: 0.92),
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfferNetworkImage extends StatelessWidget {
  const _OfferNetworkImage({
    required this.url,
    required this.flight,
    required this.arabic,
    this.restaurant = false,
  });

  final String url;
  final bool flight;
  final bool arabic;
  final bool restaurant;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _OfferMediaPlaceholder(
        flight: flight,
        restaurant: restaurant,
        arabic: arabic,
      );
    }
    return ObicCachedImage(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: ObicColors.navySoft,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white.withValues(alpha: 0.85),
                value: progress.expectedTotalBytes == null
                    ? null
                    : progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => _OfferMediaPlaceholder(
        flight: flight,
        restaurant: restaurant,
        arabic: arabic,
      ),
    );
  }
}

class _OfferMediaCarousel extends StatefulWidget {
  const _OfferMediaCarousel({
    required this.media,
    required this.flight,
    required this.arabic,
    this.restaurant = false,
  });

  final List<Map<String, dynamic>> media;
  final bool flight;
  final bool arabic;
  final bool restaurant;

  @override
  State<_OfferMediaCarousel> createState() => _OfferMediaCarouselState();
}

class _OfferMediaCarouselState extends State<_OfferMediaCarousel> {
  late final PageController _controller = PageController();
  int _index = 0;

  @override
  void didUpdateWidget(covariant _OfferMediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.length != widget.media.length) {
      _index = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen(int index) {
    if (widget.media.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => _OfferFullscreenGallery(
          media: widget.media,
          initialIndex: index,
          flight: widget.flight,
        ),
        transitionsBuilder: (_, anim, _, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) {
      return _OfferMediaPlaceholder(
        flight: widget.flight,
        restaurant: widget.restaurant,
        arabic: widget.arabic,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.media.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            final m = widget.media[i];
            final url = resolveMediaUrl(m['url'] as String?);
            final active = i == _index;
            if (m['kind'] == 'video') {
              return Stack(
                fit: StackFit.expand,
                children: [
                  _OfferVideoSlide(
                    url: url,
                    fill: true,
                    playingAllowed: active,
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 56,
                    right: 12,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _openFullscreen(i),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.fullscreen_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return GestureDetector(
              onTap: () => _openFullscreen(i),
              child: _OfferNetworkImage(
                url: url,
                flight: widget.flight,
                restaurant: widget.restaurant,
                arabic: widget.arabic,
              ),
            );
          },
        ),
        if (widget.media.length > 1) ...[
          Positioned(
            top: MediaQuery.paddingOf(context).top + 14,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_index + 1}/${widget.media.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.media.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}

class _OfferVideoSlide extends StatefulWidget {
  const _OfferVideoSlide({
    required this.url,
    this.fill = false,
    this.autoPlay = false,
    this.playingAllowed = true,
  });

  final String url;
  final bool fill;
  final bool autoPlay;
  final bool playingAllowed;

  @override
  State<_OfferVideoSlide> createState() => _OfferVideoSlideState();
}

class _OfferVideoSlideState extends State<_OfferVideoSlide> {
  VideoPlayerController? _c;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    if (widget.url.isEmpty) return;
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _c = c;
    c.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      if (widget.autoPlay && widget.playingAllowed) c.play();
      c.addListener(() {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void didUpdateWidget(covariant _OfferVideoSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _c?.dispose();
      _c = null;
      _ready = false;
      _start();
      return;
    }
    final c = _c;
    if (c == null || !_ready) return;
    if (!widget.playingAllowed && c.value.isPlaying) {
      c.pause();
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  void _toggle() {
    final c = _c;
    if (c == null || !_ready) return;
    c.value.isPlaying ? c.pause() : c.play();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null || !_ready) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final video = FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: c.value.size.width,
        height: c.value.size.height,
        child: VideoPlayer(c),
      ),
    );

    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.fill) video else Center(child: video),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x26000000),
                  Color(0x00000000),
                  Color(0x59000000),
                ],
              ),
            ),
          ),
          if (!c.value.isPlaying)
            const Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _OfferFullscreenGallery extends StatefulWidget {
  const _OfferFullscreenGallery({
    required this.media,
    required this.initialIndex,
    required this.flight,
  });

  final List<Map<String, dynamic>> media;
  final int initialIndex;
  final bool flight;

  @override
  State<_OfferFullscreenGallery> createState() =>
      _OfferFullscreenGalleryState();
}

class _OfferFullscreenGalleryState extends State<_OfferFullscreenGallery> {
  late final PageController _pc =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: widget.media.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final m = widget.media[i];
              final url = resolveMediaUrl(m['url'] as String?);
              if (m['kind'] == 'video') {
                return _OfferVideoSlide(
                  url: url,
                  fill: false,
                  autoPlay: i == _index,
                  playingAllowed: i == _index,
                );
              }
              return InteractiveViewer(
                child: Center(
                  child: ObicCachedImage(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      widget.flight ? Icons.flight : Icons.hotel,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    '${_index + 1} / ${widget.media.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
