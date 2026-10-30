// Made by Dr Ali
// Customer office page — opened from Home "Offices near you" chips.

import 'package:flutter/material.dart';

import '../../core/geo_utils.dart';
import '../../core/obic_branches.dart';
import '../../core/obic_org.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/obic_logo.dart';
import '../messages/chat_location_body.dart';

class BranchOfficeScreen extends StatelessWidget {
  const BranchOfficeScreen({
    super.key,
    required this.branch,
    required this.langCode,
    this.userLat,
    this.userLng,
  });

  final ObicBranch branch;
  final String langCode;
  final double? userLat;
  final double? userLng;

  @override
  Widget build(BuildContext context) {
    final ar = langCode.startsWith('ar');
    final zh = langCode.startsWith('zh');
    final org = _org(branch.name);
    final name = branchDisplayName(branch.name, langCode);
    final km = branch.distanceKmFrom(userLat, userLng);
    final distance = km.isFinite
        ? formatDistanceKm(km, zh: zh, ar: ar)
        : null;
    final info = _copy(branch.name, ar: ar, zh: zh);
    final primary = org?.isPrimary ?? branch.name == 'Yiwu';

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 188,
            backgroundColor: ObicColors.navy,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ObicColors.navyDeep,
                      ObicColors.navy,
                      Color(0xFF1A4F9C),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const ObicLogo(size: 28, borderRadius: 8),
                            const SizedBox(width: 8),
                            Text(
                              'OBIC',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            if (primary) ...[
                              const SizedBox(width: 8),
                              _pill(
                                ar
                                    ? 'المكتب الرئيسي'
                                    : zh
                                        ? '总部'
                                        : 'Head office',
                              ),
                            ],
                          ],
                        ),
                        const Spacer(),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info.place,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (distance != null)
                    _card(
                      context,
                      child: Row(
                        children: [
                          const Icon(Icons.near_me_rounded, color: ObicColors.blue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ar
                                  ? 'يبعد عنك $distance'
                                  : zh
                                      ? '距你 $distance'
                                      : '$distance from you',
                              style: TextStyle(
                                color: ObicColors.inkOf(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  _card(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ar ? 'عن المكتب' : zh ? '关于办公室' : 'About this office',
                          style: TextStyle(
                            color: ObicColors.inkOf(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          info.about,
                          style: TextStyle(
                            color: ObicColors.inkOf(context),
                            height: 1.45,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ar ? 'ماذا نخدم هنا' : zh ? '这里可办理' : 'What you can do here',
                          style: TextStyle(
                            color: ObicColors.inkOf(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in info.services)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: ObicColors.blueSoftOf(context),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    color: ObicColors.blue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (org != null) ...[
                    const SizedBox(height: 12),
                    _card(
                      context,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: ObicColors.navy,
                            child: Text(
                              org.managerAr.characters.isEmpty
                                  ? 'O'
                                  : org.managerAr.characters.last,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ar
                                      ? 'مدير الفرع'
                                      : zh
                                          ? '分公司负责人'
                                          : 'Branch lead',
                                  style: TextStyle(
                                    color: ObicColors.mutedOf(context),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  org.managerAr,
                                  style: TextStyle(
                                    color: ObicColors.inkOf(context),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _openObicMap(context, branch, name),
                    style: FilledButton.styleFrom(
                      backgroundColor: ObicColors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.map_rounded),
                    label: Text(
                      ar ? 'افتح الموقع على الخريطة' : zh ? '在地图中打开' : 'Open on the map',
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

  static Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ObicColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ObicColors.lineOf(context).withValues(alpha: 0.7),
        ),
      ),
      child: child,
    );
  }
}

ObicOrgBranch? _org(String id) {
  for (final b in kObicOrgBranches) {
    if (b.id == id) return b;
  }
  return null;
}

class _BranchCopy {
  const _BranchCopy({
    required this.place,
    required this.about,
    required this.services,
  });
  final String place;
  final String about;
  final List<String> services;
}

_BranchCopy _copy(String id, {required bool ar, required bool zh}) {
  String pick(String en, String arText, String zhText) =>
      ar ? arText : zh ? zhText : en;

  switch (id) {
    case 'Yiwu':
      return _BranchCopy(
        place: pick('Yiwu, Zhejiang', 'إيوو، تشجيانغ', '浙江 · 义乌'),
        about: pick(
          'OBIC head office. Start visas, company setup, purchasing, shipping, and day-to-day China support from here. Other branches coordinate with Yiwu.',
          'المكتب الرئيسي لـ OBIC. من هنا تبدأ التأشيرات وتأسيس الشركات والمشتريات والشحن وخدمات الحياة اليومية في الصين. الفروع الأخرى تنسّق مع إيوو.',
          'OBIC 总部。签证、公司注册、采购、物流和在华日常事务从这里开始。其他分公司与义乌协同。',
        ),
        services: [
          pick('Visas', 'تأشيرات', '签证'),
          pick('Companies', 'شركات', '公司注册'),
          pick('Purchasing', 'مشتريات', '采购'),
          pick('Shipping', 'شحن', '物流'),
          pick('Property', 'عقارات', '房产'),
          pick('Scholarships', 'منح', '奖学金'),
        ],
      );
    case 'Guangzhou':
      return _BranchCopy(
        place: pick('Guangzhou, Guangdong', 'قوانغتشو، قوانغدونغ', '广东 · 广州'),
        about: pick(
          'South China desk for trade, company accounts, property, and visa escort with banks. Good if you are already in the Pearl River Delta.',
          'مكتب جنوب الصين للتجارة وحسابات الشركات والعقارات ومرافقة التأشيرة والبنوك. مناسب إذا كنت في دلتا نهر اللؤلؤ.',
          '华南窗口：贸易、公司账户、房产，以及银行与签证陪同。人在珠三角时更方便。',
        ),
        services: [
          pick('Trade', 'تجارة', '贸易'),
          pick('Visa escort', 'مرافقة فيزا', '签证陪同'),
          pick('Banks', 'بنوك', '银行'),
          pick('Property', 'عقارات', '房产'),
        ],
      );
    case 'Hangzhou':
      return _BranchCopy(
        place: pick('Hangzhou, Zhejiang', 'هانغتشو، تشجيانغ', '浙江 · 杭州'),
        about: pick(
          'Zhejiang capital branch. Visas and business help for clients around Hangzhou, with Yiwu HQ behind the file.',
          'فرع عاصمة تشجيانغ. تأشيرات ودعم أعمال لمن حول هانغتشو، مع المكتب الرئيسي في إيوو خلف الملف.',
          '浙江省会分公司。为杭州及周边客户办理签证和商务事务，档案由义乌总部协同。',
        ),
        services: [
          pick('Visas', 'تأشيرات', '签证'),
          pick('Business', 'أعمال', '商务'),
          pick('Daily China', 'حياة يومية', '在华事务'),
        ],
      );
    case 'Shanghai':
      return _BranchCopy(
        place: pick('Shanghai', 'شنغهاي', '上海'),
        about: pick(
          'East China branch for company and trade support, visas, and clients based in Shanghai.',
          'فرع شرق الصين لدعم الشركات والتجارة والتأشيرات وللعملاء المقيمين في شنغهاي.',
          '华东分公司：公司与贸易支持、签证，服务常驻上海的客户。',
        ),
        services: [
          pick('Companies', 'شركات', '公司'),
          pick('Trade', 'تجارة', '贸易'),
          pick('Visas', 'تأشيرات', '签证'),
        ],
      );
    case 'Foshan':
      return _BranchCopy(
        place: pick('Foshan, Guangdong', 'فوشان، قوانغدونغ', '广东 · 佛山'),
        about: pick(
          'Pearl River branch focused on visas and local follow-up, linked to the Guangzhou and Yiwu teams.',
          'فرع دلتا النهر يركّز على التأشيرات والمتابعة المحلية، مرتبط بفريقَي قوانغتشو وإيوو.',
          '珠三角分公司，侧重签证与本地跟进，与广州、义乌团队联动。',
        ),
        services: [
          pick('Visas', 'تأشيرات', '签证'),
          pick('Local follow-up', 'متابعة محلية', '本地跟进'),
        ],
      );
    case 'Hainan':
      return _BranchCopy(
        place: pick('Hainan', 'هاينان', '海南'),
        about: pick(
          'Island branch for visas, accounts, and clients who need a local OBIC contact in Hainan.',
          'فرع الجزيرة للتأشيرات والحسابات ولمن يحتاج تواصلاً محلياً مع OBIC في هاينان.',
          '海南分公司：签证、账户，以及需要本地对接的客户。',
        ),
        services: [
          pick('Visas', 'تأشيرات', '签证'),
          pick('Accounts', 'حسابات', '账户'),
        ],
      );
    case 'Yemen':
      return _BranchCopy(
        place: pick('Yemen', 'اليمن', '也门'),
        about: pick(
          'OBIC’s Yemen desk for scholarships and foreign-trade marketing, coordinated with the China offices.',
          'مكتب OBIC في اليمن للمنح وتسويق التجارة الخارجية، بالتنسيق مع مكاتب الصين.',
          '也门窗口：奖学金与外贸推广，与中国办公室协同。',
        ),
        services: [
          pick('Scholarships', 'منح', '奖学金'),
          pick('Foreign trade', 'تجارة خارجية', '外贸'),
        ],
      );
    default:
      return _BranchCopy(
        place: branchDisplayName(id, zh ? 'zh' : ar ? 'ar' : 'en'),
        about: pick(
          'OBIC office. Message the team in the app for appointments and which service to start.',
          'مكتب OBIC. راسل الفريق داخل التطبيق للمواعيد ومعرفة الخدمة المناسبة.',
          'OBIC 办公室。在应用里联系团队预约并确认要办的服务。',
        ),
        services: [
          pick('Visas', 'تأشيرات', '签证'),
          pick('Business', 'أعمال', '商务'),
        ],
      );
  }
}

void _openObicMap(BuildContext context, ObicBranch branch, String name) {
  final lang = Localizations.localeOf(context).languageCode;
  showLocationMapSheet(
    context,
    ParsedLocationShare(
      label: name,
      lat: branch.latitude,
      lng: branch.longitude,
      preferChina: true,
      links: [
        MapLinkRow(
          label: lang == 'zh' ? '高德地图' : 'Amap',
          url: amapMarkerUrl(lat: branch.latitude, lng: branch.longitude, name: name),
        ),
        MapLinkRow(
          label: 'Apple Maps',
          url: appleMapsUrl(lat: branch.latitude, lng: branch.longitude, name: name),
        ),
        MapLinkRow(
          label: 'Google Maps',
          url: googleMapsUrl(lat: branch.latitude, lng: branch.longitude),
        ),
      ],
    ),
  );
}

/// Every OBIC office, nearest first.
class BranchDirectoryScreen extends StatelessWidget {
  const BranchDirectoryScreen({
    super.key,
    required this.langCode,
    this.userLat,
    this.userLng,
  });

  final String langCode;
  final double? userLat;
  final double? userLng;

  @override
  Widget build(BuildContext context) {
    final ar = langCode.startsWith('ar');
    final zh = langCode.startsWith('zh');
    final branches = branchesSortedByDistance(userLat, userLng);
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(ar ? 'مكاتب OBIC' : zh ? 'OBIC 办公室' : 'OBIC offices'),
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: branches.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final b = branches[i];
          final org = _org(b.name);
          return Material(
            color: ObicColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BranchOfficeScreen(
                      branch: b,
                      langCode: langCode,
                      userLat: userLat,
                      userLng: userLng,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: ObicColors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.distanceLabel(userLat, userLng, langCode: langCode),
                            style: TextStyle(
                              color: ObicColors.inkOf(context),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (org?.isPrimary == true)
                            Text(
                              ar ? 'المكتب الرئيسي' : zh ? '总部' : 'Head office',
                              style: const TextStyle(
                                color: ObicColors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: ObicColors.mutedOf(context)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
