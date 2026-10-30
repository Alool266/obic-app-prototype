// Made by Dr Ali
// Public visit pins in China — WGS-84, keyed by cityId.

import 'dart:math' as math;

enum ChinaVisitKind { mosque, market, place, halal }

class ChinaVisitPlace {
  const ChinaVisitPlace({
    required this.id,
    required this.cityId,
    required this.kind,
    required this.lat,
    required this.lng,
    required this.nameAr,
    required this.nameEn,
    required this.nameZh,
    required this.blurbAr,
    required this.blurbEn,
    required this.blurbZh,
    this.imageAsset,
    this.tipsAr,
    this.tipsEn,
    this.tipsZh,
    this.sourceNote = 'Public landmark / community listing',
  });

  final String id;
  final String cityId;
  final ChinaVisitKind kind;
  final double lat;
  final double lng;
  final String nameAr;
  final String nameEn;
  final String nameZh;
  final String blurbAr;
  final String blurbEn;
  final String blurbZh;
  final String? imageAsset;
  final String? tipsAr;
  final String? tipsEn;
  final String? tipsZh;
  final String sourceNote;

  String name(String lang) => _pick(lang, nameAr, nameEn, nameZh);
  String blurb(String lang) => _pick(lang, blurbAr, blurbEn, blurbZh);
  String? tips(String lang) {
    final a = tipsAr;
    final e = tipsEn;
    final z = tipsZh;
    if (a == null && e == null && z == null) return null;
    return _pick(lang, a ?? e ?? '', e ?? a ?? '', z ?? e ?? a ?? '');
  }

  static String _pick(String lang, String ar, String en, String zh) {
    if (lang.startsWith('ar')) return ar;
    if (lang.startsWith('zh')) return zh;
    return en;
  }
}

const kChinaVisitNearKm = 120.0;

bool isRoughlyInOrNearChina(double lat, double lng) {
  return lat >= 18.0 && lat <= 54.0 && lng >= 73.0 && lng <= 135.0;
}

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a));
}

double _rad(double d) => d * math.pi / 180.0;

List<ChinaVisitPlace> placesForCity(String cityId) {
  return kChinaVisitPlaces.where((p) => p.cityId == cityId).toList();
}

List<({ChinaVisitPlace place, double km})> chinaVisitNearby({
  required double userLat,
  required double userLng,
  double maxKm = kChinaVisitNearKm,
  String? cityId,
}) {
  if (!isRoughlyInOrNearChina(userLat, userLng)) return const [];
  final pool = cityId == null
      ? kChinaVisitPlaces
      : placesForCity(cityId);
  final out = <({ChinaVisitPlace place, double km})>[];
  for (final p in pool.isEmpty ? kChinaVisitPlaces : pool) {
    final km = haversineKm(userLat, userLng, p.lat, p.lng);
    if (km <= maxKm) out.add((place: p, km: km));
  }
  out.sort((a, b) => a.km.compareTo(b.km));
  return out;
}

const _imgMosque = 'assets/mideast/mosque.jpg';
const _imgMarket = 'assets/china/expo-hall.jpg';
const _imgNight = 'assets/china/night-city.jpg';
const _imgBiz = 'assets/china/business-skyline.jpg';
const _imgTravel = 'assets/travel/landmark.jpg';

