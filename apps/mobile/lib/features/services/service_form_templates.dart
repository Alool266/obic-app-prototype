// Made by Dr Ali
// Per-service customer request form fields (bilingual labels).

import 'package:flutter/material.dart';

enum ServiceFormFieldKind { text, phone, email, date, multiline, number }

class ServiceFormFieldDef {
  const ServiceFormFieldDef({
    required this.key,
    required this.labelEn,
    required this.labelAr,
    this.required = true,
    this.kind = ServiceFormFieldKind.text,
    this.hintEn,
    this.hintAr,
    this.labelZh = '',
    this.hintZh,
  });

  final String key;
  final String labelEn;
  final String labelAr;
  final String labelZh;
  final bool required;
  final ServiceFormFieldKind kind;
  final String? hintEn;
  final String? hintAr;
  final String? hintZh;

  String label(String langCode) {
    switch (langCode) {
      case 'ar':
        return labelAr;
      case 'zh':
        return labelZh.isNotEmpty ? labelZh : labelEn;
      default:
        return labelEn;
    }
  }

  String? hint(String langCode) {
    switch (langCode) {
      case 'ar':
        return hintAr;
      case 'zh':
        return hintZh ?? hintEn;
      default:
        return hintEn;
    }
  }
}

TextInputType keyboardFor(ServiceFormFieldKind kind) {
  switch (kind) {
    case ServiceFormFieldKind.phone:
      return TextInputType.phone;
    case ServiceFormFieldKind.email:
      return TextInputType.emailAddress;
    case ServiceFormFieldKind.number:
      return TextInputType.number;
    case ServiceFormFieldKind.multiline:
      return TextInputType.multiline;
    case ServiceFormFieldKind.date:
    case ServiceFormFieldKind.text:
      return TextInputType.text;
  }
}

/// Phone, email, and numeric identifiers stay left-to-right in Arabic UI.
/// Free-text fields return null and follow the locale direction.
TextDirection? identifierTextDirection(ServiceFormFieldKind kind) {
  switch (kind) {
    case ServiceFormFieldKind.phone:
    case ServiceFormFieldKind.email:
    case ServiceFormFieldKind.number:
    case ServiceFormFieldKind.date:
      return TextDirection.ltr;
    case ServiceFormFieldKind.text:
    case ServiceFormFieldKind.multiline:
      return null;
  }
}

const _baseFields = <ServiceFormFieldDef>[
  ServiceFormFieldDef(
    key: 'fullName',
    labelEn: 'Full name',
    labelAr: 'الاسم الكامل',
  ),
  ServiceFormFieldDef(
    key: 'phone',
    labelEn: 'Phone / WhatsApp',
    labelAr: 'الهاتف / واتساب',
    kind: ServiceFormFieldKind.phone,
  ),
  ServiceFormFieldDef(
    key: 'email',
    labelEn: 'Email',
    labelAr: 'البريد الإلكتروني',
    kind: ServiceFormFieldKind.email,
    required: false,
  ),
  ServiceFormFieldDef(
    key: 'preferredDate',
    labelEn: 'Preferred date',
    labelAr: 'التاريخ المفضل',
    hintEn: 'e.g. 2026-09-15',
    hintAr: 'مثال: 2026-09-15',
    kind: ServiceFormFieldKind.date,
    required: false,
  ),
  ServiceFormFieldDef(
    key: 'city',
    labelEn: 'City in China',
    labelAr: 'المدينة في الصين',
    hintEn: 'Yiwu, Guangzhou…',
    hintAr: 'ييو، قوانغتشو…',
    required: false,
  ),
];

