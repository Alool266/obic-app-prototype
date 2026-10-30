// Made by Dr Ali
// Curated country + city options for Profile pickers (China-first trial).

import 'obic_branches.dart';

class ProfileCountry {
  const ProfileCountry({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.nameZh,
  });

  final String code;
  final String nameEn;
  final String nameAr;
  final String nameZh;

  String label(String lang) {
    if (lang.startsWith('ar')) return nameAr;
    if (lang.startsWith('zh')) return nameZh;
    return nameEn;
  }
}

/// Common countries for trial; CN first.
const kProfileCountries = <ProfileCountry>[
  ProfileCountry(
    code: 'CN',
    nameEn: 'China',
    nameAr: 'الصين',
    nameZh: '中国',
  ),
  ProfileCountry(
    code: 'HK',
    nameEn: 'Hong Kong',
    nameAr: 'هونغ كونغ',
    nameZh: '香港',
  ),
  ProfileCountry(
    code: 'MO',
    nameEn: 'Macao',
    nameAr: 'ماكاو',
    nameZh: '澳门',
  ),
  ProfileCountry(
    code: 'YE',
    nameEn: 'Yemen',
    nameAr: 'اليمن',
    nameZh: '也门',
  ),
  ProfileCountry(
    code: 'SA',
    nameEn: 'Saudi Arabia',
    nameAr: 'السعودية',
    nameZh: '沙特阿拉伯',
  ),
  ProfileCountry(
    code: 'AE',
    nameEn: 'United Arab Emirates',
    nameAr: 'الإمارات',
    nameZh: '阿联酋',
  ),
  ProfileCountry(
    code: 'EG',
    nameEn: 'Egypt',
    nameAr: 'مصر',
    nameZh: '埃及',
  ),
  ProfileCountry(
    code: 'US',
    nameEn: 'United States',
    nameAr: 'الولايات المتحدة',
    nameZh: '美国',
  ),
  ProfileCountry(
    code: 'GB',
    nameEn: 'United Kingdom',
    nameAr: 'المملكة المتحدة',
    nameZh: '英国',
  ),
];

/// China-first cities: OBIC branches + major hubs.
const kChinaCities = <String>[
  'Yiwu',
  'Guangzhou',
  'Foshan',
  'Hangzhou',
  'Haikou',
  'Sanya',
  'Shanghai',
  'Beijing',
  'Shenzhen',
  'Dongguan',
  'Ningbo',
  'Wenzhou',
  'Jinhua',
  'Chengdu',
  'Chongqing',
  'Wuhan',
  'Nanjing',
  'Xi\'an',
  'Qingdao',
  'Xiamen',
];

const kHkCities = <String>['Hong Kong', 'Kowloon', 'New Territories'];
const kMoCities = <String>['Macao', 'Taipa', 'Coloane'];
const kYeCities = <String>['Sana\'a', 'Aden', 'Taiz', 'Hodeidah'];
const kSaCities = <String>['Riyadh', 'Jeddah', 'Dammam', 'Mecca', 'Medina'];
const kAeCities = <String>['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman'];
const kEgCities = <String>['Cairo', 'Alexandria', 'Giza'];
const kUsCities = <String>['New York', 'Los Angeles', 'Chicago', 'Houston'];
const kGbCities = <String>['London', 'Manchester', 'Birmingham'];

List<String> citiesForCountry(String? countryCode) {
  final code = (countryCode ?? '').trim().toUpperCase();
  switch (code) {
    case 'CN':
      // Prefer branch order, then extras (dedupe).
      final out = <String>[];
      final seen = <String>{};
      for (final b in kObicBranches) {
        if (b == 'Hainan') {
          for (final c in ['Haikou', 'Sanya']) {
            if (seen.add(c)) out.add(c);
          }
          continue;
        }
        if (b == 'Yemen') continue;
        if (seen.add(b)) out.add(b);
      }
      for (final c in kChinaCities) {
        if (seen.add(c)) out.add(c);
      }
      return out;
    case 'HK':
      return List<String>.from(kHkCities);
    case 'MO':
      return List<String>.from(kMoCities);
    case 'YE':
      return List<String>.from(kYeCities);
    case 'SA':
      return List<String>.from(kSaCities);
    case 'AE':
      return List<String>.from(kAeCities);
    case 'EG':
      return List<String>.from(kEgCities);
    case 'US':
      return List<String>.from(kUsCities);
    case 'GB':
      return List<String>.from(kGbCities);
    default:
      return const [];
  }
}

ProfileCountry? findCountryByCode(String? code) {
  if (code == null || code.trim().isEmpty) return null;
  final upper = code.trim().toUpperCase();
  for (final c in kProfileCountries) {
    if (c.code == upper) return c;
  }
  return null;
}

/// Match placemark / free-text country to a curated ISO code.
String? matchCountryCode({
  String? isoCountryCode,
  String? countryName,
}) {
  final iso = isoCountryCode?.trim().toUpperCase();
  if (iso != null && iso.length == 2) {
    if (findCountryByCode(iso) != null) return iso;
  }
  final name = (countryName ?? '').trim().toLowerCase();
  if (name.isEmpty) return iso != null && iso.length == 2 ? iso : null;
  for (final c in kProfileCountries) {
    if (c.nameEn.toLowerCase() == name ||
        c.nameZh == countryName ||
        c.nameAr == countryName) {
      return c.code;
    }
  }
  if (name.contains('china') || name.contains('中国')) return 'CN';
  if (name.contains('hong kong') || name.contains('香港')) return 'HK';
  if (name.contains('macao') || name.contains('macau') || name.contains('澳门')) {
    return 'MO';
  }
  return iso != null && iso.length == 2 ? iso : null;
}

/// Best-effort city match against curated list for [countryCode].
String? matchCityName({
  required String? countryCode,
  String? locality,
  String? subAdministrativeArea,
  String? administrativeArea,
}) {
  final cities = citiesForCountry(countryCode);
  if (cities.isEmpty) {
    return (locality?.trim().isNotEmpty == true)
        ? locality!.trim()
        : (administrativeArea?.trim().isNotEmpty == true
            ? administrativeArea!.trim()
            : null);
  }
  final candidates = <String>[
    if (locality != null) locality,
    if (subAdministrativeArea != null) subAdministrativeArea,
    if (administrativeArea != null) administrativeArea,
  ].map((s) => s.trim()).where((s) => s.isNotEmpty);

  for (final cand in candidates) {
    for (final city in cities) {
      if (city.toLowerCase() == cand.toLowerCase()) return city;
    }
  }
  for (final cand in candidates) {
    final lower = cand.toLowerCase();
    for (final city in cities) {
      if (lower.contains(city.toLowerCase()) ||
          city.toLowerCase().contains(lower)) {
        return city;
      }
    }
  }
  // Hainan province → Haikou default for branch alignment.
  for (final cand in candidates) {
    if (cand.toLowerCase().contains('hainan') || cand.contains('海南')) {
      return 'Haikou';
    }
  }
  return candidates.isEmpty ? null : candidates.first;
}

bool isChinaRegionCode(String? code) {
  final c = (code ?? '').trim().toUpperCase();
  return c == 'CN' || c == 'HK' || c == 'MO';
}

bool isChinaMobile(String raw) {
  var digits = raw.trim().replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.startsWith('+')) digits = digits.substring(1);
  if (digits.startsWith('0086')) digits = digits.substring(4);
  if (digits.startsWith('86') && digits.length == 13) {
    digits = digits.substring(2);
  }
  return RegExp(r'^1[3-9]\d{9}$').hasMatch(digits);
}
