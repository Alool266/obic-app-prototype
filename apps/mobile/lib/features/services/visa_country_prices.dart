// Made by Dr Ali
// Boss-approved visa prices (Form1 · 报价.xlsx · 17 Sep 2026).
// Display/reference — quote uses rate on pricing day.

class ObicVisaPrice {
  const ObicVisaPrice({
    required this.countryAr,
    required this.countryEn,
    required this.priceLabelAr,
    required this.priceLabelEn,
    this.offline = false,
  });

  final String countryAr;
  final String countryEn;
  final String priceLabelAr;
  final String priceLabelEn;
  final bool offline;
}

/// Online visas — fixed RMB (boss table).
const kObicVisaOnline = <ObicVisaPrice>[
  ObicVisaPrice(countryAr: 'هونغ كونغ', countryEn: 'Hong Kong', priceLabelAr: '1265¥', priceLabelEn: '¥1265'),
  ObicVisaPrice(countryAr: 'إندونيسيا 1', countryEn: 'Indonesia 1', priceLabelAr: '1515¥', priceLabelEn: '¥1515'),
  ObicVisaPrice(countryAr: 'إندونيسيا 2', countryEn: 'Indonesia 2', priceLabelAr: '1950¥', priceLabelEn: '¥1950'),
  ObicVisaPrice(countryAr: 'إندونيسيا 3', countryEn: 'Indonesia 3', priceLabelAr: '1645¥', priceLabelEn: '¥1645'),
  ObicVisaPrice(countryAr: 'تايلاند', countryEn: 'Thailand', priceLabelAr: '1200¥', priceLabelEn: '¥1200'),
  ObicVisaPrice(countryAr: 'تايلاند DTV', countryEn: 'Thailand DTV', priceLabelAr: '3260¥', priceLabelEn: '¥3260'),
  ObicVisaPrice(countryAr: 'الهند', countryEn: 'India', priceLabelAr: '1880¥', priceLabelEn: '¥1880'),
  ObicVisaPrice(countryAr: 'كمبوديا', countryEn: 'Cambodia', priceLabelAr: '1176¥', priceLabelEn: '¥1176'),
  ObicVisaPrice(countryAr: 'فيتنام', countryEn: 'Vietnam', priceLabelAr: '1100¥', priceLabelEn: '¥1100'),
  ObicVisaPrice(countryAr: 'تركيا', countryEn: 'Turkey', priceLabelAr: '1468¥', priceLabelEn: '¥1468'),
  ObicVisaPrice(countryAr: 'العراق الجنوبي', countryEn: 'Southern Iraq', priceLabelAr: '2168¥', priceLabelEn: '¥2168'),
  ObicVisaPrice(countryAr: 'صربيا', countryEn: 'Serbia', priceLabelAr: '1660¥', priceLabelEn: '¥1660'),
  ObicVisaPrice(countryAr: 'قيرغيزستان', countryEn: 'Kyrgyzstan', priceLabelAr: '1358¥', priceLabelEn: '¥1358'),
  ObicVisaPrice(countryAr: 'أذربيجان', countryEn: 'Azerbaijan', priceLabelAr: '1198¥', priceLabelEn: '¥1198'),
  ObicVisaPrice(countryAr: 'اليابان (جينهوا)', countryEn: 'Japan (Jinhua)', priceLabelAr: '2270¥', priceLabelEn: '¥2270'),
  ObicVisaPrice(countryAr: 'اليابان (قوانغتشو)', countryEn: 'Japan (Guangzhou)', priceLabelAr: '2155¥', priceLabelEn: '¥2155'),
  ObicVisaPrice(countryAr: 'اليابان (بكين/خنان)', countryEn: 'Japan (Beijing/Henan)', priceLabelAr: '2325¥', priceLabelEn: '¥2325'),
  ObicVisaPrice(countryAr: 'كندا', countryEn: 'Canada', priceLabelAr: '2090¥', priceLabelEn: '¥2090'),
  ObicVisaPrice(countryAr: 'ماليزيا', countryEn: 'Malaysia', priceLabelAr: '1178¥', priceLabelEn: '¥1178'),
  ObicVisaPrice(countryAr: 'أستراليا', countryEn: 'Australia', priceLabelAr: '2606¥', priceLabelEn: '¥2606'),
  ObicVisaPrice(countryAr: 'قطر', countryEn: 'Qatar', priceLabelAr: '1162¥', priceLabelEn: '¥1162'),
  ObicVisaPrice(countryAr: 'السعودية (تجاري)', countryEn: 'Saudi (business)', priceLabelAr: '2316¥', priceLabelEn: '¥2316'),
  ObicVisaPrice(countryAr: 'عمان', countryEn: 'Oman', priceLabelAr: '1552¥', priceLabelEn: '¥1552'),
  ObicVisaPrice(countryAr: 'نيوزيلندا', countryEn: 'New Zealand', priceLabelAr: '3050¥', priceLabelEn: '¥3050'),
  ObicVisaPrice(countryAr: 'بريطانيا', countryEn: 'UK', priceLabelAr: '2576¥', priceLabelEn: '¥2576'),
  ObicVisaPrice(countryAr: 'بنغلاديش', countryEn: 'Bangladesh', priceLabelAr: '1536¥', priceLabelEn: '¥1536'),
  ObicVisaPrice(countryAr: 'بيرو', countryEn: 'Peru', priceLabelAr: '1230¥', priceLabelEn: '¥1230'),
  ObicVisaPrice(countryAr: 'لاوس', countryEn: 'Laos', priceLabelAr: '1216¥', priceLabelEn: '¥1216'),
  ObicVisaPrice(countryAr: 'ميانمار', countryEn: 'Myanmar', priceLabelAr: '1310¥', priceLabelEn: '¥1310'),
  ObicVisaPrice(countryAr: 'سريلانكا', countryEn: 'Sri Lanka', priceLabelAr: '1360¥', priceLabelEn: '¥1360'),
  ObicVisaPrice(countryAr: 'السعودية (دعوة)', countryEn: 'Saudi (invitation)', priceLabelAr: '1200¥', priceLabelEn: '¥1200'),
  ObicVisaPrice(countryAr: 'دبي', countryEn: 'Dubai', priceLabelAr: '2300¥', priceLabelEn: '¥2300'),
  ObicVisaPrice(countryAr: 'تونس', countryEn: 'Tunisia', priceLabelAr: '1950/2600¥', priceLabelEn: '¥1950/2600'),
];

