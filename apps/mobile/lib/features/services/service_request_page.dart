// Made by Dr Ali
// Structured service request form — routes to assigned employee via API.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/connectivity_service.dart';
import '../../core/obic_branches.dart';
import '../../core/obic_org.dart';
import '../../core/region_controller.dart';
import '../../theme/obic_colors.dart';
import '../../widgets/offline_banner.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import '../me/addresses_screen.dart';
import 'service_catalog.dart';
import 'service_form_templates.dart';
import 'service_sub_catalog.dart';
import 'services_api.dart';

class ServiceRequestPage extends StatefulWidget {
  const ServiceRequestPage({
    super.key,
    required this.service,
    required this.authController,
    required this.langCode,
    this.subService,
    this.offerId,
    this.prefillRequirements,
    this.foodDelivery = false,
    this.restaurantTitle,
    this.deliveryAddress,
  });

  final ObicService service;
  final AuthController authController;
  final String langCode;
  final ObicSubService? subService;
  final String? offerId;
  final String? prefillRequirements;

  /// Restaurant food order — hides branch picker; uses delivery address.
  final bool foodDelivery;
  final String? restaurantTitle;
  final ObicAddress? deliveryAddress;

  @override
  State<ServiceRequestPage> createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage> {
  final _api = ServicesApi();
  final _formKey = GlobalKey<FormState>();
  late final List<ServiceFormFieldDef> _fields;
  late final Map<String, TextEditingController> _controllers;
  bool _busy = false;
  String? _error;
  List<ObicBranch> _sortedBranches = kObicBranchRecords;
  String _branch = kObicBranches.first;
  double? _userLat;
  double? _userLng;
  ObicAddress? _deliveryAddress;

  @override
  void initState() {
    super.initState();
    _deliveryAddress = widget.deliveryAddress;
    _fields = widget.foodDelivery
        ? formFieldsForFoodDelivery(widget.langCode)
        : formFieldsForService(
            widget.service.slug,
            subServiceId: widget.subService?.id,
          );
    final user = widget.authController.user;
    _controllers = {for (final f in _fields) f.key: TextEditingController()};
    _controllers['fullName']?.text = user?.name ?? '';
    _controllers['phone']?.text = user?.phone ?? '';
    _controllers['email']?.text = user?.email ?? '';
    if (widget.prefillRequirements != null && !widget.foodDelivery) {
      _controllers['requirements']?.text = widget.prefillRequirements!;
    }
    if (!widget.foodDelivery) {
      _loadBranchOrder();
    }
  }

  Future<void> _loadBranchOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(kRegionLatKey);
    final lng = prefs.getDouble(kRegionLngKey);
    final country = prefs.getString(kRegionCountryKey);
    final sorted = branchesSortedByDistance(lat, lng, countryCode: country);
    if (!mounted) return;
    setState(() {
      _userLat = lat;
      _userLng = lng;
      _sortedBranches = sorted;
      _branch = sorted.first.name;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> _collectFormData() {
    final out = <String, String>{};
    for (final f in _fields) {
      final v = _controllers[f.key]?.text.trim() ?? '';
      if (v.isNotEmpty) out[f.key] = v;
    }
    if (widget.subService != null) {
      out['subServiceId'] = widget.subService!.id;
      out['subServiceLabel'] = widget.subService!.name(widget.langCode);
    }
    if (widget.foodDelivery && _deliveryAddress != null) {
      final a = _deliveryAddress!;
      out['deliveryLabel'] = a.label;
      out['deliveryLine1'] = a.line1;
      if (a.line2 != null && a.line2!.isNotEmpty)
        out['deliveryLine2'] = a.line2!;
      if (a.district != null && a.district!.isNotEmpty) {
        out['deliveryDistrict'] = a.district!;
      }
      out['deliveryCity'] = a.city;
      if (a.notes != null && a.notes!.isNotEmpty) {
        out['savedAddressNotes'] = a.notes!;
      }
      out['deliveryAddress'] = a.formatted();
    }
    if (widget.restaurantTitle != null && widget.restaurantTitle!.isNotEmpty) {
      out['restaurant'] = widget.restaurantTitle!;
    }
    return out;
  }

  Future<void> _changeDeliveryAddress() async {
    final picked = await pickSavedAddress(
      context,
      authController: widget.authController,
    );
    if (!mounted || picked == null) return;
    setState(() => _deliveryAddress = picked);
  }

  String _foodOrderNotes(Map<String, String> formData) {
    final lines = <String>[
      if (widget.restaurantTitle != null && widget.restaurantTitle!.isNotEmpty)
        'Restaurant: ${widget.restaurantTitle}',
      if (_deliveryAddress != null)
        'Delivery (${_deliveryAddress!.label}): ${_deliveryAddress!.formatted(multiline: true)}',
      ...formData.entries.map((e) => '${e.key}: ${e.value}'),
    ];
    return lines.join('\n');
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (ConnectivityService.instance.isOffline) {
      setState(() => _error = offlineNeedsNetworkMessage(l10n));
      return;
    }
    if (widget.foodDelivery && _deliveryAddress == null) {
      setState(() => _error = _foodDeliveryAddressRequired(widget.langCode));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null) {
        setState(() => _error = l10n.authRequiredTitle);
        return;
      }

      final formData = _collectFormData();
      final summary = widget.foodDelivery
          ? _foodOrderNotes(formData)
          : formData.entries.map((e) => '${e.key}: ${e.value}').join('\n');

      final serviceId = widget.service.id;
      final looksUuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(serviceId);

      if (!looksUuid) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.orderSubmitted)));
        Navigator.of(context).pop();
        return;
      }

