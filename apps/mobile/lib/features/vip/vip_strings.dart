// Made by Dr Ali
// Local copy for the VIP flow (ar / en / zh / fr), keyed by langCode.

class VipStrings {
  const VipStrings(this.langCode);

  final String langCode;

  String get _l => langCode.startsWith('ar')
      ? 'ar'
      : langCode.startsWith('zh')
      ? 'zh'
      : langCode.startsWith('fr')
      ? 'fr'
      : 'en';

  String _pick(String ar, String en, String zh, String fr) => switch (_l) {
    'ar' => ar,
    'zh' => zh,
    'fr' => fr,
    _ => en,
  };

  String get title =>
      _pick('خدمات VIP', 'VIP Services', 'VIP服务', 'Services VIP');
  String get consultations => _pick(
    'استشارات مؤقتة',
    'Timed consultations',
    '计时咨询',
    'Consultations limitées',
  );
  String get consultHint => _pick(
    'جلسة تنتهي تلقائياً عند انتهاء الوقت — لا تمديد تلقائي أبداً. لوقت إضافي اشترِ جلسة جديدة.',
    'A session ends automatically when time is up — never auto-extended. For more time, buy a new session.',
    '会话到时自动结束——绝不自动延长。如需更多时间，请购买新会话。',
    'Une session se termine automatiquement à la fin du temps — jamais prolongée automatiquement. Pour plus de temps, achetez une nouvelle session.',
  );
  String get minutes => _pick('دقيقة', 'min', '分钟', 'min');
  String get buy => _pick('شراء', 'Buy', '购买', 'Acheter');
  String get start => _pick('بدء', 'Start', '开始', 'Commencer');
  String get end => _pick('إنهاء', 'End', '结束', 'Terminer');
  String get remaining => _pick('المتبقي', 'remaining', '剩余', 'restant');
  String get pendingPayment => _pick(
    'بانتظار الدفع',
    'Waiting for payment',
    '等待付款',
    'En attente de paiement',
  );
  String get mySessions =>
      _pick('جلساتي', 'My sessions', '我的会话', 'Mes sessions');
  String get myTrips => _pick('رحلاتي', 'My trips', '我的行程', 'Mes voyages');
  String get tripBuilder => _pick(
    'بناء رحلة VIP',
    'Build a VIP trip',
    '创建VIP行程',
    'Créer un voyage VIP',
  );
  String get purpose =>
      _pick('غرض الرحلة', 'Trip purpose', '出行目的', 'Objet du voyage');
  String get cities => _pick(
    'المدن (مفصولة بفواصل)',
    'Cities (comma separated)',
    '城市（逗号分隔）',
    'Villes (séparées par des virgules)',
  );
  String get days =>
      _pick('عدد الأيام', 'Number of days', '天数', 'Nombre de jours');
  String get people => _pick('عدد الأشخاص', 'People', '人数', 'Personnes');
  String get notes => _pick('ملاحظات', 'Notes', '备注', 'Notes');
  String get createTrip =>
      _pick('إنشاء الرحلة', 'Create trip', '创建行程', 'Créer le voyage');
  String get getQuote =>
      _pick('احسب السعر', 'Get quotation', '获取报价', 'Obtenir un devis');
  String get accept =>
      _pick('قبول السعر', 'Accept quotation', '接受报价', 'Accepter le devis');
  String get cancel => _pick('إلغاء', 'Cancel', '取消', 'Annuler');
  String get total => _pick('الإجمالي', 'Total', '总计', 'Total');
  String get status => _pick('الحالة', 'Status', '状态', 'Statut');
  String get coordinationNote => _pick(
    'رسوم التنسيق المعتمدة: ٥ أيام ¥10,000 — ١٠ أيام ¥15,000 — ١٥ يوماً ¥20,000 — ٢٠ يوماً ¥25,000 — ٣٠ يوماً ¥35,000 — ٦٠ يوماً ¥65,000. أي مدة أخرى تحتاج اعتماد الإدارة.',
    'Approved coordination fees: 5d ¥10,000 · 10d ¥15,000 · 15d ¥20,000 · 20d ¥25,000 · 30d ¥35,000 · 60d ¥65,000. Any other duration needs management approval.',
    '已批准的协调费：5天 ¥10,000 · 10天 ¥15,000 · 15天 ¥20,000 · 20天 ¥25,000 · 30天 ¥35,000 · 60天 ¥65,000。其他天数需管理层批准。',
    'Frais de coordination approuvés : 5 j ¥10 000 · 10 j ¥15 000 · 15 j ¥20 000 · 20 j ¥25 000 · 30 j ¥35 000 · 60 j ¥65 000. Toute autre durée requiert l’approbation de la direction.',
  );
  String get none =>
      _pick('لا شيء بعد', 'Nothing yet', '暂无', 'Rien pour le moment');
}

const kConsultationPrices = <int, String>{
  10: '\$10',
  20: '\$18',
  30: '\$26',
  60: '\$50',
};

const kTripPurposes = ['BIZ', 'TOUR', 'MED', 'STU', 'INV', 'MIX'];