const _extraBySlug = <String, List<ServiceFormFieldDef>>{
  'hotels': [
    ServiceFormFieldDef(
      key: 'checkIn',
      labelEn: 'Check-in date',
      labelAr: 'تاريخ الوصول',
      kind: ServiceFormFieldKind.date,
    ),
    ServiceFormFieldDef(
      key: 'nights',
      labelEn: 'Number of nights',
      labelAr: 'عدد الليالي',
      kind: ServiceFormFieldKind.number,
    ),
    ServiceFormFieldDef(
      key: 'guests',
      labelEn: 'Guests',
      labelAr: 'عدد الضيوف',
      kind: ServiceFormFieldKind.number,
      required: false,
    ),
  ],
  'flights': [
    ServiceFormFieldDef(
      key: 'fromCity',
      labelEn: 'From city',
      labelAr: 'من مدينة',
    ),
    ServiceFormFieldDef(
      key: 'toCity',
      labelEn: 'To city',
      labelAr: 'إلى مدينة',
    ),
    ServiceFormFieldDef(
      key: 'travelDate',
      labelEn: 'Travel date',
      labelAr: 'تاريخ السفر',
      kind: ServiceFormFieldKind.date,
    ),
    ServiceFormFieldDef(
      key: 'passengers',
      labelEn: 'Passengers',
      labelAr: 'عدد المسافرين',
      kind: ServiceFormFieldKind.number,
      required: false,
    ),
  ],
  'visa': [
    ServiceFormFieldDef(
      key: 'destinationCountry',
      labelEn: 'Destination country / visa',
      labelAr: 'دولة التأشيرة المطلوبة',
      hintEn: 'e.g. Hong Kong, Thailand, Japan, Korea, USA…',
      hintAr: 'مثال: هونغ كونغ، تايلاند، اليابان، كوريا، أمريكا…',
    ),
    ServiceFormFieldDef(
      key: 'visaChannel',
      labelEn: 'Online or offline',
      labelAr: 'أونلاين أو أوفلاين',
      hintEn: 'Online / Offline (+ MBC if offline)',
      hintAr: 'أونلاين / أوفلاين (+ MBC إن أوفلاين)',
      required: false,
    ),
    ServiceFormFieldDef(
      key: 'nationality',
      labelEn: 'Nationality',
      labelAr: 'الجنسية',
    ),
    ServiceFormFieldDef(
      key: 'passportNo',
      labelEn: 'Passport number',
      labelAr: 'رقم الجواز',
    ),
    ServiceFormFieldDef(
      key: 'visaType',
      labelEn: 'Visa type needed',
      labelAr: 'نوع التأشيرة',
      hintEn: 'Business / tourist / invitation',
      hintAr: 'عمل / سياحة / دعوة',
    ),
  ],
  'bank': [
    ServiceFormFieldDef(
      key: 'companyName',
      labelEn: 'Company / personal name',
      labelAr: 'اسم الشركة / الشخص',
    ),
    ServiceFormFieldDef(
      key: 'purpose',
      labelEn: 'Account purpose',
      labelAr: 'الغرض من الحساب',
      kind: ServiceFormFieldKind.multiline,
    ),
  ],
  'scholarship': [
    ServiceFormFieldDef(
      key: 'studyLevel',
      labelEn: 'Study level',
      labelAr: 'المستوى الدراسي',
      hintEn: 'Bachelor / Master / Language',
      hintAr: 'بكالوريوس / ماجستير / لغة',
    ),
    ServiceFormFieldDef(
      key: 'targetUniversity',
      labelEn: 'Target university or program',
      labelAr: 'الجامعة أو البرنامج',
      required: false,
    ),
  ],
  'legal': [
    ServiceFormFieldDef(
      key: 'caseType',
      labelEn: 'Case type',
      labelAr: 'نوع القضية',
      hintEn: 'Contract, dispute, compliance…',
      hintAr: 'عقد، نزاع، امتثال…',
    ),
  ],
  'company': [
    ServiceFormFieldDef(
      key: 'businessType',
      labelEn: 'Business activity',
      labelAr: 'نشاط الشركة',
    ),
    ServiceFormFieldDef(
      key: 'shareholders',
      labelEn: 'Shareholders count',
      labelAr: 'عدد الشركاء',
      kind: ServiceFormFieldKind.number,
      required: false,
    ),
  ],
  'cars': [
    ServiceFormFieldDef(
      key: 'pickupLocation',
      labelEn: 'Pickup location',
      labelAr: 'موقع الاستلام',
      labelZh: '上车地点',
    ),
    ServiceFormFieldDef(
      key: 'vehicleType',
      labelEn: 'Vehicle type',
      labelAr: 'نوع المركبة',
      labelZh: '车型',
      required: false,
    ),
  ],
  'property': [
    ServiceFormFieldDef(
      key: 'propertyType',
      labelEn: 'Property type',
      labelAr: 'نوع العقار',
      labelZh: '房产类型',
      hintEn: 'Office / apartment / warehouse',
      hintAr: 'مكتب / شقة / مستودع',
      hintZh: '办公室/公寓/仓库',
    ),
    ServiceFormFieldDef(
      key: 'budget',
      labelEn: 'Budget range',
      labelAr: 'الميزانية',
      labelZh: '预算范围',
      required: false,
    ),
  ],
  'delivery': [
    ServiceFormFieldDef(
      key: 'fromAddress',
      labelEn: 'From address',
      labelAr: 'عنوان الإرسال',
      labelZh: '发货地址',
    ),
    ServiceFormFieldDef(
      key: 'toAddress',
      labelEn: 'To address',
      labelAr: 'عنوان الاستلام',
      labelZh: '收货地址',
    ),
    ServiceFormFieldDef(
      key: 'weightKg',
      labelEn: 'Weight (kg)',
      labelAr: 'الوزن (كغ)',
      labelZh: '重量（公斤）',
      kind: ServiceFormFieldKind.number,
      required: false,
    ),
  ],
  'consultations': [
    ServiceFormFieldDef(
      key: 'topic',
      labelEn: 'Consultation topic',
      labelAr: 'موضوع الاستشارة',
      labelZh: '咨询主题',
    ),
  ],
  'translation': [
    ServiceFormFieldDef(
      key: 'sourceLang',
      labelEn: 'Source language',
      labelAr: 'اللغة المصدر',
      labelZh: '源语言',
    ),
    ServiceFormFieldDef(
      key: 'targetLang',
      labelEn: 'Target language',
      labelAr: 'اللغة الهدف',
      labelZh: '目标语言',
    ),
  ],
  'tourism': [
    ServiceFormFieldDef(
      key: 'destinations',
      labelEn: 'Destinations',
      labelAr: 'الوجهات',
      labelZh: '目的地',
      hintEn: 'Beijing, Shanghai, Yiwu…',
      hintAr: 'بكين، شنغهاي، ييو…',
      hintZh: '北京、上海、义乌…',
    ),
    ServiceFormFieldDef(
      key: 'travelers',
      labelEn: 'Travelers',
      labelAr: 'عدد المسافرين',
      labelZh: '出行人数',
      kind: ServiceFormFieldKind.number,
      required: false,
    ),
  ],
};

