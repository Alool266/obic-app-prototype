// Made by Dr Ali
// Copy for the in-app boss-module admin screens (prices, registration, VIP).
// Four languages like the rest of the app: ar / en / zh / fr.

class AdminBossStrings {
  const AdminBossStrings(this.code);

  final String code;

  String get _l => code.startsWith('ar')
      ? 'ar'
      : code.startsWith('zh')
      ? 'zh'
      : code.startsWith('fr')
      ? 'fr'
      : 'en';

  String _p(String ar, String en, String zh, String fr) => switch (_l) {
    'ar' => ar,
    'zh' => zh,
    'fr' => fr,
    _ => en,
  };

  String get pricesTitle =>
      _p('الأسعار المعتمدة', 'Versioned prices', '版本价格', 'Prix versionnés');
  String get pricesSub => _p(
    'مسودة ← مراجعة ← اعتماد ← تفعيل ← إيقاف · المشرف الأعلى فقط',
    'Draft → Review → Approved → Active → Retired · SuperAdmin only',
    '草稿 → 审核 → 批准 → 生效 → 停用 · 仅超级管理员',
    'Brouillon → Révision → Approuvé → Actif → Retiré · Super-admin uniquement',
  );
  String get eligibilityTitle =>
      _p('قواعد الأهلية', 'Eligibility rules', '资格规则', "Règles d'éligibilité");
  String get registrationTitle => _p(
    'طلبات تسجيل الشركات',
    'Company registrations',
    '公司注册申请',
    "Demandes d'enregistrement",
  );
  String get registrationSub => _p(
    'مراجعة المستندات أخضر/أصفر/أحمر · تصحيح وإعادة إرسال',
    'Document review Green/Yellow/Red · correction & resubmit',
    '文件审核 绿/黄/红 · 更正与重新提交',
    'Revue des documents Vert/Jaune/Rouge · correction et renvoi',
  );
  String get vipTitle =>
      _p('خدمات VIP', 'VIP services', 'VIP服务', 'Services VIP');
  String get vipSub => _p(
    'استشارات مؤقتة ورحلات · دفع خارجي · المجموعة الرسمية',
    'Consultations & trips · external payment · official group',
    '咨询与行程 · 外部付款 · 官方群组',
    'Consultations et voyages · paiement externe · groupe officiel',
  );
  String get ocrQueue => _p(
    'قراءات الجواز بانتظار القرار',
    'Passport readings awaiting decision',
    '等待决定的护照读取',
    'Lectures de passeport en attente',
  );
  String get approve => _p('قبول', 'Approve', '通过', 'Approuver');
  String get correction =>
      _p('طلب تصحيح', 'Request correction', '要求更正', 'Demander une correction');
  String get block => _p('حظر', 'Block', '阻止', 'Bloquer');
  String get confirmReading =>
      _p('تأكيد القراءة', 'Confirm reading', '确认读取', 'Confirmer la lecture');
  String get rejectReading => _p(
    'رفض وطلب تصحيح',
    'Reject & request correction',
    '拒绝并要求更正',
    'Rejeter et demander une correction',
  );
  String get notePrompt => _p(
    'ما الذي يجب تصحيحه بالضبط؟ (الحقل + السبب)',
    'Exactly what must be fixed? (field + reason)',
    '具体需要修改什么？（字段+原因）',
    'Que faut-il corriger exactement ? (champ + raison)',
  );
  String get markPaid => _p('تسجيل دفع', 'Mark paid', '记录付款', 'Marquer payé');
  String get paidPrompt => _p(
    'مرجع الدفع الخارجي',
    'External payment reference',
    '外部付款凭证',
    'Référence du paiement externe',
  );
  String get assign =>
      _p('تعيين موظف', 'Assign employee', '指派员工', 'Attribuer un employé');
  String get assignPrompt => _p(
    'معرف الموظف (UUID)',
    'Employee ID (UUID)',
    '员工ID (UUID)',
    "ID de l'employé (UUID)",
  );
  String get createGroup => _p(
    'إنشاء المجموعة الرسمية',
    'Create official group',
    '创建官方群组',
    'Créer le groupe officiel',
  );
  String get groupPrompt => _p(
    'معرفات الطاقم مفصولة بفواصل',
    'Staff UUIDs, comma-separated',
    '员工UUID，逗号分隔',
    'UUID du personnel, séparés par des virgules',
  );
  String get totpPrompt => _p(
    'رمز المصادقة (٦ أرقام) — اتركه فارغاً إن لم يكن مطلوباً',
    'Authenticator code (6 digits) — leave empty if not required',
    '验证器代码（6位）——如不需要可留空',
    'Code Authenticator (6 chiffres) — laisser vide si non requis',
  );
  String get effectivePrompt => _p(
    'تاريخ السريان (YYYY-MM-DD)',
    'Effective date (YYYY-MM-DD)',
    '生效日期 (YYYY-MM-DD)',
    'Date d’effet (YYYY-MM-DD)',
  );
  String get documents => _p('المستندات', 'Documents', '文件', 'Documents');
  String get timeline => _p('الخط الزمني', 'Timeline', '时间线', 'Chronologie');
  String get trips => _p('رحلات VIP', 'VIP trips', 'VIP行程', 'Voyages VIP');
  String get sessions => _p(
    'الاستشارات المؤقتة',
    'Timed consultations',
    '计时咨询',
    'Consultations limitées',
  );
  String get none =>
      _p('لا شيء بعد', 'Nothing yet', '暂无', 'Rien pour le moment');
  String get save => _p('حفظ', 'Save', '保存', 'Enregistrer');
  String get cancel => _p('إلغاء', 'Cancel', '取消', 'Annuler');
  String get total => _p('الإجمالي', 'Total', '总计', 'Total');
}