      await _api.createOrder(
        accessToken: token,
        serviceId: serviceId,
        preferredBranch: widget.foodDelivery
            ? (_deliveryAddress?.city ?? '')
            : _branch,
        notes: summary,
        offerId: widget.offerId,
        subServiceId: widget.subService?.id,
        subServiceNameEn: widget.subService?.nameEn,
        subServiceNameAr: widget.subService?.nameAr,
        formData: formData,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.orderSubmitted)));
      Navigator.of(context).pop();
    } on AuthApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = l10n.authNetworkError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = widget.langCode;
    final sub = widget.subService;
    final title = widget.foodDelivery
        ? (widget.restaurantTitle ?? widget.service.name(langCode))
        : (sub?.name(langCode) ?? widget.service.name(langCode));
    final subtitle = widget.foodDelivery
        ? switch (langCode) {
            'ar' => 'أكمل طلب التوصيل — بدون اختيار فرع',
            'zh' => '完成外卖订单 — 无需选择分支机构',
            _ => 'Complete your delivery order — no branch selection',
          }
        : switch (langCode) {
            'ar' => 'املأ النموذج — يصل مباشرة للموظف المسؤول والمشرف',
            'zh' => '填写表单 — 直接发送给负责员工和管理员',
            _ => 'Fill the form — sent to the responsible employee & admin',
          };

    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(
          widget.foodDelivery ? _foodOrderTitle(langCode) : l10n.requestTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ObicColors.blueSoftOf(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ObicColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ObicColors.titleOf(context),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: ObicColors.mutedOf(context),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.foodDelivery) ...[
              const SizedBox(height: 16),
              Text(
                _deliveryAddressLabel(langCode),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ObicColors.titleOf(context),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ObicColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ObicColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_deliveryAddress != null) ...[
                      Text(
                        _deliveryAddress!.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ObicColors.titleOf(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _deliveryAddress!.formatted(multiline: true),
                        style: TextStyle(
                          color: ObicColors.inkOf(context),
                          height: 1.35,
                        ),
                      ),
                    ] else
                      Text(
                        _foodDeliveryAddressRequired(langCode),
                        style: TextStyle(color: ObicColors.mutedOf(context)),
                      ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _changeDeliveryAddress,
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      label: Text(_changeAddressLabel(langCode)),
                    ),
                  ],
                ),
              ),
            ],
            if (!widget.foodDelivery) ...[
              const SizedBox(height: 16),
              Text(
                l10n.prefBranch,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ObicColors.titleOf(context),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _branch,
                items: _sortedBranches
                    .map(
                      (b) => DropdownMenuItem(
                        value: b.name,
                        child: Text(
                          b.distanceLabel(
                            _userLat,
                            _userLng,
                            langCode: widget.langCode,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _branch = v);
                },
                decoration: _fieldDeco(),
              ),
              if (serviceOwnerHint(
                widget.service.slug,
                widget.langCode,
              ).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  serviceOwnerHint(widget.service.slug, widget.langCode),
                  style: TextStyle(
                    color: ObicColors.mutedOf(context),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 14),
            ],
            for (final field in _fields) ...[
              Text(
                field.label(langCode),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ObicColors.titleOf(context),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _controllers[field.key],
                keyboardType: keyboardFor(field.kind),
                textDirection: identifierTextDirection(field.kind),
                textAlign:
                    identifierTextDirection(field.kind) == TextDirection.ltr
                    ? TextAlign.left
                    : TextAlign.start,
                maxLines: field.kind == ServiceFormFieldKind.multiline ? 4 : 1,
                validator: (v) => validateFormField(field, v ?? '', langCode),
                decoration: _fieldDeco(hint: field.hint(langCode)),
              ),
              const SizedBox(height: 14),
            ],
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: ObicColors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.foodDelivery
                          ? _placeFoodOrderLabel(langCode)
                          : l10n.submitOrder,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _foodOrderTitle(String langCode) => switch (langCode) {
    'ar' => 'طلب توصيل',
    'zh' => '外卖下单',
    _ => 'Food delivery',
  };

  String _deliveryAddressLabel(String langCode) => switch (langCode) {
    'ar' => 'عنوان التوصيل',
    'zh' => '配送地址',
    _ => 'Delivery address',
  };

  String _changeAddressLabel(String langCode) => switch (langCode) {
    'ar' => 'تغيير العنوان',
    'zh' => '更换地址',
    _ => 'Change address',
  };

  String _placeFoodOrderLabel(String langCode) => switch (langCode) {
    'ar' => 'تأكيد الطلب',
    'zh' => '确认下单',
    _ => 'Place order',
  };

  String _foodDeliveryAddressRequired(String langCode) => switch (langCode) {
    'ar' => 'اختر عنوان توصيل',
    'zh' => '请选择配送地址',
    _ => 'Choose a delivery address',
  };

  InputDecoration _fieldDeco({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: ObicColors.surfaceRaisedOf(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ObicColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ObicColors.line),
      ),
    );
  }
}
