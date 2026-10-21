// Made by Dr Ali
// Admin desk — only useful when /v1/admin/me succeeds (server role).
// UI never grants privilege; every screen re-fetches via Admin API.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_logo.dart';
import '../auth/auth_controller.dart';
import 'admin_accounts_screen.dart';
import 'admin_api.dart';
import 'admin_bug_reports_screen.dart';
import 'admin_moderation_screen.dart';
import 'admin_offers_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_org_screen.dart';
import 'admin_prices_screen.dart';
import 'admin_registration_screen.dart';
import 'admin_vip_screen.dart';
import 'admin_oversight_screen.dart';
import 'admin_services_screen.dart';
import 'admin_staff_screen.dart';
import '../notifications/notifications_screen.dart';
import '../ops/ops_hub_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _api = AdminApi();
  Map<String, dynamic>? _me;
  Map<String, dynamic>? _dash;
  String? _error;
  bool _loading = true;

  bool get _isSuperAdmin => _me?['isSuperAdmin'] == true;
  bool get _canReassignOrders =>
      _isSuperAdmin || _me?['canReassignOrders'] == true;
  bool get _canManageOffers => _me?['canManageOffers'] == true;
  bool get _canOpenOps => _me?['canOpenOps'] == true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw Exception('session_expired');
      final me = await _api.me(token);
      final dash = await _api.dashboard(token);
      if (!mounted) return;
      setState(() {
        _me = me;
        _dash = dash;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final ar = Directionality.of(context) == TextDirection.rtl;
      final msg = e.toString();
      setState(() {
        _loading = false;
        _error = msg.contains('session_expired')
            ? (ar
                  ? 'انتهت الجلسة — سجّل الدخول مرة أخرى'
                  : 'Session expired — please sign in again')
            : msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(ar ? 'إدارة OBIC' : 'OBIC Admin'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Center(child: ObicLogo(size: 56, borderRadius: 14)),
                  const SizedBox(height: 16),
                  if (!_isSuperAdmin)
                    Card(
                      color: ObicColors.card,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          ar
                              ? 'حساب موظف — الطلبات والعروض فقط. لإدارة الموظفين استخدم Super Admin (admin@obic.local).'
                              : 'Employee account — orders & offers only. To manage staff, use Super Admin (admin@obic.local).',
                          style: TextStyle(
                            color: ObicColors.inkOf(context),
                            height: 1.4,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    (_me?['name'] as String?) ?? (ar ? 'موظف' : 'Staff'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ObicColors.titleOf(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (_) {
                      final desk = [
                        (_me?['staffTitle'] as String?)?.trim(),
                        (_me?['branchLabel'] as String?)?.trim(),
                      ].whereType<String>().where((e) => e.isNotEmpty);
                      final deskLine = desk.join(' · ');
                      final role = (_me?['role'] as String?) ?? '—';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (deskLine.isNotEmpty)
                            Text(
                              deskLine,
                              style: TextStyle(
                                color: ObicColors.inkOf(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Text(
                            ar
                                ? (deskLine.isEmpty
                                      ? 'الدور: $role (من الخادم)'
                                      : 'الدور: $role · الصلاحية حسب الدور فقط')
                                : (deskLine.isEmpty
                                      ? 'Role: $role (from server)'
                                      : 'Role: $role · privilege is role only'),
                            style: TextStyle(
                              color: ObicColors.mutedOf(context),
                              fontSize: deskLine.isEmpty ? 14 : 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _StatCard(
                    title: ar ? 'الطلبات في النطاق' : 'Orders in scope',
                    value: '${(_dash?['orders'] as Map?)?['total'] ?? 0}',
                  ),
                  _StatCard(
                    title: ar ? 'مُقدَّم' : 'Submitted',
                    value: '${(_dash?['orders'] as Map?)?['submitted'] ?? 0}',
                  ),
                  _StatCard(
                    title: ar ? 'قيد التنفيذ' : 'In progress',
                    value: '${(_dash?['orders'] as Map?)?['inProgress'] ?? 0}',
                  ),
                  if (_isSuperAdmin)
                    _StatCard(
                      title: ar ? 'غير معيّن' : 'Unassigned',
                      value:
                          '${(_dash?['orders'] as Map?)?['unassigned'] ?? 0}',
                    ),
                  const SizedBox(height: 12),
                  Card(
                    color: ObicColors.blueSoft,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        ar
                            ? 'كل خدمة لها نموذج — يصل الطلب للموظف المسؤول حسب الفرع والخدمة، والمشرف يرى كل النماذج.'
                            : 'Each service has a form — requests route to the branch desk; Super Admin sees all forms.',
                        style: TextStyle(
                          color: ObicColors.titleOf(context),
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  _NavTile(
                    icon: Icons.receipt_long,
                    title: ar ? 'قائمة الطلبات' : 'Orders queue',
                    subtitle: ar
                        ? 'نماذج العملاء · تعيين · متابعة'
                        : 'Customer forms · assign · track',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminOrdersScreen(
                          authController: widget.authController,
                          isSuperAdmin: _isSuperAdmin,
                          canReassignOrders: _canReassignOrders,
                        ),
                      ),
                    ),
                  ),
                  if (_canOpenOps || _isSuperAdmin) ...[
                    _NavTile(
                      icon: Icons.domain_outlined,
                      title: ar
                          ? 'طلبات تسجيل الشركات'
                          : 'Company registrations',
                      subtitle: ar
                          ? 'مستندات أخضر/أصفر/أحمر · قراءة الجواز · تصحيح'
                          : 'Green/Yellow/Red docs · passport reading · corrections',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminRegistrationScreen(
                            authController: widget.authController,
                          ),
                        ),
                      ),
                    ),
                    _NavTile(
                      icon: Icons.workspace_premium_outlined,
                      title: ar ? 'خدمات VIP' : 'VIP services',
                      subtitle: ar
                          ? 'استشارات مؤقتة · رحلات · المجموعة الرسمية'
                          : 'Timed consultations · trips · official group',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminVipScreen(
                            authController: widget.authController,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_canManageOffers)
                    _NavTile(
                      icon: Icons.hotel_class_outlined,
                      title: ar
                          ? 'عروض الفنادق والطيران والمطاعم'
                          : 'Hotels, flights & restaurants',
                      subtitle: ar
                          ? 'إدخال الصور والأسعار · فندق · طيران · مطاعم'
                          : 'Photos, video & prices · hotels · flights · food',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminOffersScreen(
                            authController: widget.authController,
                          ),
                        ),
                      ),
                    ),
                  _NavTile(
                    icon: Icons.bug_report_outlined,
                    title: ar ? 'بلاغات الأعطال' : 'Bug reports',
                    subtitle: ar
                        ? 'تقارير العملاء من التطبيق'
                        : 'In-app customer reports',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminBugReportsScreen(
                          authController: widget.authController,
                        ),
                      ),
                    ),
                  ),
                  if (_canOpenOps || _isSuperAdmin)
                    _NavTile(
                      icon: Icons.person_off_outlined,
                      title: ar
                          ? 'حسابات موقوفة · استعادة'
                          : 'Deactivated · restore',
                      subtitle: ar
                          ? 'إعادة تفعيل بعد الحذف الذاتي'
                          : 'Reactivate soft-deleted accounts',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminAccountsScreen(
                            authController: widget.authController,
                          ),
                        ),
                      ),
                    ),
                  _NavTile(
                    icon: Icons.notifications_outlined,
                    title: ar ? 'صندوق الإشعارات' : 'Notifications inbox',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(
                          authController: widget.authController,
                        ),
                      ),
                    ),
                  ),
                  if (_canOpenOps)
                    _NavTile(
                      icon: Icons.dashboard_customize_outlined,
                      title: ar ? 'العمليات الداخلية' : 'Internal Ops',
                      subtitle: ar
                          ? 'وحدات تشغيلية (نموذج)'
                          : 'Operational modules (prototype)',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OpsHubScreen()),
                      ),
                    ),
                  _NavTile(
                    icon: Icons.apartment_outlined,
                    title: ar
                        ? 'الهيكل التنظيمي (Form2)'
                        : 'Org structure (Form2)',
                    subtitle: ar
                        ? 'فروع · مسؤولو خدمات · قائمة الموظفين'
                        : 'Branches · service owners · roster',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminOrgScreen()),
                    ),
                  ),
                  if (_isSuperAdmin) ...[
                    _NavTile(
                      icon: Icons.price_change_outlined,
                      title: ar
                          ? 'الأسعار وقواعد الأهلية'
                          : 'Prices & eligibility rules',
                      subtitle: ar
                          ? 'إصدارات معتمدة · تفعيل بمصادقة'
                          : 'Versioned approvals · TOTP activation',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminPricesScreen(
                            authController: widget.authController,
                          ),
                        ),
                      ),
                    ),
                    _NavTile(
                      icon: Icons.category_outlined,
                      title: ar ? 'كتالوج الخدمات' : 'Service catalog',
                      subtitle: ar
                          ? 'إضافة وتعديل الخدمات · عربي/إنجليزي/صيني'
                          : 'Add & edit services · AR/EN/ZH',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminServicesScreen(
                            authController: widget.authController,
                          ),
                        ),
                      ),
                    ),
                    _NavTile(
                      icon: Icons.people_outline,
                      title: ar ? 'مكتب الموظفين' : 'Staff desk',
                      subtitle: ar
                          ? 'الصور · الفروع · الأدوار'
                          : 'Photos · branches · roles',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminStaffScreen(
                            authController: widget.authController,
                          ),
                        ),
                      ),
                    ),
                    _NavTile(
                      icon: Icons.visibility_outlined,
                      title: ar ? 'رقابة الدردشة' : 'Chat oversight',
                      subtitle: ar
                          ? 'موظف ↔ عميل فقط'
                          : 'Staff ↔ customer only',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminOversightScreen(
                            authController: widget.authController,
                          ),
                        ),
                      ),
                    ),
                    _NavTile(
                      icon: Icons.shield_outlined,
                      title: ar ? 'إشراف المحتوى' : 'Content moderation',
                      subtitle: ar
                          ? 'بلاغات وكلمات محظورة'
                          : 'Reports & banned phrases',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminModerationScreen(
                            authController: widget.authController,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    ar
                        ? 'تصميم وتطوير: د. علي — الصلاحية مفروضة من الخادم.'
                        : 'Made by Dr Ali — privilege is server-enforced.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: ObicColors.mutedOf(context),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: ObicColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ObicColors.line),
      ),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: ObicColors.blue,
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: ObicColors.card,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ObicColors.line),
      ),
      child: ListTile(
        leading: Icon(icon, color: ObicColors.blue),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
