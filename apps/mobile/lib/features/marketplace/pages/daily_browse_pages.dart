// Made by Dr Ali
// Meituan-style daily category screens — distinct UIs (food ≠ pharmacy ≠ errands).

import 'package:flutter/material.dart';

import '../../../theme/obic_colors.dart';
import '../../../widgets/obic_cached_image.dart';
import '../../auth/auth_controller.dart';
import '../marketplace_api.dart';
import '../marketplace_models.dart';
import 'marketplace_chrome.dart';
import 'merchant_shop_page.dart';

class FoodBrowsePage extends StatefulWidget {
  const FoodBrowsePage({
    super.key,
    required this.authController,
    required this.langCode,
    this.filterHint,
  });
  final AuthController authController;
  final String langCode;
  final String? filterHint;

  @override
  State<FoodBrowsePage> createState() => _FoodBrowsePageState();
}

class _FoodBrowsePageState extends State<FoodBrowsePage> {
  late Future<List<MerchantListing>> _future =
      marketplaceRepo.listMerchants(MarketplaceVertical.food);
  String _q = '';
  String _chip = 'all';

  @override
  void initState() {
    super.initState();
    final hint = widget.filterHint?.toLowerCase() ?? '';
    if (hint.contains('chinese') || hint.contains('صين')) _chip = 'chinese';
    if (hint.contains('sweet') || hint.contains('حل')) _chip = 'sweets';
    if (hint.contains('drink') || hint.contains('مشروب')) _chip = 'drinks';
    if (hint.contains('deliver') || hint.contains('توصيل')) _chip = 'delivery';
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.langCode;
    final chips = <(String id, String label)>[
      ('all', mp(lang, 'الكل', 'All', '全部')),
      ('arabic', mp(lang, 'عربي', 'Arabic', '阿拉伯')),
      ('chinese', mp(lang, 'صيني', 'Chinese', '中餐')),
      ('drinks', mp(lang, 'مشروبات', 'Drinks', '饮品')),
      ('delivery', mp(lang, 'توصيل', 'Delivery', '外卖')),
      ('sweets', mp(lang, 'حلويات', 'Sweets', '甜品')),
    ];
    return MarketplaceScaffold(
      title: mp(lang, 'أكل ومشروبات', 'Food & drinks', '餐饮美食'),
      accent: const Color(0xFFE11D48),
      searchHint: mp(lang, 'مطعم أو مطبخ…', 'Restaurant or cuisine…', '餐厅或菜系…'),
      onSearch: (v) => setState(() => _q = v.trim().toLowerCase()),
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
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            ? const Color(0xFFE11D48)
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
      body: FutureBuilder<List<MerchantListing>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              snap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          var items = snap.data ?? const <MerchantListing>[];
          if (_q.isNotEmpty) {
            items = items
                .where((m) =>
                    m.nameEn.toLowerCase().contains(_q) ||
                    m.nameAr.contains(_q) ||
                    m.tags.any((t) => t.toLowerCase().contains(_q)))
                .toList();
          }
          if (_chip != 'all') {
            items = items.where((m) {
              final blob =
                  '${m.nameEn} ${m.nameAr} ${m.tags.join(' ')}'.toLowerCase();
              return switch (_chip) {
                'arabic' =>
                  blob.contains('arab') ||
                      blob.contains('عربي') ||
                      blob.contains('mandi') ||
                      blob.contains('مندي'),
                'chinese' =>
                  blob.contains('chin') ||
                      blob.contains('صين') ||
                      blob.contains('noodle') ||
                      blob.contains('ramen'),
                'delivery' =>
                  blob.contains('deliver') ||
                      blob.contains('توصيل') ||
                      blob.contains('外卖'),
                'sweets' =>
                  blob.contains('sweet') ||
                      blob.contains('حل') ||
                      blob.contains('dessert') ||
                      blob.contains('cafe') ||
                      blob.contains('قهوة'),
                'drinks' =>
                  blob.contains('drink') ||
                      blob.contains('cafe') ||
                      blob.contains('coffee') ||
                      blob.contains('مشروب') ||
                      blob.contains('قهوة') ||
                      blob.contains('كافيه'),
                _ => true,
              };
            }).toList();
          }
          if (items.isEmpty) {
            return Center(
              child: Text(
                mp(lang, 'لا نتائج — جرّب بحثاً آخر', 'No results — try another search', '无结果'),
                style: TextStyle(color: ObicColors.mutedOf(context)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final m = items[i];
              return _MerchantCard(
                merchant: m,
                lang: lang,
                showMenu: true,
                onTap: () => openMerchantShop(
                  context: context,
                  auth: widget.authController,
                  langCode: lang,
                  merchant: m,
                  vertical: MarketplaceVertical.food,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PharmacyBrowsePage extends StatefulWidget {
  const PharmacyBrowsePage({
    super.key,
    required this.authController,
    required this.langCode,
  });
  final AuthController authController;
  final String langCode;

  @override
  State<PharmacyBrowsePage> createState() => _PharmacyBrowsePageState();
}

class _PharmacyBrowsePageState extends State<PharmacyBrowsePage> {
  late Future<List<MerchantListing>> _future =
      marketplaceRepo.listMerchants(MarketplaceVertical.pharmacy);
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final lang = widget.langCode;
    return MarketplaceScaffold(
      title: mp(lang, 'صيدليات', 'Pharmacies', '药店'),
      accent: const Color(0xFF0891B2),
      searchHint:
          mp(lang, 'دواء أو صيدلية…', 'Medicine or pharmacy…', '药品或药店…'),
      onSearch: (v) => setState(() => _q = v.trim().toLowerCase()),
      headerExtra: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          mp(
            lang,
            'وصفة · توصيل أدوية · خدمة ٢٤ ساعة',
            'Prescription · medicine delivery · 24h',
            '处方 · 送药 · 24小时',
          ),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
      body: FutureBuilder<List<MerchantListing>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              snap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          var items = snap.data ?? const <MerchantListing>[];
          if (_q.isNotEmpty) {
            items = items
                .where((m) =>
                    m.nameEn.toLowerCase().contains(_q) ||
                    m.nameAr.contains(_q) ||
                    m.tags.any((t) => t.toLowerCase().contains(_q)))
                .toList();
          }
          if (items.isEmpty) {
            return Center(
              child: Text(
                mp(lang, 'لا صيدليات مطابقة', 'No matching pharmacies', '无匹配药店'),
                style: TextStyle(color: ObicColors.mutedOf(context)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final m = items[i];
              return _MerchantCard(
                merchant: m,
                lang: lang,
                trailingIcon: Icons.local_pharmacy_rounded,
                onTap: () => openMerchantShop(
                  context: context,
                  auth: widget.authController,
                  langCode: lang,
                  merchant: m,
                  vertical: MarketplaceVertical.pharmacy,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MarketBrowsePage extends StatefulWidget {
  const MarketBrowsePage({
    super.key,
    required this.authController,
    required this.langCode,
    this.titleOverride,
  });
  final AuthController authController;
  final String langCode;
  final String? titleOverride;

  @override
  State<MarketBrowsePage> createState() => _MarketBrowsePageState();
}

class _MarketBrowsePageState extends State<MarketBrowsePage> {
  late Future<List<MerchantListing>> _future =
      marketplaceRepo.listMerchants(MarketplaceVertical.market);
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final lang = widget.langCode;
    return MarketplaceScaffold(
      title: widget.titleOverride ??
          mp(lang, 'سوبرماركت وخضار', 'Market & produce', '超市果蔬'),
      accent: const Color(0xFF059669),
      searchHint: mp(lang, 'سوق أو منتج…', 'Market or item…', '超市或商品…'),
      onSearch: (v) => setState(() => _q = v.trim().toLowerCase()),
      body: FutureBuilder<List<MerchantListing>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              snap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          var items = snap.data ?? const <MerchantListing>[];
          if (_q.isNotEmpty) {
            items = items
                .where((m) =>
                    m.nameEn.toLowerCase().contains(_q) ||
                    m.nameAr.contains(_q) ||
                    m.tags.any((t) => t.toLowerCase().contains(_q)))
                .toList();
          }
          if (items.isEmpty) {
            return Center(
              child: Text(
                mp(lang, 'لا نتائج', 'No results', '无结果'),
                style: TextStyle(color: ObicColors.mutedOf(context)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final m = items[i];
              return _MerchantCard(
                merchant: m,
                lang: lang,
                trailingIcon: Icons.shopping_basket_rounded,
                onTap: () => openMerchantShop(
                  context: context,
                  auth: widget.authController,
                  langCode: lang,
                  merchant: m,
                  vertical: MarketplaceVertical.market,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ErrandBrowsePage extends StatefulWidget {
  const ErrandBrowsePage({
    super.key,
    required this.authController,
    required this.langCode,
  });
  final AuthController authController;
  final String langCode;

  @override
  State<ErrandBrowsePage> createState() => _ErrandBrowsePageState();
}

class _ErrandBrowsePageState extends State<ErrandBrowsePage> {
  final _pickup = TextEditingController();
  final _dropoff = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _pickup.dispose();
    _dropoff.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.langCode;
    return MarketplaceScaffold(
      title: mp(lang, 'مشاوير', 'Errands', '跑腿'),
      accent: const Color(0xFF7C3AED),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _errandField(
            lang,
            controller: _pickup,
            label: mp(lang, 'نقطة الاستلام', 'Pickup', '取件点'),
            icon: Icons.my_location_rounded,
          ),
          const SizedBox(height: 12),
          _errandField(
            lang,
            controller: _dropoff,
            label: mp(lang, 'التسليم', 'Drop-off', '送至'),
            icon: Icons.flag_rounded,
          ),
          const SizedBox(height: 12),
          _errandField(
            lang,
            controller: _note,
            label: mp(lang, 'ماذا نحضر؟', 'What to fetch?', '需要代办什么？'),
            icon: Icons.edit_note_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Text(
            mp(lang, 'خيارات سريعة', 'Quick options', '快捷选项'),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ObicColors.titleOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in [
                mp(lang, 'شراء من سوبرماركت', 'Buy from supermarket', '超市代购'),
                mp(lang, 'استلام طرد', 'Pick up parcel', '取快递'),
                mp(lang, 'توصيل مفاتيح', 'Deliver keys', '送钥匙'),
              ])
                ActionChip(
                  label: Text(o),
                  onPressed: () => _note.text = o,
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              if (_pickup.text.trim().isEmpty ||
                  _dropoff.text.trim().isEmpty ||
                  _note.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      mp(
                        lang,
                        'أكمل الاستلام والتسليم ووصف المهمة',
                        'Fill pickup, drop-off, and what to fetch',
                        '请填写取件、送达与任务说明',
                      ),
                    ),
                  ),
                );
                return;
              }
              await showMarketplaceHoldDialog(
                context,
                auth: widget.authController,
                langCode: lang,
                title: mp(lang, 'طلب مشوار', 'Errand request', '跑腿请求'),
                vertical: MarketplaceVertical.errand,
                formData: {
                  'pickup': _pickup.text.trim(),
                  'dropoff': _dropoff.text.trim(),
                  'task': _note.text.trim(),
                },
                notes:
                    'Pickup: ${_pickup.text.trim()}\nDrop-off: ${_dropoff.text.trim()}\n${_note.text.trim()}',
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              mp(lang, 'اطلب مشواراً', 'Request errand', '提交跑腿'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errandField(
    String lang, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF7C3AED)),
        filled: true,
        fillColor: ObicColors.surfaceOf(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ObicColors.lineOf(context)),
        ),
      ),
    );
  }
}

class ClinicBrowsePage extends StatefulWidget {
  const ClinicBrowsePage({
    super.key,
    required this.authController,
    required this.langCode,
  });
  final AuthController authController;
  final String langCode;

  @override
  State<ClinicBrowsePage> createState() => _ClinicBrowsePageState();
}

class _ClinicBrowsePageState extends State<ClinicBrowsePage> {
  late Future<List<MerchantListing>> _future =
      marketplaceRepo.listMerchants(MarketplaceVertical.clinic);

  @override
  Widget build(BuildContext context) {
    final lang = widget.langCode;
    return MarketplaceScaffold(
      title: mp(lang, 'رعاية صحية', 'Healthcare', '医疗健康'),
      accent: const Color(0xFF2563EB),
      headerExtra: Text(
        mp(
          lang,
          'حجز موعد · عيادة · مستشفى',
          'Book clinic · hospital visit',
          '预约诊所 · 医院',
        ),
        style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
      ),
      body: FutureBuilder<List<MerchantListing>>(
        future: _future,
        builder: (context, snap) {
          final items = snap.data ?? const <MerchantListing>[];
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final m = items[i];
              return MarketplaceListCard(
                onTap: () => openMerchantShop(
                  context: context,
                  auth: widget.authController,
                  langCode: lang,
                  merchant: m,
                  vertical: MarketplaceVertical.clinic,
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0E7FF),
                    child: Icon(Icons.medical_services_rounded,
                        color: Color(0xFF2563EB)),
                  ),
                  title: Text(
                    m.name(lang),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '★ ${m.rating} · ${m.distanceKm} km · '
                    '${mp(lang, 'أقرب موعد ${m.etaMin} د', 'Next ~${m.etaMin} min', '约${m.etaMin}分钟')}',
                  ),
                  trailing: Text(
                    mp(lang, 'احجز', 'Book', '预约'),
                    style: const TextStyle(
                      color: ObicColors.blue,
                      fontWeight: FontWeight.w800,
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

class BeautyBrowsePage extends StatefulWidget {
  const BeautyBrowsePage({
    super.key,
    required this.authController,
    required this.langCode,
  });
  final AuthController authController;
  final String langCode;

  @override
  State<BeautyBrowsePage> createState() => _BeautyBrowsePageState();
}

class _BeautyBrowsePageState extends State<BeautyBrowsePage> {
  late Future<List<MerchantListing>> _future =
      marketplaceRepo.listMerchants(MarketplaceVertical.beauty);

  @override
  Widget build(BuildContext context) {
    final lang = widget.langCode;
    return MarketplaceScaffold(
      title: mp(lang, 'جمال وعناية', 'Beauty', '美妆护理'),
      accent: const Color(0xFFC026D3),
      body: FutureBuilder<List<MerchantListing>>(
        future: _future,
        builder: (context, snap) {
          final items = snap.data ?? const <MerchantListing>[];
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final m = items[i];
              return _MerchantCard(
                merchant: m,
                lang: lang,
                trailingIcon: Icons.spa_rounded,
                onTap: () => openMerchantShop(
                  context: context,
                  auth: widget.authController,
                  langCode: lang,
                  merchant: m,
                  vertical: MarketplaceVertical.beauty,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ShopBrowsePage extends StatefulWidget {
  const ShopBrowsePage({
    super.key,
    required this.authController,
    required this.langCode,
  });
  final AuthController authController;
  final String langCode;

  @override
  State<ShopBrowsePage> createState() => _ShopBrowsePageState();
}

class _ShopBrowsePageState extends State<ShopBrowsePage> {
  late Future<List<MerchantListing>> _future =
      marketplaceRepo.listMerchants(MarketplaceVertical.shop);

  @override
  Widget build(BuildContext context) {
    final lang = widget.langCode;
    return MarketplaceScaffold(
      title: mp(lang, 'تسوق محلي', 'Local shop', '本地购'),
      accent: const Color(0xFFDB2777),
      body: FutureBuilder<List<MerchantListing>>(
        future: _future,
        builder: (context, snap) {
          final items = snap.data ?? const <MerchantListing>[];
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final m = items[i];
              return _MerchantCard(
                merchant: m,
                lang: lang,
                trailingIcon: Icons.storefront_rounded,
                onTap: () => openMerchantShop(
                  context: context,
                  auth: widget.authController,
                  langCode: lang,
                  merchant: m,
                  vertical: MarketplaceVertical.shop,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({
    required this.merchant,
    required this.lang,
    required this.onTap,
    this.showMenu = false,
    this.trailingIcon,
  });

  final MerchantListing merchant;
  final String lang;
  final VoidCallback onTap;
  final bool showMenu;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final m = merchant;
    return MarketplaceListCard(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: ObicCachedImage(m.photo, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.name(lang),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: ObicColors.titleOf(context),
                          ),
                        ),
                      ),
                      if (trailingIcon != null)
                        Icon(trailingIcon, color: ObicColors.blue, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '★ ${m.rating} · ${m.distanceKm} km · ${m.etaMin} '
                    '${mp(lang, 'د', 'min', '分钟')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: ObicColors.mutedOf(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${mp(lang, 'رسوم', 'Fee', '配送费')} ¥${m.feeYuan}'
                    '${m.minOrderYuan != null ? ' · ${mp(lang, 'حد أدنى', 'min', '起送')} ¥${m.minOrderYuan}' : ''}',
                    style: const TextStyle(
                      color: ObicColors.blue,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final t in m.tags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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
                        ),
                    ],
                  ),
                  if (showMenu) ...[
                    const SizedBox(height: 6),
                    Text(
                      mp(lang, 'قائمة · تقييمات · صور', 'Menu · reviews · photos',
                          '菜单 · 评价 · 相册'),
                      style: TextStyle(
                        fontSize: 11,
                        color: ObicColors.mutedOf(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
