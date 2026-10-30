// Made by Dr Ali — OBIC branches with coordinates for distance sorting.

import 'geo_utils.dart';
import 'obic_org.dart';

class ObicBranch {
  const ObicBranch({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.countryCode = '',
  });

  final String name;
  final double latitude;
  final double longitude;
  final String countryCode;

  double distanceKmFrom(double? lat, double? lng) {
    if (lat == null || lng == null) return double.infinity;
    return haversineKm(lat, lng, latitude, longitude);
  }

  String distanceLabel(double? lat, double? lng, {required String langCode}) {
    final display = branchDisplayName(name, langCode);
    final km = distanceKmFrom(lat, lng);
    if (!km.isFinite) return display;
    final zh = langCode.startsWith('zh');
    final ar = langCode.startsWith('ar');
    return '$display · ${formatDistanceKm(km, zh: zh, ar: ar)}';
  }
}

/// Form2 order: Yiwu (primary) → Guangzhou → Foshan → Hangzhou → Hainan → Yemen → Shanghai.
const kObicBranchRecords = [
  ObicBranch(name: 'Yiwu', latitude: 29.306, longitude: 120.075, countryCode: 'CN'),
  ObicBranch(name: 'Guangzhou', latitude: 23.129, longitude: 113.264, countryCode: 'CN'),
  ObicBranch(name: 'Foshan', latitude: 23.022, longitude: 113.122, countryCode: 'CN'),
  ObicBranch(name: 'Hangzhou', latitude: 30.274, longitude: 120.155, countryCode: 'CN'),
  ObicBranch(name: 'Hainan', latitude: 20.044, longitude: 110.199, countryCode: 'CN'),
  ObicBranch(name: 'Yemen', latitude: 15.369, longitude: 44.191, countryCode: 'YE'),
  ObicBranch(name: 'Shanghai', latitude: 31.230, longitude: 121.473, countryCode: 'CN'),
];

const kObicBranches = [
  'Yiwu',
  'Guangzhou',
  'Foshan',
  'Hangzhou',
  'Hainan',
  'Yemen',
  'Shanghai',
];

const kObicBranchOptions = [
  ...kObicBranches,
  'All branches',
  'HQ (temp)',
];

const kObicDeskTitles = [
  'General Manager / Owner',
  'Branch Manager',
  'Secretary (GM)',
  'HR Manager',
  'Local Accountant',
  'Marketing Manager — All Services',
  'General Marketing Manager',
  'Foreign Marketing Manager',
  'Visa Marketing — China',
  'Visa Marketing — Foreign',
  'Visa Department Manager',
  'Visa Group Assistant',
  'Passports / Client Data',
  'Foreign Company Registration',
  'Trademarks & Operations',
  'China Company Registration',
  'External Accounts',
  'Purchasing Manager',
  'Purchasing — AC & Furniture',
  'Purchasing — Beauty',
  'Purchasing — Auto Parts',
  'Purchasing — Phones',
  'Media / Photography',
  'Property Manager',
  'Software Manager',
  'Software Deputy',
  'AC Marketing',
  'Scholarships Marketing',
  'Scholarships Group Lead',
  'Scholarships Operations',
  'Shipping & Logistics Manager',
  'Banks / Visa Escort',
  'Trade Department Manager',
  'Marketing Manager',
  'Marketer',
  'Data Entry',
  'Finance',
  'Secretary',
  'Cashier',
  'Scholarships Desk',
  'General Employee',
  'Head of Administration',
];

List<String> get obicBranches => List.unmodifiable(kObicBranches);

List<String> get obicBranchOptions => List.unmodifiable(kObicBranchOptions);

List<String> get obicDeskTitles => List.unmodifiable(kObicDeskTitles);

List<ObicBranch> branchesSortedByDistance(
  double? lat,
  double? lng, {
  String? countryCode,
}) {
  var list = List<ObicBranch>.from(kObicBranchRecords);
  if (countryCode != null && countryCode.isNotEmpty) {
    final c = countryCode.toUpperCase();
    final local = list.where((b) => b.countryCode == c).toList();
    if (local.isNotEmpty) list = local;
  }
  list.sort((a, b) {
    final da = a.distanceKmFrom(lat, lng);
    final db = b.distanceKmFrom(lat, lng);
    return da.compareTo(db);
  });
  return list;
}

ObicBranch? nearestBranch(double? lat, double? lng, {String? countryCode}) {
  final sorted = branchesSortedByDistance(lat, lng, countryCode: countryCode);
  return sorted.isEmpty ? null : sorted.first;
}
