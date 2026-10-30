// Made by Dr Ali
// Local copy for the registration flow (ar / en / zh / fr), keyed by langCode.

class RegistrationStrings {
  const RegistrationStrings(this.langCode);

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

  String get title => _pick(
    'تسجيل شركة',
    'Company Registration',
    '公司注册',
    "Enregistrement d'entreprise",
  );
  String get myApplications =>
      _pick('طلباتي', 'My applications', '我的申请', 'Mes demandes');
  String get startNew => _pick(
    'بدء طلب جديد',
    'Start a new application',
    '开始新申请',
    'Nouvelle demande',
  );
  String get city => _pick('المدينة', 'City', '城市', 'Ville');
  String get activity => _pick(
    'النشاط التجاري',
    'Business activity',
    '业务活动',
    'Activité commerciale',
  );
  String get activityHint => _pick(
    'مثال: تجارة عامة',
    'e.g. general trading',
    '例如：一般贸易',
    'ex. commerce général',
  );
  String get nationality =>
      _pick('الجنسية', 'Nationality', '国籍', 'Nationalité');
  String get insideChina => _pick(
    'أنا حالياً داخل الصين',
    'I am currently inside China',
    '我目前在中国境内',
    'Je suis actuellement en Chine',
  );
  String get qualification => _pick(
    'أعلى مؤهل علمي',
    'Latest academic qualification',
    '最高学历',
    'Dernier diplôme',
  );
  String get accountantTier => _pick(
    'باقة المحاسب العام (اختيارك أنت)',
    'General accountant package (your choice)',
    '总会计套餐（由您选择）',
    'Forfait comptable général (votre choix)',
  );
  String get tierNone => _pick(
    'بدون إقرار استرداد ضريبي',
    'Without tax-refund filing',
    '不含退税申报',
    'Sans déclaration de remboursement de taxe',
  );
  String get tierLt20 => _pick(
    'استرداد ضريبي: أقل من ٢٠ قضية/سنة',
    'Tax-refund filing: fewer than 20 cases/year',
    '退税申报：每年少于20件',
    'Remboursement de taxe : moins de 20 dossiers/an',
  );
  String get tier2050 => _pick(
    'استرداد ضريبي: أكثر من ٢٠ وأقل من ٥٠ قضية/سنة',
    'Tax-refund filing: more than 20, fewer than 50 cases/year',
    '退税申报：每年20至50件',
    'Remboursement de taxe : plus de 20, moins de 50 dossiers/an',
  );
  String get tierHint => _pick(
    'لن نختار عنك أبداً — اختر النطاق الصحيح لعملك.',
    'We never choose for you — pick the scope that fits your business.',
    '我们绝不替您选择——请选择适合您业务的范围。',
    'Nous ne choisissons jamais pour vous — choisissez la portée adaptée à votre activité.',
  );
  String get workResidence => _pick(
    'أضف خدمة تصريح العمل والإقامة',
    'Add work/residence permit service',
    '添加工作/居留许可服务',
    'Ajouter le service permis de travail/résidence',
  );
  String get checkEligibility => _pick(
    'تحقق من الأهلية',
    'Check eligibility',
    '检查资格',
    "Vérifier l'éligibilité",
  );
  String get startApplication =>
      _pick('بدء الطلب', 'Start application', '开始申请', 'Commencer la demande');
  String get eligible => _pick('مؤهل', 'Eligible', '符合资格', 'Éligible');
  String get ineligible =>
      _pick('غير مؤهل', 'Not eligible', '不符合资格', 'Non éligible');
  String get toBeVerified => _pick(
    'قيد التحقق — فريقنا يتحقق قبل أي دفع',
    'To be verified — our team checks before any payment',
    '待核实——我们的团队会在付款前核实',
    'À vérifier — notre équipe vérifie avant tout paiement',
  );
  String get alternatives => _pick(
    'مدن بديلة مقترحة',
    'Suggested alternative cities',
    '推荐的替代城市',
    'Villes alternatives suggérées',
  );
  String get documents => _pick('المستندات', 'Documents', '文件', 'Documents');
  String get required => _pick('إلزامي', 'required', '必填', 'obligatoire');
  String get upload => _pick('رفع', 'Upload', '上传', 'Téléverser');
  String get replace => _pick('استبدال', 'Replace', '替换', 'Remplacer');
  String get camera => _pick('الكاميرا', 'Camera', '相机', 'Appareil photo');
  String get gallery => _pick('المعرض', 'Gallery', '相册', 'Galerie');
  String get submit =>
      _pick('إرسال الطلب', 'Submit application', '提交申请', 'Envoyer la demande');
  String get resubmit => _pick('إعادة الإرسال', 'Resubmit', '重新提交', 'Renvoyer');
  String get cancel =>
      _pick('إلغاء الطلب', 'Cancel application', '取消申请', 'Annuler la demande');
  String get status => _pick('الحالة', 'Status', '状态', 'Statut');
  String get tracking =>
      _pick('رقم التتبع', 'Tracking ID', '跟踪编号', 'N° de suivi');
  String get contract =>
      _pick('رقم العقد', 'Contract ID', '合同编号', 'N° de contrat');
  String get total => _pick('الإجمالي', 'Total', '总计', 'Total');
  String get passportDetails => _pick(
    'بيانات الجواز كما هي مكتوبة فيه',
    'Passport details exactly as printed',
    '护照上的信息（按印刷填写）',
    'Données du passeport telles qu’imprimées',
  );
  String get fullName =>
      _pick('الاسم الكامل', 'Full name', '全名', 'Nom complet');
  String get passportNumber =>
      _pick('رقم الجواز', 'Passport number', '护照号码', 'N° de passeport');
  String get saveDetails =>
      _pick('حفظ البيانات', 'Save details', '保存信息', 'Enregistrer');
  String get readPassport => _pick(
    'قراءة الجواز بالذكاء الاصطناعي',
    'Read passport with OBIC AI',
    '用OBIC AI读取护照',
    'Lire le passeport avec OBIC AI',
  );
  String get ocrOff => _pick(
    'قراءة المستندات غير مفعّلة بعد — سيتحقق الموظف يدوياً.',
    'Document reading is not enabled yet — staff will check manually.',
    '文件读取尚未启用——员工将人工审核。',
    'La lecture de documents n’est pas encore activée — le personnel vérifiera manuellement.',
  );
  String get ocrSent => _pick(
    'تمت القراءة وأُرسلت لمراجعة الموظف.',
    'Read complete — sent to staff review.',
    '读取完成——已发送给员工审核。',
    'Lecture terminée — envoyée au personnel.',
  );
  String get timeline => _pick('الخط الزمني', 'Timeline', '时间线', 'Chronologie');
  String get noApplications =>
      _pick('لا طلبات بعد', 'No applications yet', '暂无申请', 'Aucune demande');
  String get chooseTierFirst => _pick(
    'اختر باقة المحاسب أولاً',
    'Choose an accountant package first',
    '请先选择会计套餐',
    'Choisissez d’abord un forfait comptable',
  );
  String get staffNote =>
      _pick('ملاحظة الموظف', 'Staff note', '员工备注', 'Note du personnel');
}

/// Cities with an approved price matrix in the system (boss Oct 2026).
const kRegistrationCities = [
  'Yiwu',
  'Foshan',
  'Guangzhou',
  'Shenzhen',
  'Shanghai',
  'Beijing',
  'Hainan',
  'Hangzhou',
];
