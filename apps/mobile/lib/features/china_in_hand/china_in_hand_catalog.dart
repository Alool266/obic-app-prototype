// Made by Dr Ali
// «الصين بين يديك» — every China-related app service (no food / flights / transport).

import '../services/service_sub_catalog.dart';

enum ChinaTileAction {
  exhibitions,
  companyRegistration,
  subService,
  logisticsTools,
  scholarships,
  visitNearMe,
}

class ChinaHubSection {
  const ChinaHubSection({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.titleZh,
    required this.tiles,
  });

  final String id;
  final String titleAr;
  final String titleEn;
  final String titleZh;
  final List<ChinaHubTile> tiles;

  String title(String lang) {
    if (lang.startsWith('ar')) return titleAr;
    if (lang.startsWith('zh')) return titleZh;
    return titleEn;
  }
}

class ChinaHubTile {
  const ChinaHubTile({
    required this.id,
    required this.action,
    required this.parentSlug,
    required this.icon,
    required this.labelAr,
    required this.labelEn,
    required this.labelZh,
    this.subServiceId,
    this.searchExtra = const [],
  });

  final String id;
  final ChinaTileAction action;
  final String parentSlug;
  final String? subServiceId;
  final String icon;
  final String labelAr;
  final String labelEn;
  final String labelZh;
  final List<String> searchExtra;

  String label(String lang) {
    if (lang.startsWith('ar')) return labelAr;
    if (lang.startsWith('zh')) return labelZh;
    return labelEn;
  }

  bool matchesQuery(String raw, String lang) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return true;
    final blob = [
      labelAr,
      labelEn,
      labelZh,
      parentSlug,
      subServiceId ?? '',
      ...searchExtra,
    ].join(' ').toLowerCase();
    return blob.contains(q);
  }

  ObicSubService? resolveSub() {
    final sid = subServiceId;
    if (sid == null) return null;
    for (final s in subServicesForParent(parentSlug)) {
      if (s.id == sid) return s;
    }
    return null;
  }
}

/// Hard-excluded: food, flights, passenger transport booking.
const kChinaHubExcludedIds = <String>{
  'food',
  'flights',
  'flight',
  'taxi',
  'vip-taxi',
  'train',
  'trains',
  'bullet-train',
  'bus',
  'buses',
  'transport',
  'tourist-transport',
  'ride',
  'car-rental',
  'private-transfer',
  'e-bikes',
  'bicycles',
  'scooters',
  'boats',
  'delivery-food',
  'restaurants',
  'arabic',
  'asian',
  'fastfood',
  'sweets',
  'coffee',
  'supermarket',
  'yemeni',
  'food-delivery',
};

ChinaHubTile _t({
  required String id,
  required String parentSlug,
  required String labelAr,
  required String labelEn,
  required String labelZh,
  String? icon,
  ChinaTileAction action = ChinaTileAction.subService,
  List<String> searchExtra = const [],
}) {
  return ChinaHubTile(
    id: id,
    action: action,
    parentSlug: parentSlug,
    subServiceId: id,
    icon: icon ?? id,
    labelAr: labelAr,
    labelEn: labelEn,
    labelZh: labelZh,
    searchExtra: searchExtra,
  );
}

/// Landing groups shown as big cards (merged from fine-grained sections).
List<ChinaHubSection> kChinaInHandLandingCategories() {
  final all = kChinaInHandSections();
  ChinaHubSection byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);

  final business = byId('business');
  final consult = byId('consult');
  final property = byId('property');
  final visa = byId('visa-gov');
  final legal = byId('legal-docs');
  final education = byId('education');
  final logistics = byId('obic-logistics-tools');
  final sourcing = byId('sourcing');
  final stay = byId('stay-tour');

  return [
    ChinaHubSection(
      id: 'business',
      titleAr: 'أعمال وتأسيس',
      titleEn: 'Business & setup',
      titleZh: '商务与注册',
      tiles: [
        ...business.tiles,
        ...consult.tiles.where(
          (t) => t.id != 'property-consult' && t.id != 'property-advice',
        ),
      ],
    ),
    property,
    ChinaHubSection(
      id: 'visa-docs',
      titleAr: 'تأشيرات وإقامة ووثائق',
      titleEn: 'Visas, residence & docs',
      titleZh: '签证居留与文件',
      tiles: [...visa.tiles, ...legal.tiles],
    ),
    education,
    ChinaHubSection(
      id: 'sourcing-logistics',
      titleAr: 'توريد وفحص ولوجستيات',
      titleEn: 'Sourcing, QC & logistics',
      titleZh: '采购质检与物流',
      tiles: [...logistics.tiles, ...sourcing.tiles],
    ),
    stay,
  ];
}