/// Offline visas — base + MBC (boss table).
const kObicVisaOffline = <ObicVisaPrice>[
  ObicVisaPrice(countryAr: 'كوريا', countryEn: 'Korea', priceLabelAr: '1066¥ + 400 MBC', priceLabelEn: '¥1066 + ¥400 MBC', offline: true),
  ObicVisaPrice(countryAr: 'إيطاليا (شنغهاي)', countryEn: 'Italy (Shanghai)', priceLabelAr: '1326¥ + 822 MBC', priceLabelEn: '¥1326 + ¥822 MBC', offline: true),
  ObicVisaPrice(countryAr: 'فرنسا (شنغهاي)', countryEn: 'France (Shanghai)', priceLabelAr: '1326¥ + 957 MBC', priceLabelEn: '¥1326 + ¥957 MBC', offline: true),
  ObicVisaPrice(countryAr: 'اليونان (شنغهاي)', countryEn: 'Greece (Shanghai)', priceLabelAr: '1576¥ + 1150 MBC', priceLabelEn: '¥1576 + ¥1150 MBC', offline: true),
  ObicVisaPrice(countryAr: 'إسبانيا (شنغهاي)', countryEn: 'Spain (Shanghai)', priceLabelAr: '1451¥ + 730 MBC', priceLabelEn: '¥1451 + ¥730 MBC', offline: true),
  ObicVisaPrice(countryAr: 'إسبانيا (قوانغتشو)', countryEn: 'Spain (Guangzhou)', priceLabelAr: '1326¥ + 1000 MBC', priceLabelEn: '¥1326 + ¥1000 MBC', offline: true),
  ObicVisaPrice(countryAr: 'أمريكا', countryEn: 'USA', priceLabelAr: '2626¥', priceLabelEn: '¥2626', offline: true),
  ObicVisaPrice(countryAr: 'ألمانيا', countryEn: 'Germany', priceLabelAr: '1483¥ + 740 MBC', priceLabelEn: '¥1483 + ¥740 MBC', offline: true),
  ObicVisaPrice(countryAr: 'اليابان (نينغبو)', countryEn: 'Japan (Ningbo)', priceLabelAr: '1156¥ + 545 MBC', priceLabelEn: '¥1156 + ¥545 MBC', offline: true),
  ObicVisaPrice(countryAr: 'سنغافورة', countryEn: 'Singapore', priceLabelAr: '1156¥ + 300 MBC', priceLabelEn: '¥1156 + ¥300 MBC', offline: true),
  ObicVisaPrice(countryAr: 'اليمن', countryEn: 'Yemen', priceLabelAr: '950¥ + 330 MBC', priceLabelEn: '¥950 + ¥330 MBC', offline: true),
  ObicVisaPrice(countryAr: 'بريطانيا (أوفلاين)', countryEn: 'UK (offline)', priceLabelAr: '1326¥ + 1200 MBC', priceLabelEn: '¥1326 + ¥1200 MBC', offline: true),
];

String visaPriceHint(String langCode) {
  final ar = langCode.startsWith('ar');
  final zh = langCode.startsWith('zh');
  if (ar) {
    return 'أسعار معتمدة حسب الدولة (أونلاين من 1100¥ · أوفلاين من 950¥+MBC). يُراجع سعر الصرف يوم التسعير.';
  }
  if (zh) {
    return '按国家核定价格（线上¥1100起 · 线下¥950+MBC起）。签证当天核对汇率。';
  }
  return 'Approved by-country prices (online from ¥1100 · offline from ¥950+MBC). Check FX on pricing day.';
}
