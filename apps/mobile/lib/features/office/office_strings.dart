// Made by Dr Ali
// AR/EN/ZH/FR labels for personal office mini-apps.

class OfficeStrings {
  OfficeStrings(this.langCode);

  final String langCode;

  bool get _ar => langCode.startsWith('ar');
  bool get _zh => langCode.startsWith('zh');
  bool get _fr => langCode.startsWith('fr');

  String get notes => _ar
      ? 'ملاحظات'
      : _zh
          ? '笔记'
          : _fr
              ? 'Notes'
              : 'Notes';

  String get documents => _ar
      ? 'مستندات'
      : _zh
          ? '文档'
          : _fr
              ? 'Documents'
              : 'Documents';

  String get spreadsheets => _ar
      ? 'جداول'
      : _zh
          ? '表格'
          : _fr
              ? 'Feuilles'
              : 'Spreadsheets';

  String get pdf => _ar
      ? 'عرض PDF'
      : _zh
          ? 'PDF 查看'
          : _fr
              ? 'Lecteur PDF'
              : 'PDF viewer';

  String get slides => _ar
      ? 'عروض'
      : _zh
          ? '演示文稿'
          : _fr
              ? 'Diapositives'
              : 'Slides';

  String get comingSoon => _ar
      ? 'قريباً'
      : _zh
          ? '即将推出'
          : _fr
              ? 'Bientôt'
              : 'Coming soon';

  String get onlyOfficeSoon => _ar
      ? 'محرر أوفيس الكامل (OnlyOffice) قريباً على خادم أكبر. الآن: ملاحظات ومستندات وجداول نصية.'
      : _zh
          ? '完整 OnlyOffice 编辑器需更大服务器，即将推出。现在可用：笔记、文本文档与表格。'
          : _fr
              ? 'Éditeur OnlyOffice complet bientôt (serveur plus grand). Pour l’instant : notes, docs et feuilles texte.'
              : 'Full OnlyOffice soon on a larger server. Live now: Notes, text Docs, and Sheets.';

  String get newItem => _ar
      ? 'جديد'
      : _zh
          ? '新建'
          : _fr
              ? 'Nouveau'
              : 'New';

  String get save => _ar
      ? 'حفظ'
      : _zh
          ? '保存'
          : _fr
              ? 'Enregistrer'
              : 'Save';

  String get share => _ar
      ? 'مشاركة مع جهات الاتصال'
      : _zh
          ? '分享给联系人'
          : _fr
              ? 'Partager avec des contacts'
              : 'Share with contacts';

  String get empty => _ar
      ? 'لا عناصر بعد.'
      : _zh
          ? '还没有内容。'
          : _fr
              ? 'Aucun élément.'
              : 'Nothing yet.';

  String get loadFailed => _ar
      ? 'تعذر التحميل'
      : _zh
          ? '加载失败'
          : _fr
              ? 'Échec du chargement'
              : 'Could not load';

  String get signInRequired => _ar
      ? 'سجّل الدخول لاستخدام التطبيقات المكتبية.'
      : _zh
          ? '请登录后使用办公小程序。'
          : _fr
              ? 'Connectez-vous pour les mini-apps bureau.'
              : 'Sign in to use office mini-apps.';

  String get titleHint => _ar
      ? 'العنوان'
      : _zh
          ? '标题'
          : _fr
              ? 'Titre'
              : 'Title';

  String get bodyHint => _ar
      ? 'اكتب هنا…'
      : _zh
          ? '在此输入…'
          : _fr
              ? 'Écrire ici…'
              : 'Write here…';

  String get pdfUrlHint => _ar
      ? 'رابط PDF (https)'
      : _zh
          ? 'PDF 链接 (https)'
          : _fr
              ? 'URL PDF (https)'
              : 'PDF URL (https)';

  String get openPdf => _ar
      ? 'فتح'
      : _zh
          ? '打开'
          : _fr
              ? 'Ouvrir'
              : 'Open';
}