List<ChinaHubSection> kChinaInHandSections() => [
      ChinaHubSection(
        id: 'business',
        titleAr: 'أعمال وتأسيس',
        titleEn: 'Business & setup',
        titleZh: '商务与注册',
        tiles: [
          // Single entry for all cities — do NOT re-add company-yiwu /
          // company-guangzhou / company-hk tiles to this China hub grid.
          _t(
            id: 'company-registration',
            parentSlug: 'business',
            labelAr: 'تسجيل شركات',
            labelEn: 'Company registration',
            labelZh: '公司注册',
            icon: 'domain',
            action: ChinaTileAction.companyRegistration,
            searchExtra: const [
              'شركة',
              'company',
              'ييوو',
              'قوانغ',
              'هونغ',
              'yiwu',
              'guangzhou',
              'hk',
            ],
          ),
          _t(
            id: 'china-exhibitions',
            parentSlug: 'business',
            labelAr: 'معارض الصين',
            labelEn: 'China exhibitions',
            labelZh: '中国展会',
            icon: 'storefront',
            action: ChinaTileAction.exhibitions,
            searchExtra: const ['معرض', 'fair', 'expo', 'كانتون'],
          ),
          _t(
            id: 'business-consult',
            parentSlug: 'business',
            labelAr: 'استشارات أعمال',
            labelEn: 'Business consulting',
            labelZh: '商务咨询',
            icon: 'biz',
          ),
          _t(
            id: 'vip-trip',
            parentSlug: 'business',
            labelAr: 'رحلات واستشارات VIP',
            labelEn: 'VIP trips & timed consults',
            labelZh: 'VIP行程与计时咨询',
            icon: 'vip',
            searchExtra: const ['vip', 'مؤقتة', 'timed'],
          ),
          _t(
            id: 'trademarks',
            parentSlug: 'business',
            labelAr: 'علامات تجارية',
            labelEn: 'Trademarks',
            labelZh: '商标',
            icon: 'verified',
          ),
          _t(
            id: 'marketing',
            parentSlug: 'business',
            labelAr: 'تسويق',
            labelEn: 'Marketing',
            labelZh: '营销',
          ),
          _t(
            id: 'programming',
            parentSlug: 'business',
            labelAr: 'برمجة',
            labelEn: 'Programming',
            labelZh: '编程',
          ),
          _t(
            id: 'design',
            parentSlug: 'business',
            labelAr: 'تصميم',
            labelEn: 'Design',
            labelZh: '设计',
          ),
          _t(
            id: 'accounting',
            parentSlug: 'business',
            labelAr: 'محاسبة',
            labelEn: 'Accounting',
            labelZh: '会计',
          ),
          _t(
            id: 'tax-consulting',
            parentSlug: 'business',
            labelAr: 'استشارات ضريبية',
            labelEn: 'Tax consulting',
            labelZh: '税务咨询',
          ),
        ],
      ),
      ChinaHubSection(
        id: 'consult',
        titleAr: 'استشارات الصين',
        titleEn: 'China consultations',
        titleZh: '中国咨询',
        tiles: [
          _t(
            id: 'legal',
            parentSlug: 'education',
            labelAr: 'استشارات قانونية',
            labelEn: 'Legal consulting',
            labelZh: '法律咨询',
            icon: 'gavel',
            searchExtra: const ['قانون', 'legal'],
          ),
          _t(
            id: 'property-consult',
            parentSlug: 'education',
            labelAr: 'استشارات عقارية',
            labelEn: 'Property consulting',
            labelZh: '房产咨询',
            icon: 'real_estate_agent',
          ),
          _t(
            id: 'property-advice',
            parentSlug: 'property',
            labelAr: 'نصيحة عقارية',
            labelEn: 'Property advice',
            labelZh: '房产建议',
            icon: 'real_estate_agent',
          ),
          _t(
            id: 'admin',
            parentSlug: 'education',
            labelAr: 'خدمات إدارية',
            labelEn: 'Admin services',
            labelZh: '行政服务',
          ),
        ],
      ),
      ChinaHubSection(
        id: 'property',
        titleAr: 'عقارات ومكاتب الصين',
        titleEn: 'China property & offices',
        titleZh: '中国房产与办公',
        tiles: [
          _t(
            id: 'sale',
            parentSlug: 'property',
            labelAr: 'عقارات للبيع',
            labelEn: 'Property for sale',
            labelZh: '房产出售',
            icon: 'sell',
          ),
          _t(
            id: 'houses',
            parentSlug: 'property',
            labelAr: 'منازل',
            labelEn: 'Houses',
            labelZh: '住宅',
          ),
          _t(
            id: 'apartments',
            parentSlug: 'property',
            labelAr: 'شقق',
            labelEn: 'Apartments',
            labelZh: '公寓',
          ),
          _t(
            id: 'offices',
            parentSlug: 'property',
            labelAr: 'مكاتب',
            labelEn: 'Offices',
            labelZh: '办公室',
            icon: 'business',
          ),
          _t(
            id: 'warehouses',
            parentSlug: 'property',
            labelAr: 'مستودعات',
            labelEn: 'Warehouses',
            labelZh: '仓库',
          ),
          _t(
            id: 'villas',
            parentSlug: 'property',
            labelAr: 'فلل',
            labelEn: 'Villas',
            labelZh: '别墅',
          ),
          _t(
            id: 'shared-housing',
            parentSlug: 'property',
            labelAr: 'سكن مشترك',
            labelEn: 'Shared housing',
            labelZh: '合租',
          ),
          _t(
            id: 'mortgage-finance',
            parentSlug: 'property',
            labelAr: 'تمويل عقاري',
            labelEn: 'Mortgage finance',
            labelZh: '房贷',
          ),
        ],
      ),
      ChinaHubSection(
        id: 'visa-gov',
        titleAr: 'تأشيرات وإقامة ووثائق',
        titleEn: 'Visas, residence & docs',
        titleZh: '签证居留与文件',
        tiles: [
          _t(
            id: 'visas',
            parentSlug: 'government',
            labelAr: 'تأشيرات الصين',
            labelEn: 'China visas',
            labelZh: '中国签证',
            icon: 'visa',
            searchExtra: const ['فيزا', 'visa'],
          ),
          _t(
            id: 'visa',
            parentSlug: 'travel',
            labelAr: 'تأشيرة سياحية',
            labelEn: 'Tourist visa',
            labelZh: '旅游签证',
            icon: 'visa',
          ),
          _t(
            id: 'residence',
            parentSlug: 'government',
            labelAr: 'إقامة',
            labelEn: 'Residence',
            labelZh: '居留',
            icon: 'home_work',
          ),
          _t(
            id: 'passports',
            parentSlug: 'government',
            labelAr: 'جوازات',
            labelEn: 'Passports',
            labelZh: '护照',
          ),
          _t(
            id: 'documents',
            parentSlug: 'government',
            labelAr: 'وثائق رسمية',
            labelEn: 'Official documents',
            labelZh: '官方文件',
          ),
          _t(
            id: 'document-attestation',
            parentSlug: 'government',
            labelAr: 'تصديق وثائق',
            labelEn: 'Document attestation',
            labelZh: '文件认证',
            icon: 'verified',
          ),
          _t(
            id: 'licenses',
            parentSlug: 'government',
            labelAr: 'رخص',
            labelEn: 'Licenses',
            labelZh: '许可证',
          ),
          _t(
            id: 'gov-services',
            parentSlug: 'government',
            labelAr: 'خدمات حكومية',
            labelEn: 'Gov services',
            labelZh: '政务服务',
          ),
          _t(
            id: 'tax-services',
            parentSlug: 'government',
            labelAr: 'خدمات ضريبية',
            labelEn: 'Tax services',
            labelZh: '税务服务',
          ),
          _t(
            id: 'social-insurance',
            parentSlug: 'government',
            labelAr: 'تأمين اجتماعي',
            labelEn: 'Social insurance',
            labelZh: '社保',
          ),
        ],
      ),
      ChinaHubSection(
        id: 'legal-docs',
        titleAr: 'ترجمة وتوثيق للصين',
        titleEn: 'Translation & notarization',
        titleZh: '翻译与公证',
        tiles: [
          _t(
            id: 'legal-translation',
            parentSlug: 'business',
            labelAr: 'ترجمة قانونية',
            labelEn: 'Legal translation',
            labelZh: '法律翻译',
            icon: 'translate',
          ),
          _t(
            id: 'contract-notarization',
            parentSlug: 'business',
            labelAr: 'توثيق عقود',
            labelEn: 'Contract notarization',
            labelZh: '合同公证',
            icon: 'gavel',
          ),
        ],
      ),
      ChinaHubSection(
        id: 'education',
        titleAr: 'لغة صينية وتعليم',
        titleEn: 'Chinese language & study',
        titleZh: '中文与学习',
        tiles: [
          _t(
            id: 'chinese-lang',
            parentSlug: 'education',
            labelAr: 'لغة صينية',
            labelEn: 'Chinese language',
            labelZh: '中文学习',
            icon: 'translate',
            searchExtra: const ['لغة', 'chinese', '中文'],
          ),
          _t(
            id: 'remote-study',
            parentSlug: 'education',
            labelAr: 'دراسة عن بُعد',
            labelEn: 'Remote study',
            labelZh: '远程学习',
          ),
          _t(
            id: 'scholarships',
            parentSlug: 'education',
            labelAr: 'منح دراسية',
            labelEn: 'Scholarships',
            labelZh: '奖学金',
            icon: 'school',
            action: ChinaTileAction.scholarships,
            searchExtra: const [
              'منحة',
              'csc',
              'scholarship',
              'جامعة',
              'CSC',
            ],
          ),
          _t(
            id: 'training-courses',
            parentSlug: 'education',
            labelAr: 'دورات تدريبية',
            labelEn: 'Training courses',
            labelZh: '培训课程',
          ),
          _t(
            id: 'education',
            parentSlug: 'education',
            labelAr: 'تعليم أكاديمي',
            labelEn: 'Academic education',
            labelZh: '学历教育',
            icon: 'school',
          ),
        ],
      ),
      ChinaHubSection(
        id: 'obic-logistics-tools',
        titleAr: 'لوجستيات أوبك · حاسبة واستيراد',
        titleEn: 'OBIC logistics · calculator',
        titleZh: 'OBIC 物流 · 计算器',
        tiles: [
          const ChinaHubTile(
            id: 'obic-import-calc',
            action: ChinaTileAction.logisticsTools,
            parentSlug: 'logistics',
            icon: 'calculate',
            labelAr: 'حاسبة تكاليف وأرباح الاستيراد',
            labelEn: 'Import cost & profit calculator',
            labelZh: '进口成本利润计算器',
            searchExtra: ['حاسبة', 'CBM', 'LCL', 'FCL', 'calculator'],
          ),
          const ChinaHubTile(
            id: 'obic-cbm-quote',
            action: ChinaTileAction.logisticsTools,
            parentSlug: 'logistics',
            icon: 'local_shipping',
            labelAr: 'احسب تكلفة الشحن (CBM/LCL·FCL)',
            labelEn: 'Freight estimate (CBM/LCL·FCL)',
            labelZh: '运费估算 CBM',
            searchExtra: ['شحن', 'CBM', 'freight'],
          ),
          const ChinaHubTile(
            id: 'obic-track-ship',
            action: ChinaTileAction.logisticsTools,
            parentSlug: 'logistics',
            icon: 'track',
            labelAr: 'تتبع شحنة',
            labelEn: 'Track shipment',
            labelZh: '运单跟踪',
            searchExtra: ['تتبع', 'tracking', 'TRK'],
          ),
          const ChinaHubTile(
            id: 'obic-ship-quote',
            action: ChinaTileAction.logisticsTools,
            parentSlug: 'logistics',
            icon: 'request_quote',
            labelAr: 'اطلب عرض سعر / احجز شحن',
            labelEn: 'Quote / book shipping',
            labelZh: '询价 / 订舱',
            searchExtra: ['عرض سعر', 'حجز', 'quote'],
          ),
        ],
      ),
      ChinaHubSection(
        id: 'sourcing',
        titleAr: 'توريد وفحص ولوجستيات',
        titleEn: 'Sourcing, QC & logistics',
        titleZh: '采购质检与物流',
        tiles: [
          _t(
            id: 'factories',
            parentSlug: 'shopping',
            labelAr: 'مصانع',
            labelEn: 'Factories',
            labelZh: '工厂',
            searchExtra: const ['مصنع', 'factory'],
          ),
          _t(
            id: 'products',
            parentSlug: 'shopping',
            labelAr: 'منتجات',
            labelEn: 'Products',
            labelZh: '产品',
          ),
          _t(
            id: 'quality-inspection',
            parentSlug: 'business',
            labelAr: 'فحص جودة',
            labelEn: 'Quality inspection',
            labelZh: '质量检验',
            icon: 'fact_check',
            searchExtra: const ['QC', 'جودة'],
          ),
          _t(
            id: 'intl-shipping',
            parentSlug: 'logistics',
            labelAr: 'شحن دولي',
            labelEn: 'Intl shipping',
            labelZh: '国际物流',
          ),
          _t(
            id: 'customs',
            parentSlug: 'logistics',
            labelAr: 'جمارك',
            labelEn: 'Customs',
            labelZh: '报关',
          ),
          _t(
            id: 'storage',
            parentSlug: 'logistics',
            labelAr: 'تخزين',
            labelEn: 'Storage',
            labelZh: '仓储',
          ),
          _t(
            id: 'shipment-tracking',
            parentSlug: 'logistics',
            labelAr: 'تتبع شحنة',
            labelEn: 'Shipment tracking',
            labelZh: '物流跟踪',
          ),
          _t(
            id: 'moving',
            parentSlug: 'logistics',
            labelAr: 'نقل عفش',
            labelEn: 'Moving',
            labelZh: '搬家',
          ),
        ],
      ),
      ChinaHubSection(
        id: 'stay-tour',
        titleAr: 'إقامة وجولات الصين',
        titleEn: 'Stay & China tours',
        titleZh: '住宿与中国游',
        tiles: [
          _t(
            id: 'visit-near-me',
            parentSlug: 'travel',
            labelAr: 'زيارة قريبة منك',
            labelEn: 'Visit near you',
            labelZh: '附近可访',
            icon: 'place',
            action: ChinaTileAction.visitNearMe,
            searchExtra: const [
              'مسجد',
              'mosque',
              'سوق',
              'market',
              'مكان',
              'visit',
              'قرب',
            ],
          ),
          _t(
            id: 'hotels',
            parentSlug: 'travel',
            labelAr: 'فنادق الصين',
            labelEn: 'China hotels',
            labelZh: '中国酒店',
            searchExtra: const ['فندق', 'hotel'],
          ),
          _t(
            id: 'tours',
            parentSlug: 'travel',
            labelAr: 'جولات',
            labelEn: 'Tours',
            labelZh: '旅游线路',
          ),
          _t(
            id: 'guide',
            parentSlug: 'travel',
            labelAr: 'مرشد',
            labelEn: 'Guide',
            labelZh: '导游',
          ),
          _t(
            id: 'attractions',
            parentSlug: 'travel',
            labelAr: 'معالم',
            labelEn: 'Attractions',
            labelZh: '景点',
          ),
          _t(
            id: 'travel-insurance',
            parentSlug: 'travel',
            labelAr: 'تأمين سفر',
            labelEn: 'Travel insurance',
            labelZh: '旅行保险',
          ),
        ],
      ),
    ];