const kChinaVisitPlaces = <ChinaVisitPlace>[
  // —— Yiwu ——
  ChinaVisitPlace(
    id: 'yiwu-mosque',
    cityId: 'yiwu',
    kind: ChinaVisitKind.mosque,
    lat: 29.3069,
    lng: 120.0753,
    nameAr: 'مسجد ييوو',
    nameEn: 'Yiwu Mosque',
    nameZh: '义乌清真寺',
    blurbAr: 'مسجد معروف للجالية العربية في ييوو.',
    blurbEn: 'Well-known mosque for the Arab community in Yiwu.',
    blurbZh: '义乌阿拉伯社群常去的清真寺。',
    imageAsset: _imgMosque,
    tipsAr: 'تحقق من مواقيت الصلاة محلياً.',
    tipsEn: 'Confirm prayer times locally.',
    tipsZh: '请当地核实礼拜时间。',
  ),
  ChinaVisitPlace(
    id: 'yiwu-futian',
    cityId: 'yiwu',
    kind: ChinaVisitKind.market,
    lat: 29.3235,
    lng: 120.0788,
    nameAr: 'سوق فوتان الدولي',
    nameEn: 'Futian Market (Yiwu)',
    nameZh: '义乌国际商贸城（福田）',
    blurbAr: 'مجمّع التجارة الدولي — قلب توريد ييوو.',
    blurbEn: 'International Trade City — heart of Yiwu sourcing.',
    blurbZh: '国际商贸城 — 义乌采购核心。',
    imageAsset: _imgMarket,
  ),
  ChinaVisitPlace(
    id: 'yiwu-binwang',
    cityId: 'yiwu',
    kind: ChinaVisitKind.market,
    lat: 29.3148,
    lng: 120.0625,
    nameAr: 'سوق بينوانغ',
    nameEn: 'Binwang Market',
    nameZh: '宾王市场',
    blurbAr: 'سوق يومي وملابس قريب من وسط ييوو.',
    blurbEn: 'Daily goods and apparel near central Yiwu.',
    blurbZh: '义乌城区日用品与服装市场。',
    imageAsset: 'assets/daily/market.jpg',
  ),
  ChinaVisitPlace(
    id: 'yiwu-xiuhu',
    cityId: 'yiwu',
    kind: ChinaVisitKind.place,
    lat: 29.3372,
    lng: 120.0965,
    nameAr: 'منتزه شيوهو',
    nameEn: 'Xiuhu Park',
    nameZh: '绣湖公园',
    blurbAr: 'متنزه حضري هادئ للتنزه.',
    blurbEn: 'Calm urban park for a short walk.',
    blurbZh: '适合散步的城市公园。',
    imageAsset: _imgTravel,
  ),
  // —— Guangzhou ——
  ChinaVisitPlace(
    id: 'gz-huaisheng',
    cityId: 'guangzhou',
    kind: ChinaVisitKind.mosque,
    lat: 23.1213,
    lng: 113.2558,
    nameAr: 'مسجد هوايشنغ',
    nameEn: 'Huaisheng Mosque',
    nameZh: '怀圣寺',
    blurbAr: 'من أقدم المساجد في الصين.',
    blurbEn: 'One of China’s oldest mosques.',
    blurbZh: '中国最古老清真寺之一。',
    imageAsset: _imgMosque,
  ),
  ChinaVisitPlace(
    id: 'gz-xiaobei',
    cityId: 'guangzhou',
    kind: ChinaVisitKind.market,
    lat: 23.1355,
    lng: 113.2762,
    nameAr: 'منطقة شياوبي',
    nameEn: 'Xiaobei trade area',
    nameZh: '小北商圈',
    blurbAr: 'حي تجارة وطعام عربي-أفريقي.',
    blurbEn: 'Arab–African trade and food district.',
    blurbZh: '阿拉伯-非洲商贸餐饮区。',
    imageAsset: 'assets/daily/food.jpg',
  ),
  ChinaVisitPlace(
    id: 'gz-canton-fair',
    cityId: 'guangzhou',
    kind: ChinaVisitKind.place,
    lat: 23.1084,
    lng: 113.3645,
    nameAr: 'مجمّع معرض كانتون',
    nameEn: 'Canton Fair Complex',
    nameZh: '广交会展馆',
    blurbAr: 'موقع معرض الاستيراد والتصدير.',
    blurbEn: 'China Import and Export Fair venue.',
    blurbZh: '中国进出口商品交易会场馆。',
    imageAsset: 'assets/china/convention.jpg',
  ),
  // —— Shanghai ——
  ChinaVisitPlace(
    id: 'sh-xiaotaoyuan',
    cityId: 'shanghai',
    kind: ChinaVisitKind.mosque,
    lat: 31.2205,
    lng: 121.4892,
    nameAr: 'مسجد شياوتاويوان',
    nameEn: 'Xiaotaoyuan Mosque',
    nameZh: '小桃园清真寺',
    blurbAr: 'مسجد تاريخي في الحي القديم.',
    blurbEn: 'Historic mosque in the old town area.',
    blurbZh: '老城厢历史清真寺。',
    imageAsset: _imgMosque,
  ),
  ChinaVisitPlace(
    id: 'sh-yuyuan',
    cityId: 'shanghai',
    kind: ChinaVisitKind.market,
    lat: 31.2272,
    lng: 121.4920,
    nameAr: 'سوق يويوان',
    nameEn: 'Yuyuan Bazaar',
    nameZh: '豫园商城',
    blurbAr: 'أسواق وهدايا بجانب الحديقة.',
    blurbEn: 'Markets beside the classical garden.',
    blurbZh: '古典园林旁商城。',
    imageAsset: _imgMarket,
  ),
  ChinaVisitPlace(
    id: 'sh-bund',
    cityId: 'shanghai',
    kind: ChinaVisitKind.place,
    lat: 31.2400,
    lng: 121.4905,
    nameAr: 'البوند',
    nameEn: 'The Bund',
    nameZh: '外滩',
    blurbAr: 'واجهة النهر وأفق بودونغ.',
    blurbEn: 'Riverfront skyline toward Pudong.',
    blurbZh: '黄浦江畔天际线。',
    imageAsset: _imgNight,
  ),
  // —— Beijing ——
  ChinaVisitPlace(
    id: 'bj-niujie',
    cityId: 'beijing',
    kind: ChinaVisitKind.mosque,
    lat: 39.8865,
    lng: 116.3728,
    nameAr: 'مسجد نيوجي',
    nameEn: 'Niujie Mosque',
    nameZh: '牛街礼拜寺',
    blurbAr: 'أشهر مساجد بكين.',
    blurbEn: 'Beijing’s best-known mosque.',
    blurbZh: '北京著名清真寺。',
    imageAsset: _imgMosque,
  ),
  ChinaVisitPlace(
    id: 'bj-panjiayuan',
    cityId: 'beijing',
    kind: ChinaVisitKind.market,
    lat: 39.8755,
    lng: 116.4495,
    nameAr: 'سوق بانجيايوان',
    nameEn: 'Panjiayuan Market',
    nameZh: '潘家园旧货市场',
    blurbAr: 'سوق عتيقات وهدايا.',
    blurbEn: 'Antiques and gifts market.',
    blurbZh: '旧货文玩市场。',
    imageAsset: 'assets/daily/market.jpg',
  ),
  ChinaVisitPlace(
    id: 'bj-forbidden',
    cityId: 'beijing',
    kind: ChinaVisitKind.place,
    lat: 39.9163,
    lng: 116.3972,
    nameAr: 'المدينة المحرّمة',
    nameEn: 'Forbidden City',
    nameZh: '故宫',
    blurbAr: 'القصر الإمبراطوري — احجز مسبقاً.',
    blurbEn: 'Imperial palace — book ahead.',
    blurbZh: '故宫 — 建议提前购票。',
    imageAsset: _imgTravel,
  ),
  // —— Hangzhou ——
  ChinaVisitPlace(
    id: 'hz-phoenix',
    cityId: 'hangzhou',
    kind: ChinaVisitKind.mosque,
    lat: 30.2465,
    lng: 120.1705,
    nameAr: 'مسجد فينيكس',
    nameEn: 'Phoenix Mosque',
    nameZh: '凤凰寺',
    blurbAr: 'مسجد تاريخي قرب بحيرة الغرب.',
    blurbEn: 'Historic mosque near West Lake.',
    blurbZh: '西湖附近历史清真寺。',
    imageAsset: _imgMosque,
  ),
  ChinaVisitPlace(
    id: 'hz-west-lake',
    cityId: 'hangzhou',
    kind: ChinaVisitKind.place,
    lat: 30.2420,
    lng: 120.1485,
    nameAr: 'بحيرة الغرب',
    nameEn: 'West Lake',
    nameZh: '西湖',
    blurbAr: 'من أشهر المناظر في الصين.',
    blurbEn: 'One of China’s most famous landscapes.',
    blurbZh: '中国著名风景名胜。',
    imageAsset: _imgTravel,
  ),
  // —— Shenzhen ——
  ChinaVisitPlace(
    id: 'sz-nanshan-mosque',
    cityId: 'shenzhen',
    kind: ChinaVisitKind.mosque,
    lat: 22.5329,
    lng: 113.9308,
    nameAr: 'مسجد نانشان',
    nameEn: 'Nanshan Mosque',
    nameZh: '南山清真寺',
    blurbAr: 'مسجد حديث في نانشان.',
    blurbEn: 'Modern mosque in Nanshan.',
    blurbZh: '南山区清真寺。',
    imageAsset: _imgMosque,
  ),
  ChinaVisitPlace(
    id: 'sz-huaqiangbei',
    cityId: 'shenzhen',
    kind: ChinaVisitKind.market,
    lat: 22.5455,
    lng: 114.0850,
    nameAr: 'هواتشيانغبي',
    nameEn: 'Huaqiangbei',
    nameZh: '华强北',
    blurbAr: 'أكبر أسواق الإلكترونيات.',
    blurbEn: 'Major electronics trading area.',
    blurbZh: '电子元器件商圈。',
    imageAsset: _imgBiz,
  ),
  // —— Ningbo / Wenzhou / Dongguan / Suzhou / Chengdu / Xi'an ——
  ChinaVisitPlace(
    id: 'nb-tianyi',
    cityId: 'ningbo',
    kind: ChinaVisitKind.place,
    lat: 29.8688,
    lng: 121.5430,
    nameAr: 'ساحة تianyي / وسط نينغبو',
    nameEn: 'Tianyi Square area',
    nameZh: '天一广场',
    blurbAr: 'قلب التسوق والحياة في نينغبو.',
    blurbEn: 'Ningbo’s central shopping hub.',
    blurbZh: '宁波中心商圈。',
    imageAsset: _imgBiz,
  ),
  ChinaVisitPlace(
    id: 'wz-jiangxin',
    cityId: 'wenzhou',
    kind: ChinaVisitKind.place,
    lat: 28.0197,
    lng: 120.6480,
    nameAr: 'جزيرة جيانغشين',
    nameEn: 'Jiangxin Island',
    nameZh: '江心屿',
    blurbAr: 'جزيرة نهرية هادئة في ونتشو.',
    blurbEn: 'River island park in Wenzhou.',
    blurbZh: '温州江心屿公园。',
    imageAsset: _imgTravel,
  ),
  ChinaVisitPlace(
    id: 'dg-ophelia',
    cityId: 'dongguan',
    kind: ChinaVisitKind.market,
    lat: 23.0210,
    lng: 113.7518,
    nameAr: 'أسواق مصانع دونغقوان',
    nameEn: 'Dongguan factory markets',
    nameZh: '东莞工厂商圈',
    blurbAr: 'منطقة توريد وتصنيع قريبة من شنتشن.',
    blurbEn: 'Sourcing/manufacturing belt near Shenzhen.',
    blurbZh: '临近深圳的制造采购带。',
    imageAsset: _imgMarket,
  ),
  ChinaVisitPlace(
    id: 'sz-humble',
    cityId: 'suzhou',
    kind: ChinaVisitKind.place,
    lat: 31.3243,
    lng: 120.6250,
    nameAr: 'حديقة المتواضع الإداري',
    nameEn: 'Humble Administrator’s Garden',
    nameZh: '拙政园',
    blurbAr: 'حديقة كلاسيكية شهيرة في سوتشو.',
    blurbEn: 'Famous classical garden in Suzhou.',
    blurbZh: '苏州著名古典园林。',
    imageAsset: _imgTravel,
  ),
  ChinaVisitPlace(
    id: 'cd-wide-narrow',
    cityId: 'chengdu',
    kind: ChinaVisitKind.place,
    lat: 30.6637,
    lng: 104.0540,
    nameAr: 'شوارع كوانجاي تشايجي',
    nameEn: 'Kuanzhai Alley',
    nameZh: '宽窄巷子',
    blurbAr: 'أزقة تراثية ومطاعم في تشنغدو.',
    blurbEn: 'Heritage lanes and dining in Chengdu.',
    blurbZh: '成都宽窄巷子。',
    imageAsset: 'assets/daily/cafe.jpg',
  ),
  ChinaVisitPlace(
    id: 'xa-muslim-quarter',
    cityId: 'xian',
    kind: ChinaVisitKind.market,
    lat: 34.2655,
    lng: 108.9450,
    nameAr: 'الحي الإسلامي / سوق مسلم',
    nameEn: 'Muslim Quarter',
    nameZh: '回民街',
    blurbAr: 'سوق طعام وتسوق قرب المسجد الكبير.',
    blurbEn: 'Food and shopping near the Great Mosque.',
    blurbZh: '靠近大清真寺的回民街。',
    imageAsset: 'assets/daily/food.jpg',
  ),
  ChinaVisitPlace(
    id: 'xa-great-mosque',
    cityId: 'xian',
    kind: ChinaVisitKind.mosque,
    lat: 34.2635,
    lng: 108.9428,
    nameAr: 'المسجد الكبير في شيان',
    nameEn: 'Great Mosque of Xi’an',
    nameZh: '西安大清真寺',
    blurbAr: 'مسجد تاريخي بطراز صيني-إسلامي.',
    blurbEn: 'Historic Chinese–Islamic style mosque.',
    blurbZh: '中国伊斯兰教历史名寺。',
    imageAsset: _imgMosque,
  ),
];