List<ServiceFormFieldDef> formFieldsForService(
  String serviceSlug, {
  String? subServiceId,
}) {
  final sub = (subServiceId ?? '').toLowerCase();
  final useVisa = sub == 'visa' || sub == 'visas' || serviceSlug == 'visa';
  final extras = useVisa
      ? (_extraBySlug['visa'] ?? const <ServiceFormFieldDef>[])
      : (_extraBySlug[serviceSlug] ?? const <ServiceFormFieldDef>[]);
  return [
    ..._baseFields,
    ...extras,
    const ServiceFormFieldDef(
      key: 'requirements',
      labelEn: 'Additional requirements',
      labelAr: 'متطلبات إضافية',
      kind: ServiceFormFieldKind.multiline,
      required: false,
      hintEn: 'Tell us what you need…',
      hintAr: 'صف احتياجك بالتفصيل…',
    ),
  ];
}

String? validateFormField(
  ServiceFormFieldDef field,
  String value,
  String langCode,
) {
  final trimmed = value.trim();
  if (field.required && trimmed.isEmpty) {
    switch (langCode) {
      case 'ar':
        return 'هذا الحقل مطلوب';
      case 'zh':
        return '此字段为必填项';
      default:
        return 'This field is required';
    }
  }
  if (trimmed.isEmpty) return null;
  if (field.kind == ServiceFormFieldKind.email && !trimmed.contains('@')) {
    switch (langCode) {
      case 'ar':
        return 'بريد غير صالح';
      case 'zh':
        return '邮箱格式无效';
      default:
        return 'Invalid email';
    }
  }
  return null;
}

/// Food delivery — no OBIC branch picker; address comes from saved profile.
List<ServiceFormFieldDef> formFieldsForFoodDelivery(String langCode) {
  return [
    ServiceFormFieldDef(
      key: 'phone',
      labelEn: 'Phone / WhatsApp',
      labelAr: 'الهاتف / واتساب',
      labelZh: '手机 / WhatsApp',
      kind: ServiceFormFieldKind.phone,
    ),
    ServiceFormFieldDef(
      key: 'orderItems',
      labelEn: 'Your order',
      labelAr: 'طلبك',
      labelZh: '您的订单',
      kind: ServiceFormFieldKind.multiline,
      hintEn: 'e.g. Mandi chicken x2, salad…',
      hintAr: 'مثال: مندي دجاج x2، سلطة…',
      hintZh: '例如：曼迪鸡 x2、沙拉…',
    ),
    ServiceFormFieldDef(
      key: 'deliveryNotes',
      labelEn: 'Delivery notes',
      labelAr: 'ملاحظات التوصيل',
      labelZh: '配送备注',
      kind: ServiceFormFieldKind.multiline,
      required: false,
      hintEn: 'Gate code, landmark, call on arrival…',
      hintAr: 'رمز البوابة، معلم قريب، اتصل عند الوصول…',
      hintZh: '门禁、地标、到达时请致电…',
    ),
  ];
}
