/**
 * OBIC website catalog — same category *data* as live obicgp.com
 * (names + slugs + URLs). No old CMS images — clean icons only.
 */
(function (global) {
  const LIVE = "https://www.obicgp.com";

  const FALLBACK_HUBS = [
    { slug: "legal-services", icon: "legal", nameEn: "Legal Services", nameAr: "خدمات قانونية", nameZh: "法律服务", descEn: "Contracts, counsel, and compliance in China.", descAr: "عقود واستشارات والامتثال في الصين.", descZh: "中国合同、法律咨询与合规。" },
    { slug: "flight", icon: "flight", nameEn: "Flight", nameAr: "طيران", nameZh: "机票", descEn: "Domestic and international flight support.", descAr: "دعم الرحلات الداخلية والدولية.", descZh: "国内国际航班支持。" },
    { slug: "open-bank-account", icon: "bank", nameEn: "Open a bank account", nameAr: "فتح حساب بنكي", nameZh: "开户", descEn: "Guided bank account opening.", descAr: "فتح حساب بنكي بإرشاد محلي.", descZh: "协助开设银行账户。" },
    { slug: "hotel", icon: "hotel", nameEn: "Hotel", nameAr: "فنادق", nameZh: "酒店", descEn: "Hotels and short stays across China.", descAr: "فنادق وإقامات قصيرة في الصين.", descZh: "中国各地酒店与短住。" },
    { slug: "visa", icon: "visa", nameEn: "Visa", nameAr: "تأشيرة", nameZh: "签证", descEn: "China visa support for individuals and teams.", descAr: "دعم تأشيرة الصين للأفراد والفرق.", descZh: "个人与团队中国签证支持。" },
    { slug: "company-registration", icon: "company", nameEn: "Company registration", nameAr: "تسجيل شركة", nameZh: "公司注册", descEn: "Register and structure your company in China.", descAr: "تسجيل وهيكلة شركتك في الصين.", descZh: "在中国注册与搭建公司。", href: "/open-company.html" },
    { slug: "vip-service", icon: "vip", nameEn: "VIP Service", nameAr: "خدمة VIP", nameZh: "VIP服务", descEn: "Airport, hosting, and priority assistance.", descAr: "مطار واستقبال ومساعدة ذات أولوية.", descZh: "机场、接待与优先协助。" },
    { slug: "money-transfer", icon: "payments", nameEn: "Money Transfer", nameAr: "تحويل أموال", nameZh: "汇款", descEn: "Cross-border transfer assistance.", descAr: "مساعدة التحويل عبر الحدود.", descZh: "跨境汇款协助。" },
    { slug: "scholarships", icon: "school", nameEn: "Scholarships", nameAr: "منح دراسية", nameZh: "奖学金", descEn: "Study pathways and scholarship guidance.", descAr: "مسارات دراسية وإرشاد المنح.", descZh: "留学路径与奖学金指导。", href: "/study-china.html" },
    { slug: "advertisements", icon: "ads", nameEn: "Advertisements", nameAr: "إعلانات", nameZh: "广告", descEn: "Marketing and advertising support.", descAr: "دعم التسويق والإعلان.", descZh: "营销与广告支持。" },
    { slug: "business-services", icon: "business", nameEn: "Business Services", nameAr: "خدمات أعمال", nameZh: "商务服务", descEn: "Day-to-day business support in China.", descAr: "دعم الأعمال اليومي في الصين.", descZh: "在华日常商务支持。" },
    { slug: "human-resources", icon: "hr", nameEn: "Human Resources", nameAr: "موارد بشرية", nameZh: "人力资源", descEn: "Hiring and HR support.", descAr: "توظيف ودعم الموارد البشرية.", descZh: "招聘与人力支持。" },
    { slug: "insurance-and-protection", icon: "shield", nameEn: "Insurance and Protection", nameAr: "تأمين وحماية", nameZh: "保险与保障", descEn: "Insurance and protection options.", descAr: "خيارات التأمين والحماية.", descZh: "保险与保障方案。" },
    { slug: "international-expansion", icon: "globe", nameEn: "International expansion", nameAr: "توسع دولي", nameZh: "国际拓展", descEn: "Grow your presence across markets.", descAr: "وسّع حضورك عبر الأسواق.", descZh: "跨市场拓展业务。" },
    { slug: "technical-support", icon: "tech", nameEn: "Technical Support", nameAr: "دعم تقني", nameZh: "技术支持", descEn: "Technical help for your operations.", descAr: "مساعدة تقنية لعملياتك.", descZh: "业务技术协助。" },
    { slug: "business-planning", icon: "plan", nameEn: "Business Planning", nameAr: "تخطيط أعمال", nameZh: "商业规划", descEn: "Plans and strategy for China.", descAr: "خطط واستراتيجية للصين.", descZh: "中国业务规划与策略。" },
  ].map((h) => ({
    ...h,
    href: h.href || "/category/" + h.slug,
  }));

  function apiBase() {
    return (global.OBIC_API_BASE || "").replace(/\/$/, "");
  }

  async function fetchJson(path) {
    const base = apiBase();
    if (!base) return null;
    const res = await fetch(`${base}${path}`, { headers: { Accept: "application/json" } });
    if (!res.ok) throw new Error("API " + res.status);
    return res.json();
  }

  const CATALOG_ICONS = {
    property: "company",
    directions_car: "flight",
    tourism: "vip",
    local_hospital: "shield",
    restaurant: "plan",
    shopping_bag: "payments",
    school: "school",
    local_shipping: "globe",
    account_balance: "bank",
    biz: "business",
  };

  function catalogHubs() {
    const parents = global.ObicCatalog && global.ObicCatalog.PARENTS;
    if (!parents || !parents.length) return null;
    return parents.map((p) => ({
      ...p,
      icon: CATALOG_ICONS[p.icon] || "business",
      href: "/category/" + p.slug,
    }));
  }

  async function listServices() {
    const fromCatalog = catalogHubs();
    if (fromCatalog) return { source: "catalog", items: fromCatalog };
    try {
      const data = await fetchJson("/services");
      if (Array.isArray(data) && data.length) return { source: "api", items: data };
      if (data && Array.isArray(data.items) && data.items.length) return { source: "api", items: data.items };
    } catch (_) {}
    return { source: "live", items: FALLBACK_HUBS };
  }

  async function listSubServices() {
    return { source: "empty", items: [] };
  }

  async function listOffers() {
    return { source: "empty", items: [] };
  }

  function hubLabel(item, lang) {
    if (lang === "ar") return item.nameAr || item.nameEn;
    if (lang === "zh") return item.nameZh || item.nameEn;
    return item.nameEn || item.name || item.slug;
  }

  function hubDesc(item, lang) {
    if (lang === "ar") return item.descAr || item.descEn || "";
    if (lang === "zh") return item.descZh || item.descEn || "";
    return item.descEn || item.desc || "";
  }

  function hubHref(item) {
    const slug = item.slug || "";
    if (item.href) return item.href;
    if (slug === "company-registration") return "/open-company.html";
    if (slug === "scholarships") return "/study-china.html";
    return "/category/" + slug;
  }

  global.ObicApi = {
    FALLBACK_HUBS,
    LIVE,
    apiBase,
    listServices,
    listSubServices,
    listOffers,
    hubLabel,
    hubDesc,
    hubHref,
  };
})(window);
