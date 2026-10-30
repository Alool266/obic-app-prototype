// Made by Dr Ali
// Meituan/Ctrip-style marketplace order card — not staff chat / secretary summary.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_back_button.dart';
import '../auth/auth_controller.dart';
import '../messages/chat_screen.dart';
import '../services/services_api.dart';
import 'marketplace_models.dart';
import 'marketplace_request.dart';
import 'pages/marketplace_chrome.dart';

bool isMarketplaceOrderRow(Map<String, dynamic> row) {
  if (row['marketplace'] == true) return true;
  final fd = row['formData'];
  if (fd is Map && (fd['source']?.toString().toLowerCase() == 'marketplace')) {
    return true;
  }
  return false;
}

Map<String, dynamic>? marketplaceFormData(Map<String, dynamic> row) {
  final fd = row['formData'];
  if (fd is Map) return Map<String, dynamic>.from(fd);
  return null;
}

MarketplaceVertical? marketplaceVerticalFromOrder(Map<String, dynamic> row) {
  final fd = marketplaceFormData(row);
  final raw = (fd?['vertical'] ?? '').toString().trim();
  if (raw.isEmpty) return null;
  for (final v in MarketplaceVertical.values) {
    if (v.name == raw) return v;
  }
  return null;
}

/// Full-screen order receipt: merchant, items, status timeline, track / reorder.
class MarketplaceOrderPage extends StatefulWidget {
  const MarketplaceOrderPage({
    super.key,
    required this.authController,
    required this.order,
    this.langCode = 'en',
  });

  final AuthController authController;
  final Map<String, dynamic> order;
  final String langCode;

  @override
  State<MarketplaceOrderPage> createState() => _MarketplaceOrderPageState();
}

