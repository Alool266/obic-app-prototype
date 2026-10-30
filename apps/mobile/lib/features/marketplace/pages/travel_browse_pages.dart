// Made by Dr Ali
// Ctrip-style travel category screens — distinct UIs per vertical.

import 'package:flutter/material.dart';

import '../../../theme/obic_colors.dart';
import '../../../widgets/obic_cached_image.dart';
import '../../auth/auth_controller.dart';
import '../marketplace_api.dart';
import '../marketplace_models.dart';
import 'marketplace_chrome.dart';

class HotelBrowsePage extends StatefulWidget {
  const HotelBrowsePage({
    super.key,
    required this.authController,
    required this.langCode,
    this.initialCity,
  });
  final AuthController authController;
  final String langCode;
  final String? initialCity;

  @override
  State<HotelBrowsePage> createState() => _HotelBrowsePageState();
}

class _HotelBrowsePageState extends State<HotelBrowsePage> {
  late Future<List<HotelListing>> _future;
  String _city = '';
  String _chip = 'all';

  @override
  void initState() {
    super.initState();
    _city = widget.initialCity?.trim() ?? '';
    _future = marketplaceRepo.searchHotels(
      city: _city.isEmpty ? null : _city,
    );
  }

  void _reload() {
    setState(() => _future = marketplaceRepo.searchHotels(
          city: _city.isEmpty ? null : _city,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.langCode;
    final chips = <(String id, String label)>[
      ('all', mp(lang, 'الكل', 'All', '全部')),
      ('tonight', mp(lang, 'الليلة', 'Tonight', '今晚')),
      ('stars4', mp(lang, '★ ٤+', '★ 4+', '★4+')),
      ('deal', mp(lang, 'عروض', 'Deals', '优惠')),
    ];
    return MarketplaceScaffold(
      title: mp(lang, 'فنادق', 'Hotels', '酒店'),
      accent: const Color(0xFF1A6DFF),
      searchHint: mp(lang, 'مدينة أو فندق…', 'City or hotel…', '城市或酒店…'),
      onSearch: (v) {
        _city = v.trim();
        _reload();
      },
      headerExtra: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final c in chips)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _chip = c.$1),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _chip == c.$1
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      c.$2,
                      style: TextStyle(
                        color: _chip == c.$1
                            ? const Color(0xFF1A6DFF)
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      body: FutureBuilder<List<HotelListing>>(
        future: _future,
        builder: (context, snap) {
          var items = snap.data ?? const <HotelListing>[];
          if (snap.connectionState == ConnectionState.waiting &&
              items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_chip == 'stars4') {
            items = items.where((h) => h.stars >= 4).toList();
          } else if (_chip == 'deal') {
            items = items.where((h) => h.pricePerNightYuan <= 450).toList();
          }
          // tonight = show all available (same list — request still created)
          if (items.isEmpty) {
            return Center(
              child: Text(
                mp(lang, 'لا فنادق مطابقة', 'No matching hotels', '无匹配酒店'),
                style: TextStyle(color: ObicColors.mutedOf(context)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final h = items[i];
              return MarketplaceListCard(
                onTap: () => showMarketplaceHoldDialog(
                  context,
                  auth: widget.authController,
                  langCode: lang,
                  title: h.name(lang),
                  vertical: MarketplaceVertical.hotel,
                  city: h.city,
                  notes: _chip == 'tonight'
                      ? 'Check-in: tonight'
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: ObicCachedImage(h.photo, fit: BoxFit.cover),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.name(lang),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: ObicColors.titleOf(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${'★' * h.stars} · ${h.city}',
                              style: TextStyle(
                                color: ObicColors.mutedOf(context),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${h.rating} (${h.reviewCount})'
                              '${h.distanceKm != null ? ' · ${h.distanceKm} km' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: [
                                for (final t in h.tags.take(3))
                                  _tag(context, t),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '¥${h.pricePerNightYuan}'
                              '${mp(lang, '/ليلة', '/night', '/晚')}',
                              style: const TextStyle(
                                color: ObicColors.blue,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FlightBrowsePage extends StatefulWidget {
  const FlightBrowsePage({
    super.key,
    required this.authController,
    required this.langCode,
  });
  final AuthController authController;
  final String langCode;

  @override
  State<FlightBrowsePage> createState() => _FlightBrowsePageState();
}

class _FlightBrowsePageState extends State<FlightBrowsePage> {
  late Future<List<FlightOffer>> _future;
  final _from = TextEditingController(text: 'HGH');
  final _to = TextEditingController(text: 'CAN');

  @override
  void initState() {
    super.initState();
    _future = marketplaceRepo.searchFlights();
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.langCode;
    return MarketplaceScaffold(
      title: mp(lang, 'طيران', 'Flights', '机票'),
      accent: const Color(0xFF2563EB),
      headerExtra: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: _routeField(_from, mp(lang, 'من', 'From', '出发')),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.swap_horiz_rounded, color: Colors.white),
            ),
            Expanded(
              child: _routeField(_to, mp(lang, 'إلى', 'To', '到达')),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => setState(() {
                _future = marketplaceRepo.searchFlights(
                  from: _from.text,
                  to: _to.text,
                );
              }),
              style: IconButton.styleFrom(backgroundColor: ObicColors.blue),
              icon: const Icon(Icons.search_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<FlightOffer>>(
        future: _future,
        builder: (context, snap) {
          final items = snap.data ?? const <FlightOffer>[];
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final f = items[i];
              return MarketplaceListCard(
                onTap: () => showMarketplaceHoldDialog(
                  context,
                  auth: widget.authController,
                  langCode: lang,
                  title: '${f.airline} ${f.fromCode}→${f.toCode}',
                  vertical: MarketplaceVertical.flight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            f.airline,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: ObicColors.titleOf(context),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            f.stops == 0
                                ? mp(lang, 'مباشر', 'Nonstop', '直飞')
                                : mp(lang, '${f.stops} توقف',
                                    '${f.stops} stop', '${f.stops}停'),
                            style: TextStyle(
                              color: ObicColors.mutedOf(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _timeCol(f.departTime, f.fromCode),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${f.durationMin ~/ 60}h ${f.durationMin % 60}m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ObicColors.mutedOf(context),
                                  ),
                                ),
                                const Divider(color: ObicColors.blue),
                              ],
                            ),
                          ),
                          _timeCol(f.arriveTime, f.toCode, alignEnd: true),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          '¥${f.priceYuan}',
                          style: const TextStyle(
                            color: ObicColors.blue,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _routeField(TextEditingController c, String label) => TextField(
        controller: c,
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          isDense: true,
          border: InputBorder.none,
        ),
      );

  Widget _timeCol(String time, String code, {bool alignEnd = false}) => Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          Text(
            code,
            style: TextStyle(
              color: ObicColors.mutedOf(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

class TrainBrowsePage extends StatefulWidget {
  const TrainBrowsePage({
    super.key,
    required this.authController,
    required this.langCode,
  });
  final AuthController authController;
  final String langCode;

  @override
  State<TrainBrowsePage> createState() => _TrainBrowsePageState();
}

class _TrainBrowsePageState extends State<TrainBrowsePage> {
  late Future<List<TrainTrip>> _future =
      marketplaceRepo.searchTrains();

  @override
  Widget build(BuildContext context) {
    final lang = widget.langCode;
    return MarketplaceScaffold(
      title: mp(lang, 'قطارات', 'Trains', '火车'),
      accent: const Color(0xFF0B4FD6),
      body: FutureBuilder<List<TrainTrip>>(
        future: _future,
        builder: (context, snap) {
          final items = snap.data ?? const <TrainTrip>[];
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final t = items[i];
              return MarketplaceListCard(
                onTap: () => showMarketplaceHoldDialog(
                  context,
                  auth: widget.authController,
                  langCode: lang,
                  title: t.trainNo,
                  vertical: MarketplaceVertical.train,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: ObicColors.blueSoftOf(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          t.trainNo,
                          style: const TextStyle(
                            color: ObicColors.blueDeep,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${t.departTime} → ${t.arriveTime}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: ObicColors.titleOf(context),
                              ),
                            ),
                            Text(
                              '${t.fromStation} · ${t.toStation}',
                              style: TextStyle(
                                color: ObicColors.mutedOf(context),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${t.durationMin} min · ${t.seatClass}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '¥${t.priceYuan}',
                        style: const TextStyle(
                          color: ObicColors.blue,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AttractionBrowsePage extends StatefulWidget {
  const AttractionBrowsePage({
    super.key,
    required this.authController,
    required this.langCode,
    this.initialCity,
  });
  final AuthController authController;
  final String langCode;
  final String? initialCity;

  @override
  State<AttractionBrowsePage> createState() => _AttractionBrowsePageState();
}

class _AttractionBrowsePageState extends State<AttractionBrowsePage> {
  late Future<List<AttractionTicket>> _future;
  String _q = '';

  @override
  void initState() {
    super.initState();
    final city = widget.initialCity?.trim();
    _future = marketplaceRepo.listAttractions(
      city: (city == null || city.isEmpty) ? null : city,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.langCode;
    return MarketplaceScaffold(
      title: mp(lang, 'معالم وتذاكر', 'Sights & tickets', '景点门票'),
      accent: const Color(0xFF0891B2),
      searchHint: mp(lang, 'مدينة أو معلم…', 'City or sight…', '城市或景点…'),
      onSearch: (v) => setState(() => _q = v.trim().toLowerCase()),
      body: FutureBuilder<List<AttractionTicket>>(
        future: _future,
        builder: (context, snap) {
          var items = snap.data ?? const <AttractionTicket>[];
          if (_q.isNotEmpty) {
            items = items
                .where((a) =>
                    a.nameEn.toLowerCase().contains(_q) ||
                    a.nameAr.contains(_q) ||
                    a.city.toLowerCase().contains(_q))
                .toList();
          }
          if (items.isEmpty) {
            return Center(
              child: Text(
                mp(lang, 'لا معالم مطابقة', 'No matching sights', '无匹配景点'),
                style: TextStyle(color: ObicColors.mutedOf(context)),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final a = items[i];
              return MarketplaceListCard(
                onTap: () => showMarketplaceHoldDialog(
                  context,
                  auth: widget.authController,
                  langCode: lang,
                  title: a.name(lang),
                  vertical: MarketplaceVertical.attraction,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ObicCachedImage(a.photo, fit: BoxFit.cover),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.name(lang),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: ObicColors.titleOf(context),
                            ),
                          ),
                          Text(
                            '${a.city} · ★${a.rating}',
                            style: TextStyle(
                              fontSize: 11,
                              color: ObicColors.mutedOf(context),
                            ),
                          ),
                          Text(
                            a.priceYuan == 0
                                ? mp(lang, 'مجاني', 'Free', '免费')
                                : '¥${a.priceYuan}',
                            style: const TextStyle(
                              color: ObicColors.blue,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TourBrowsePage extends StatefulWidget {
  const TourBrowsePage({
    super.key,
    required this.authController,
    required this.langCode,
    this.titleOverride,
  });
  final AuthController authController;
  final String langCode;
  final String? titleOverride;

  @override
  State<TourBrowsePage> createState() => _TourBrowsePageState();
}

class _TourBrowsePageState extends State<TourBrowsePage> {
  late Future<List<TourPackage>> _future = marketplaceRepo.listTours();

  @override
  Widget build(BuildContext context) {
    final lang = widget.langCode;
    return MarketplaceScaffold(
      title: widget.titleOverride ??
          mp(lang, 'إجازات وجولات', 'Holidays & tours', '度假跟团'),
      accent: const Color(0xFF059669),
      body: FutureBuilder<List<TourPackage>>(
        future: _future,
        builder: (context, snap) {
          final items = snap.data ?? const <TourPackage>[];
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final t = items[i];
              return MarketplaceListCard(
                onTap: () => showMarketplaceHoldDialog(
                  context,
                  auth: widget.authController,
                  langCode: lang,
                  title: t.name(lang),
                  vertical: MarketplaceVertical.tour,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 140,
                      child: ObicCachedImage(t.photo, fit: BoxFit.cover),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.name(lang),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: ObicColors.titleOf(context),
                            ),
                          ),
                          Text(
                            mp(lang, '${t.days} أيام', '${t.days} days',
                                '${t.days}天'),
                            style: TextStyle(
                              color: ObicColors.mutedOf(context),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              for (final h in t.highlights) _tag(context, h),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '¥${t.priceYuan}',
                            style: const TextStyle(
                              color: ObicColors.blue,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TransferBrowsePage extends StatefulWidget {
  const TransferBrowsePage({
    super.key,
    required this.authController,
    required this.langCode,
  });
  final AuthController authController;
  final String langCode;

  @override
  State<TransferBrowsePage> createState() => _TransferBrowsePageState();
}

class _TransferBrowsePageState extends State<TransferBrowsePage> {
  late Future<List<TransferOption>> _future = marketplaceRepo.listTransfers();

  @override
  Widget build(BuildContext context) {
    final lang = widget.langCode;
    return MarketplaceScaffold(
      title: mp(lang, 'توصيل مطار', 'Airport transfer', '机场接送'),
      accent: const Color(0xFF4F46E5),
      body: FutureBuilder<List<TransferOption>>(
        future: _future,
        builder: (context, snap) {
          final items = snap.data ?? const <TransferOption>[];
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final t = items[i];
              return MarketplaceListCard(
                onTap: () => showMarketplaceHoldDialog(
                  context,
                  auth: widget.authController,
                  langCode: lang,
                  title: t.title(lang),
                  vertical: MarketplaceVertical.transfer,
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: ObicColors.blueSoft,
                    child: Icon(Icons.airport_shuttle_rounded,
                        color: ObicColors.blue),
                  ),
                  title: Text(
                    t.title(lang),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${t.vehicle} · ${t.seats} '
                    '${mp(lang, 'مقاعد', 'seats', '座')} · ${t.etaMin} min',
                  ),
                  trailing: Text(
                    '¥${t.priceYuan}',
                    style: const TextStyle(
                      color: ObicColors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CarRentalBrowsePage extends StatefulWidget {
  const CarRentalBrowsePage({
    super.key,
    required this.authController,
    required this.langCode,
  });
  final AuthController authController;
  final String langCode;

  @override
  State<CarRentalBrowsePage> createState() => _CarRentalBrowsePageState();
}

class _CarRentalBrowsePageState extends State<CarRentalBrowsePage> {
  late Future<List<CarRentalOffer>> _future = marketplaceRepo.listCarRentals();

  @override
  Widget build(BuildContext context) {
    final lang = widget.langCode;
    return MarketplaceScaffold(
      title: mp(lang, 'تأجير سيارات', 'Car rental', '租车'),
      accent: const Color(0xFF0E7490),
      body: FutureBuilder<List<CarRentalOffer>>(
        future: _future,
        builder: (context, snap) {
          final items = snap.data ?? const <CarRentalOffer>[];
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final c = items[i];
              return MarketplaceListCard(
                onTap: () => showMarketplaceHoldDialog(
                  context,
                  auth: widget.authController,
                  langCode: lang,
                  title: c.name(lang),
                  vertical: MarketplaceVertical.carRental,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 80,
                      child: ObicCachedImage(c.photo, fit: BoxFit.cover),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text(
                          c.name(lang),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${c.seats} ${mp(lang, 'مقاعد', 'seats', '座')} · ${c.transmission}',
                        ),
                        trailing: Text(
                          '¥${c.pricePerDayYuan}'
                          '${mp(lang, '/يوم', '/day', '/天')}',
                          style: const TextStyle(
                            color: ObicColors.blue,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Widget _tag(BuildContext context, String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ObicColors.blueSoftOf(context),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: ObicColors.blueDeep,
        ),
      ),
    );
