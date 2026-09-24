// Made by Dr Ali
// Curated OBIC FAQ for AI grounding (AR / EN / ZH). No user PII.
// Source of truth for FAQ snippets — keep in sync with support playbooks.
// Catalog prices come from mega-catalog.seed.ts via AiGroundingService.

export type FaqEntry = {
  id: string;
  /** Keywords matched (lowercased, any language tokens). */
  keywords: string[];
  ar: string;
  en: string;
  zh: string;
};

export const OBIC_FAQ: FaqEntry[] = [
  {
    id: 'talk-to-staff',
    keywords: [
      'staff',
      'human',
      'agent',
      'support',
      'موظف',
      'دعم',
      'بشري',
      '人工',
      '客服',
      'talk to staff',
      'تحدث',
    ],
    ar: 'لطلب موظف بشري: افتح محادثة الدعم أو الطلب واضغط «تحدث مع الفريق». يتوقف الرد التلقائي للذكاء الاصطناعي على ذلك الخيط.',
    en: 'To reach a human: open Support or an order chat and tap “Talk to staff”. AI auto-reply pauses on that thread.',
    zh: '联系人工：打开客服或订单聊天，点「联系人工」。该会话的 AI 自动回复会暂停。',
  },
  {
    id: 'order-status',
    keywords: [
      'order',
      'status',
      'tracking',
      'طلب',
      'حالة',
      'تتبع',
      '订单',
      '状态',
      '进度',
    ],
    ar: 'حالة الطلب تظهر في تبويب الطلبات داخل التطبيق. المساعد لا يخترع حالة الدفع أو الإتمام — تحقق من الطلبات أو اطلب موظفاً.',
    en: 'Order status is in the app Orders tab. The assistant must not invent paid/completed status — check Orders or ask staff.',
    zh: '订单状态在应用「订单」页查看。助手不得编造已付款/已完成 — 请查订单或联系人工。',
  },
  {
    id: 'languages',
    keywords: [
      'language',
      'arabic',
      'chinese',
      'english',
      'لغة',
      'عربي',
      'صيني',
      '语言',
      '中文',
      '阿拉伯',
    ],
    ar: 'OBIC يدعم العربية والإنجليزية والصينية في التطبيق والمساعد. الرد يتبع لغة رسالة المستخدم.',
    en: 'OBIC supports Arabic, English, and Chinese in the app and assistant. Replies follow the user’s message language.',
    zh: 'OBIC 应用与助手支持阿拉伯语、英语、中文。回复跟随用户消息语言。',
  },
  {
    id: 'prices',
    keywords: [
      'price',
      'cost',
      'fee',
      'سعر',
      'تكلفة',
      'رسوم',
      '价格',
      '费用',
      '多少钱',
    ],
    ar: 'الأسعار المعروضة في الكتالوج إرشادية («من …»). التسعير النهائي يؤكد عبر الطلب أو الموظف — لا تخترع أسعاراً غير موجودة في السياق.',
    en: 'Catalog prices are indicative (“From …”). Final pricing is confirmed via an order or staff — never invent prices missing from context.',
    zh: '目录价格为参考（「起」）。最终报价以订单或人工确认为准 — 上下文没有的价格不得编造。',
  },
  {
    id: 'branches',
    keywords: [
      'branch',
      'yiwu',
      'guangzhou',
      'office',
      'فرع',
      'إيوو',
      'قوانغتشو',
      '网点',
      '义乌',
      '广州',
    ],
    ar: 'لدى OBIC فروع في الصين (مثل إيوو وقوانغتشو وغيرها). اختر الفرع المفضل عند إنشاء الطلب؛ التوجيه يتم حسب الخدمة والفرع.',
    en: 'OBIC has branches in China (e.g. Yiwu, Guangzhou, and others). Pick a preferred branch when creating an order; routing follows service + branch.',
    zh: 'OBIC 在中国设有网点（如义乌、广州等）。下单时选择首选网点；按服务与网点路由。',
  },
  {
    id: 'visa',
    keywords: [
      'visa',
      'invitation',
      'تأشيرة',
      'دعوة',
      '签证',
      '邀请',
    ],
    ar: 'خدمات التأشيرة والدعوات ضمن كتالوج السفر/الأعمال. المتطلبات تختلف حسب الجنسية والغرض — قدّم طلباً أو اطلب موظفاً للتفاصيل الدقيقة.',
    en: 'Visa and invitation help are in the travel/business catalog. Requirements vary by nationality and purpose — submit an order or ask staff for exact docs.',
    zh: '签证与邀请函在旅行/商务目录中。材料因国籍与目的而异 — 请下单或咨询人工获取准确清单。',
  },
  {
    id: 'payment',
    keywords: [
      'pay',
      'payment',
      'card',
      'alipay',
      'wechat',
      'دفع',
      'بطاقة',
      '支付',
      '支付宝',
      '微信',
    ],
    ar: 'لا تطلب كلمات مرور أو OTP أو أرقام بطاقات كاملة. الدفع يتم عبر قنوات OBIC المعتمدة داخل الطلب أو مع الموظف.',
    en: 'Never ask for passwords, OTP, or full card numbers. Payment goes through OBIC’s approved channels in-order or with staff.',
    zh: '切勿索要密码、OTP 或完整卡号。支付通过 OBIC 认可渠道（订单内或人工）完成。',
  },
  {
    id: 'friend-chat',
    keywords: ['friend', 'dm', 'private', 'صديق', 'خاص', '好友', '私聊'],
    ar: 'محادثات الأصدقاء الخاصة بلا رد تلقائي من الذكاء الاصطناعي — الترجمة اختيارية فقط.',
    en: 'Friend (DM) chats have no AI auto-reply — optional translate only.',
    zh: '好友私聊无 AI 自动回复 — 仅可选翻译。',
  },
  {
    id: 'offers',
    keywords: [
      'hotel',
      'flight',
      'offer',
      'فندق',
      'طيران',
      'عرض',
      '酒店',
      '机票',
      '优惠',
    ],
    ar: 'عروض الفنادق والطيران تظهر في تبويب العروض عند توفرها. التوفر والأسعار تتغير — أكد من التطبيق أو الموظف.',
    en: 'Hotel and flight offers appear in the Offers tab when published. Availability and prices change — confirm in-app or with staff.',
    zh: '酒店与机票优惠在「优惠」页发布后可见。库存与价格会变 — 请在应用内或向人工确认。',
  },
  {
    id: 'account',
    keywords: [
      'account',
      'login',
      'password',
      'حساب',
      'دخول',
      'كلمة',
      '账号',
      '登录',
      '密码',
    ],
    ar: 'لمشاكل الحساب أو تسجيل الدخول استخدم الشاشات في التطبيق أو اطلب موظفاً — لا تشارك كلمة المرور مع المساعد.',
    en: 'For account or login issues use in-app screens or ask staff — never share passwords with the assistant.',
    zh: '账号或登录问题请用应用内页面或联系人工 — 切勿向助手分享密码。',
  },
];