class _MarketplaceOrderPageState extends State<MarketplaceOrderPage> {
  late Map<String, dynamic> _order;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
  }

  String get _lang =>
      widget.langCode.isNotEmpty
          ? widget.langCode
          : Localizations.localeOf(context).languageCode;

  String _t(String ar, String en, [String? zh]) => mp(_lang, ar, en, zh);

  String get _status => (_order['status']?.toString() ?? 'Submitted');

  String get _title {
    final fd = marketplaceFormData(_order);
    final fromFd = (fd?['title'] ?? fd?['merchant'] ?? '').toString().trim();
    if (fromFd.isNotEmpty) return fromFd;
    final en = _order['subServiceNameEn']?.toString().trim();
    final ar = _order['subServiceNameAr']?.toString().trim();
    if (_lang.startsWith('ar') && ar != null && ar.isNotEmpty) return ar;
    if (en != null && en.isNotEmpty) return en;
    return _t('طلب سوق', 'Marketplace order', '商城订单');
  }

  String get _merchant {
    final fd = marketplaceFormData(_order);
    final m = (fd?['merchant'] ?? fd?['merchantName'] ?? '').toString().trim();
    if (m.isNotEmpty) return m;
    return _title;
  }

  String get _requestNumber {
    final n = _order['requestNumber']?.toString().trim();
    if (n != null && n.isNotEmpty) return n;
    final id = _order['id']?.toString() ?? '';
    return id.length >= 8 ? id.substring(0, 8).toUpperCase() : id;
  }

  List<_DetailLine> get _detailLines {
    final fd = marketplaceFormData(_order) ?? const {};
    const skip = {
      'source',
      'vertical',
      'title',
      'merchant',
      'merchantId',
      'merchantName',
      'city',
    };
    final out = <_DetailLine>[];
    for (final e in fd.entries) {
      final k = e.key.toString();
      if (skip.contains(k)) continue;
      final v = e.value?.toString().trim() ?? '';
      if (v.isEmpty) continue;
      out.add(_DetailLine(label: k, value: v));
    }
    final city = (fd['city'] ?? _order['preferredBranch'] ?? '')
        .toString()
        .trim();
    if (city.isNotEmpty) {
      out.insert(
        0,
        _DetailLine(
          label: _t('المدينة', 'City', '城市'),
          value: city,
        ),
      );
    }
    final notes = _order['notes']?.toString().trim() ?? '';
    if (notes.isNotEmpty && notes != _title) {
      // Prefer structured form lines; keep a short notes peek if unique.
      if (out.isEmpty) {
        out.add(_DetailLine(label: _t('ملاحظات', 'Notes', '备注'), value: notes));
      }
    }
    return out;
  }

  Future<void> _refresh() async {
    final token = await widget.authController.accessToken();
    final id = _order['id']?.toString();
    if (token == null || id == null) return;
    setState(() => _busy = true);
    try {
      final fresh = await ServicesApi().getMyOrder(
        accessToken: token,
        orderId: id,
      );
      if (!mounted) return;
      setState(() {
        _order = {..._order, ...fresh};
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('تعذر تحديث الحالة', 'Could not refresh status', '无法刷新状态'),
          ),
        ),
      );
    }
  }

  Future<void> _reorder() async {
    final vertical = marketplaceVerticalFromOrder(_order);
    if (vertical == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'أعد الطلب من يومي أو سفر',
              'Reorder from Daily or Travel',
              '请从「日常/出行」重新下单',
            ),
          ),
        ),
      );
      return;
    }
    final fd = marketplaceFormData(_order) ?? {};
    final reuse = <String, String>{};
    for (final e in fd.entries) {
      final k = e.key.toString();
      if (k == 'source' || k == 'title') continue;
      final v = e.value?.toString().trim() ?? '';
      if (v.isEmpty) continue;
      reuse[k] = v;
    }
    await submitMarketplaceRequest(
      context,
      auth: widget.authController,
      langCode: _lang,
      vertical: vertical,
      title: _title,
      formData: reuse,
      city: (fd['city'] ?? _order['preferredBranch'])?.toString(),
      notes: null,
    );
  }

  Future<void> _openStaffChat() async {
    final token = await widget.authController.accessToken();
    final orderId = _order['id']?.toString();
    if (token == null || orderId == null) return;
    setState(() => _busy = true);
    try {
      var threadId = _order['conversationId']?.toString();
      var title = _requestNumber;
      if (threadId == null || threadId.isEmpty) {
        final chat = await ServicesApi().openOrderChat(
          accessToken: token,
          orderId: orderId,
        );
        threadId = chat['conversationId']?.toString();
        title = chat['title']?.toString() ?? title;
      }
      if (!mounted || threadId == null) return;
      setState(() => _busy = false);
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            authController: widget.authController,
            threadId: threadId!,
            title: title,
            initialKind: 'order',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = ObicColors.inkOf(context);
    final muted = ObicColors.mutedOf(context);
    final surface = ObicColors.surfaceOf(context);
    final steps = _timelineSteps(_status);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      appBar: AppBar(
        backgroundColor: ObicColors.navy,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        leading: const ObicBackButtonLeading(),
        title: Text(_t('تفاصيل الطلب', 'Order details', '订单详情')),
        actions: [
          IconButton(
            tooltip: _t('تحديث', 'Refresh', '刷新'),
            onPressed: _busy ? null : _refresh,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _StatusHero(
            status: _status,
            label: _statusLabel(_status),
            requestNumber: _requestNumber,
          ),
          const SizedBox(height: 12),
          _CardBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('التاجر', 'Merchant', '商家'),
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ObicColors.blueSoftOf(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: ObicColors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _merchant,
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _CardBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('العناصر / التفاصيل', 'Items / details', '商品 / 详情'),
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _title,
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (_detailLines.isEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _t(
                      'سيتم ربط عناصر السلة عند تفعيل واجهة التاجر.',
                      'Cart line-items will appear when the merchant API is live.',
                      '商家接口上线后将显示商品明细。',
                    ),
                    style: TextStyle(color: muted, height: 1.35, fontSize: 13),
                  ),
                ] else
                  ..._detailLines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 96,
                            child: Text(
                              line.label,
                              style: TextStyle(
                                color: muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              line.value,
                              style: TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _CardBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('تتبع الحالة', 'Status timeline', '状态进度'),
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < steps.length; i++) ...[
                  _TimelineRow(
                    step: steps[i],
                    isLast: i == steps.length - 1,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy ? null : _refresh,
            style: FilledButton.styleFrom(
              backgroundColor: ObicColors.navy,
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.local_shipping_outlined),
            label: Text(_t('تتبع الطلب', 'Track order', '追踪订单')),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _reorder,
            style: OutlinedButton.styleFrom(
              foregroundColor: ObicColors.navy,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: ObicColors.navy),
            ),
            icon: const Icon(Icons.replay_rounded),
            label: Text(_t('إعادة الطلب', 'Reorder', '再来一单')),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _busy ? null : _openStaffChat,
            child: Text(
              _t(
                'مساعدة الفريق (اختياري)',
                'Contact support (optional)',
                '联系客服（可选）',
              ),
              style: TextStyle(color: muted),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              'هذا إيصال طلب سوق — ليس محادثة سكرتيرة. الخدمات الرسمية واللوجستيات تبقى عبر طلب الخدمة.',
              'This is a marketplace receipt — not a secretary chat. Visa/logistics stay on the service request flow.',
              '这是商城订单凭证，不是秘书对话。签证/物流仍走正式服务请求。',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 11, height: 1.35),
          ),
          // Keep surface color referenced for theme consistency.
          Offstage(child: ColoredBox(color: surface)),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Assigned':
        return _t('تم الاستلام', 'Received', '已接单');
      case 'InProgress':
        return _t('قيد التحضير', 'In progress', '处理中');
      case 'WaitingCustomer':
        return _t('بانتظارك', 'Waiting on you', '待您确认');
      case 'Completed':
        return _t('مكتمل', 'Completed', '已完成');
      case 'Cancelled':
        return _t('ملغى', 'Cancelled', '已取消');
      default:
        return _t('تم الإرسال', 'Submitted', '已提交');
    }
  }

  List<_TimelineStep> _timelineSteps(String status) {
    const pipe = [
      'Submitted',
      'Assigned',
      'InProgress',
      'WaitingCustomer',
      'Completed',
    ];
    if (status == 'Cancelled') {
      return [
        _TimelineStep(
          label: _t('تم الإرسال', 'Submitted', '已提交'),
          done: true,
          active: false,
        ),
        _TimelineStep(
          label: _t('ملغى', 'Cancelled', '已取消'),
          done: true,
          active: true,
        ),
      ];
    }
    final idx = pipe.indexOf(status);
    final activeIdx = idx < 0 ? 0 : idx;
    final labels = [
      _t('تم الإرسال', 'Submitted', '已提交'),
      _t('تم الاستلام', 'Received', '已接单'),
      _t('قيد التحضير', 'In progress', '处理中'),
      _t('بانتظارك', 'Waiting on you', '待您确认'),
      _t('مكتمل', 'Completed', '已完成'),
    ];
    return List.generate(pipe.length, (i) {
      return _TimelineStep(
        label: labels[i],
        done: i <= activeIdx,
        active: i == activeIdx,
      );
    });
  }
}

class _DetailLine {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;
}

class _TimelineStep {
  const _TimelineStep({
    required this.label,
    required this.done,
    required this.active,
  });
  final String label;
  final bool done;
  final bool active;
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({
    required this.status,
    required this.label,
    required this.requestNumber,
  });

  final String status;
  final String label;
  final String requestNumber;

  @override
  Widget build(BuildContext context) {
    final done = status == 'Completed';
    final cancelled = status == 'Cancelled';
    final color = cancelled
        ? const Color(0xFFB91C1C)
        : done
            ? const Color(0xFF15803D)
            : ObicColors.navy;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '#$requestNumber',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  const _CardBlock({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAEF)),
      ),
      child: child,
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});
  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final activeColor = step.active ? ObicColors.blue : const Color(0xFF94A3B8);
    final doneColor = step.done ? ObicColors.navy : const Color(0xFFCBD5E1);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: step.done ? doneColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: step.active ? activeColor : doneColor,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: step.done
                    ? ObicColors.navy.withValues(alpha: 0.35)
                    : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Text(
            step.label,
            style: TextStyle(
              fontWeight: step.active ? FontWeight.w800 : FontWeight.w600,
              color: step.done
                  ? ObicColors.inkOf(context)
                  : ObicColors.mutedOf(context),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
