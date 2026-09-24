#!/usr/bin/env node
// Made by Dr Ali — realistic Trip.com-style hotel/flight offers + WeChat Moments with photos.
// Hotels by Guangzhou Marketing; flights by Yiwu Marketing; moments by marketing + admin.

const API = process.env.API_BASE_URL || 'http://127.0.0.1:3001';
const FORCE = process.env.FORCE_DEMO_SEED === '1';

async function json(method, path, body, token) {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data = {};
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { raw: text };
  }
  if (!res.ok) {
    throw new Error(`${method} ${path} → ${res.status}: ${JSON.stringify(data)}`);
  }
  return data;
}

async function login(email, password) {
  const data = await json('POST', '/v1/auth/login', { email, password });
  return data.accessToken;
}

function img(url) {
  return [{ kind: 'image', url, name: 'photo.jpg', mime: 'image/jpeg' }];
}

const HOTELS = [
  {
    titleAr: 'فندق هيلتون غوانغتشو تيانهي — 5 نجوم',
    titleEn: 'Hilton Guangzhou Tianhe — 5★',
    bodyAr:
      'غرفة ديلوكس كينغ مع إفطار مجاني، واي فاي، وحمام سباحة ومركز أعمال. موقع ممتاز قرب محطة القطار. حجز عبر OBIC مع دعم عربي.',
    bodyEn:
      'Deluxe King room with free breakfast, Wi‑Fi, pool & business center. Steps from the train station. Book via OBIC with Arabic support.',
    priceLabelAr: 'من 89$ / ليلة',
    priceLabelEn: 'From $89 / night',
    locationLabel: 'Guangzhou · Tianhe',
    datesLabel: 'Sep–Dec 2026',
    media: img('https://images.unsplash.com/photo-1566073771259-6a8506099945?w=900&q=80'),
    attributes: {
      demoSeed: true,
      starRating: 5,
      roomType: 'Deluxe King',
      breakfast: true,
      wifi: true,
      pool: true,
      nights: 3,
      guests: 2,
      city: 'Guangzhou',
      amenities: ['Breakfast', 'Pool', 'Gym', 'Free Wi‑Fi'],
    },
  },
  {
    titleAr: 'ماريوت غوانغتشو — إطلالة على نهر اللؤلؤ',
    titleEn: 'Marriott Guangzhou — Pearl River View',
    bodyAr: 'جناح عائلي واسع، مطعم عالمي، خدمة كونسierge. مناسب للوفود التجارية من اليمن والخليج.',
    bodyEn: 'Spacious family suite, international dining, concierge. Ideal for trade delegations from Yemen & GCC.',
    priceLabelAr: 'من 95$ / ليلة',
    priceLabelEn: 'From $95 / night',
    locationLabel: 'Guangzhou · Haizhu',
    datesLabel: 'Flexible dates',
    media: img('https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=900&q=80'),
    attributes: {
      demoSeed: true,
      starRating: 5,
      roomType: 'Family Suite',
      breakfast: true,
      wifi: true,
      city: 'Guangzhou',
      amenities: ['River view', 'Restaurant', 'Concierge'],
    },
  },
  {
    titleAr: 'بولمان غوانغتشو — غرفة تنفيذية',
    titleEn: 'Pullman Guangzhou — Executive Room',
    bodyAr: 'غرفة تنفيذية مع lounge، إفطار، وموقف سيارات. قريب من معارض كanton Fair.',
    bodyEn: 'Executive room with lounge access, breakfast & parking. Near Canton Fair halls.',
    priceLabelAr: 'من 72$ / ليلة',
    priceLabelEn: 'From $72 / night',
    locationLabel: 'Guangzhou · Pazhou',
    datesLabel: 'Canton Fair weeks',
    media: img('https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=900&q=80'),
    attributes: {
      demoSeed: true,
      starRating: 4,
      roomType: 'Executive',
      breakfast: true,
      wifi: true,
      city: 'Guangzhou',
      amenities: ['Executive lounge', 'Parking'],
    },
  },
  {
    titleAr: 'Shangri-La Guangzhou — فخامة وخدمة 5 نجوم',
    titleEn: 'Shangri-La Guangzhou — Luxury 5★',
    bodyAr: 'جناح بانورامي، سبا، مطاعم فاخرة. خيار ممتاز لعملاء VIP.',
    bodyEn: 'Panoramic suite, spa, fine dining. Premium choice for VIP clients.',
    priceLabelAr: 'من 145$ / ليلة',
    priceLabelEn: 'From $145 / night',
    locationLabel: 'Guangzhou · Pazhou',
    datesLabel: 'Year-round',
    media: img('https://images.unsplash.com/photo-1618773928123-c1ed9a7f4e3a?w=900&q=80'),
    attributes: {
      demoSeed: true,
      starRating: 5,
      roomType: 'Panoramic Suite',
      breakfast: true,
      spa: true,
      city: 'Guangzhou',
      amenities: ['Spa', 'Fine dining', 'VIP desk'],
    },
  },
  {
    titleAr: 'فندق ييوu الدولي — قرب السوق',
    titleEn: 'Yiwu International Hotel — Near market',
    bodyAr: 'فندق 4 نجوم على بعد دقائق من سوق ييوu الدولي. مناسب لتجار الجملة.',
    bodyEn: '4★ hotel minutes from Yiwu International Trade City. Built for wholesale buyers.',
    priceLabelAr: 'من 58$ / ليلة',
    priceLabelEn: 'From $58 / night',
    locationLabel: 'Yiwu · Futian',
    datesLabel: 'Any week',
    media: img('https://images.unsplash.com/photo-1520250497591-112f2f40a3b4?w=900&q=80'),
    attributes: {
      demoSeed: true,
      starRating: 4,
      roomType: 'Standard Twin',
      breakfast: true,
      wifi: true,
      city: 'Yiwu',
      amenities: ['Market shuttle', 'Business center'],
    },
  },
  {
    titleAr: 'منتجع West Lake هانغzhou — إطلالة على البحيرة',
    titleEn: 'Hangzhou West Lake Resort — Lake view',
    bodyAr: 'منتجع 5 نجوم على بحيرة West Lake. إقامة هادئة بعد رحلات التوريد.',
    bodyEn: '5★ resort on West Lake. Calm stay after sourcing trips.',
    priceLabelAr: 'من 110$ / ليلة',
    priceLabelEn: 'From $110 / night',
    locationLabel: 'Hangzhou · West Lake',
    datesLabel: 'Spring & Autumn',
    media: img('https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=900&q=80'),
    attributes: {
      demoSeed: true,
      starRating: 5,
      roomType: 'Lake View',
      breakfast: true,
      city: 'Hangzhou',
      amenities: ['Lake view', 'Garden', 'Tea lounge'],
    },
  },
  {
    titleAr: 'منتجع Sanya — شاطئ وبحر',
    titleEn: 'Sanya Beach Resort — Sea & sand',
    bodyAr: 'غرفة مطلة على البحر في Hainan. باقة 3 ليالٍ مع إفطار.',
    bodyEn: 'Ocean-view room in Hainan. 3-night package with breakfast.',
    priceLabelAr: 'من 128$ / ليلة',
    priceLabelEn: 'From $128 / night',
    locationLabel: 'Sanya · Hainan',
    datesLabel: 'Oct 2026 – Mar 2027',
    media: img('https://images.unsplash.com/photo-1520250497591-112f2f40a3b4?w=900&q=80'),
    attributes: {
      demoSeed: true,
      starRating: 5,
      roomType: 'Ocean View',
      breakfast: true,
      pool: true,
      nights: 3,
      city: 'Sanya',
      amenities: ['Beach access', 'Pool', 'Breakfast'],
    },
  },
  {
    titleAr: 'Holiday Inn Foshan — للوفود الصناعية',
    titleEn: 'Holiday Inn Foshan — Industrial delegations',
    bodyAr: 'فندق عملي قرب مصانع Foshan. أسعار تنافسية وواي فاي سريع.',
    bodyEn: 'Practical hotel near Foshan factories. Competitive rates & fast Wi‑Fi.',
    priceLabelAr: 'من 49$ / ليلة',
    priceLabelEn: 'From $49 / night',
    locationLabel: 'Foshan · Chancheng',
    datesLabel: 'Flexible',
    media: img('https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=900&q=80'),
    attributes: {
      demoSeed: true,
      starRating: 4,
      roomType: 'Standard',
      wifi: true,
      city: 'Foshan',
      amenities: ['Factory visits', 'Wi‑Fi', 'Parking'],
    },
  },
];

// Real venue names from public web guides (Guangzhou + Yiwu) for Meituan-style research.
// Not yet live Meituan/Ele.me API — catalog research seed until partner contracts.
const RESTAURANTS = [
  {
    titleAr: 'Bosphorus — تركي حلال · غوانغتشو',
    titleEn: 'Bosphorus Turkish — Guangzhou Tianhe',
    bodyAr:
      'مطعم تركي شهير في珠江新城 / تيانخه. مشاوي، بيدة، ومأكولات شرق أوسطية حلال. مرجع بحث Meituan.',
    bodyEn:
      'Well-known Turkish restaurant in Zhujiang New Town / Tianhe. Grills, pide & halal Middle Eastern. Meituan research reference.',
    priceLabelAr: 'متوسط 15–25$ · تيانخه',
    priceLabelEn: '~$15–25 avg · Tianhe',
    locationLabel: 'Guangzhou · Tianhe · Xingsheng Rd',
    datesLabel: 'Open daily · ~10:00–22:00',
    media: img('https://images.unsplash.com/photo-1529042410799-b584dafa900b?w=900&q=80'),
    attributes: {
      demoSeed: true,
      internetResearch: true,
      cuisine: 'turkish',
      cuisineLabel: 'Turkish',
      rating: 4.4,
      reviewCount: 885,
      deliveryMins: '30–45 min',
      minOrder: 12,
      deliveryFee: 3,
      city: 'Guangzhou',
      tags: ['Halal', 'Turkish', 'Meituan research'],
    },
  },
  {
    titleAr: 'Al Bustan — يمني · غوانغتشو',
    titleEn: 'Al Bustan Yemeni — Guangzhou',
    bodyAr: 'مطعم يمني معروف قرب محطة القطار / مسجد سعد بن أبي وقاص. مندي ومأكولات يمنية.',
    bodyEn: 'Known Yemeni restaurant near train station / Saad Bin Waqas mosque area. Mandi & Yemeni dishes.',
    priceLabelAr: 'متوسط 10–18$',
    priceLabelEn: '~$10–18 avg',
    locationLabel: 'Guangzhou · Huanshi Xi Rd',
    datesLabel: 'Open daily · 09:00–23:00',
    media: img('https://images.unsplash.com/photo-1596797038530-2c107229654b?w=900&q=80'),
    attributes: {
      demoSeed: true,
      internetResearch: true,
      cuisine: 'yemeni',
      cuisineLabel: 'Yemeni',
      rating: 4.8,
      reviewCount: 210,
      deliveryMins: '25–40 min',
      minOrder: 10,
      deliveryFee: 2,
      city: 'Guangzhou',
      tags: ['Halal', 'Yemeni', 'Mandi'],
    },
  },
  {
    titleAr: 'Sultan Restaurant — تركي · غوانغتشو',
    titleEn: 'Sultan Restaurant — Guangzhou',
    bodyAr: 'مطعم تركي معروف في غوانغتشو (أدلة الطعام الحلال). كباب ومأكولات متوسطية.',
    bodyEn: 'Established Turkish spot in Guangzhou (halal food guides). Kebabs & Mediterranean.',
    priceLabelAr: 'متوسط 12–20$',
    priceLabelEn: '~$12–20 avg',
    locationLabel: 'Guangzhou · Tianhe',
    datesLabel: 'Open daily',
    media: img('https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=900&q=80'),
    attributes: {
      demoSeed: true,
      internetResearch: true,
      cuisine: 'turkish',
      cuisineLabel: 'Turkish',
      rating: 4.5,
      reviewCount: 640,
      deliveryMins: '30–40 min',
      minOrder: 10,
      deliveryFee: 2.5,
      city: 'Guangzhou',
      tags: ['Halal', 'Kebab'],
    },
  },
  {
    titleAr: 'MADO — تركي حلويات · تيانخه',
    titleEn: 'MADO Restaurant — Tianhe',
    bodyAr: 'مطعم تركي عائلي في تيانخه. كنافة، بيدة، إفطار تركي.',
    bodyEn: 'Family Turkish restaurant in Tianhe. Kunefe, pide, Turkish breakfast.',
    priceLabelAr: 'متوسط 8–16$',
    priceLabelEn: '~$8–16 avg',
    locationLabel: 'Guangzhou · Tianhe',
    datesLabel: 'Open daily',
    media: img('https://images.unsplash.com/photo-1488477181946-6428a0291777?w=900&q=80'),
    attributes: {
      demoSeed: true,
      internetResearch: true,
      cuisine: 'sweets',
      cuisineLabel: 'Turkish / Sweets',
      rating: 4.6,
      reviewCount: 520,
      deliveryMins: '25–35 min',
      minOrder: 8,
      deliveryFee: 2,
      city: 'Guangzhou',
      tags: ['Kunefe', 'Breakfast'],
    },
  },
  {
    titleAr: 'Xinyue Muslim — أويغوري · غوانغتشو',
    titleEn: 'Xinyue Muslim Restaurant — Guangzhou',
    bodyAr: 'مطعم مسلم مشهور (كایسا سكوير). أسياخ لحم، نودلز يدوية، مطبخ شينجيانغ.',
    bodyEn: 'Well-known Muslim restaurant (Kaisa Square area). Lamb skewers, hand-pulled noodles, Xinjiang style.',
    priceLabelAr: 'متوسط 9–15$',
    priceLabelEn: '~$9–15 avg',
    locationLabel: 'Guangzhou · Yuexiu',
    datesLabel: 'Open daily',
    media: img('https://images.unsplash.com/photo-1563379091339-03246963d29c?w=900&q=80'),
    attributes: {
      demoSeed: true,
      internetResearch: true,
      cuisine: 'chinese',
      cuisineLabel: 'Chinese Muslim',
      rating: 4.5,
      reviewCount: 1100,
      deliveryMins: '20–30 min',
      minOrder: 7,
      deliveryFee: 1.5,
      city: 'Guangzhou',
      tags: ['Halal', 'Xinjiang', 'Noodles'],
    },
  },
  {
    titleAr: 'Sultan Restaurant — إيوو · Chouzhou',
    titleEn: 'Sultan Restaurant — Yiwu Futian',
    bodyAr:
      'أشهر مطاعم إيوو الحلال (稠州北路 475). تركي/متوسطي بجانب سوق فوتیان. مرجع Meituan.',
    bodyEn:
      'Top-rated Yiwu halal restaurant (475 Chouzhou N Rd). Turkish/Mediterranean by Futian Market. Meituan research.',
    priceLabelAr: 'متوسط 12–22$',
    priceLabelEn: '~$12–22 avg',
    locationLabel: 'Yiwu · Chouzhou North Rd',
    datesLabel: 'Open daily · ~10:00–23:00',
    media: img('https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900&q=80'),
    attributes: {
      demoSeed: true,
      internetResearch: true,
      cuisine: 'turkish',
      cuisineLabel: 'Turkish',
      rating: 4.4,
      reviewCount: 193,
      deliveryMins: '20–30 min',
      minOrder: 10,
      deliveryFee: 2,
      city: 'Yiwu',
      tags: ['Halal', 'Futian', 'Popular'],
    },
  },
  {
    titleAr: 'Beyti1918 — إيوو',
    titleEn: 'Beyti1918 — Yiwu',
    bodyAr: 'مطعم تركي/عربي على 稠州北路. أسياخ لحم وزبادي منزلي — مفضل للتجار.',
    bodyEn: 'Turkish/Arabic on Chouzhou North Rd. Lamb skewers & yogurt — popular with traders.',
    priceLabelAr: 'متوسط 10–18$',
    priceLabelEn: '~$10–18 avg',
    locationLabel: 'Yiwu · Chouzhou North Rd',
    datesLabel: 'Open daily · ~10:00–23:00',
    media: img('https://images.unsplash.com/photo-1529042410799-b584dafa900b?w=900&q=80'),
    attributes: {
      demoSeed: true,
      internetResearch: true,
      cuisine: 'turkish',
      cuisineLabel: 'Turkish',
      rating: 4.3,
      reviewCount: 150,
      deliveryMins: '20–30 min',
      minOrder: 8,
      deliveryFee: 2,
      city: 'Yiwu',
      tags: ['Halal', 'Skewers'],
    },
  },
  {
    titleAr: 'Yusuf Muslim Halal — إيوو',
    titleEn: 'Yusuf Muslim Halal — Yiwu',
    bodyAr: 'خليط صيني مسلم + عربي قرب سوق فوتیان. خروف مشوي وحساء لحم.',
    bodyEn: 'Chinese Muslim + Arabian mix near Futian Market. Roast lamb & lamb soup.',
    priceLabelAr: 'متوسط 11–20$',
    priceLabelEn: '~$11–20 avg',
    locationLabel: 'Yiwu · Near Futian Market',
    datesLabel: 'Open daily',
    media: img('https://images.unsplash.com/photo-1596797038530-2c107229654b?w=900&q=80'),
    attributes: {
      demoSeed: true,
      internetResearch: true,
      cuisine: 'arabic',
      cuisineLabel: 'Arabic / Hui',
      rating: 4.4,
      reviewCount: 180,
      deliveryMins: '25–35 min',
      minOrder: 9,
      deliveryFee: 2,
      city: 'Yiwu',
      tags: ['Halal', 'Lamb'],
    },
  },
  {
    titleAr: 'Ali Baba Turkish — إيوو',
    titleEn: 'Ali Baba Turkish Restaurant — Yiwu',
    bodyAr: 'مطعم تركي مذكور في أدلة إيوو للتجار. كباب ومأكولات متوسطية.',
    bodyEn: 'Turkish restaurant listed in Yiwu buyer guides. Kebabs & Mediterranean.',
    priceLabelAr: 'متوسط 10–18$',
    priceLabelEn: '~$10–18 avg',
    locationLabel: 'Yiwu · Market district',
    datesLabel: 'Open daily',
    media: img('https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=900&q=80'),
    attributes: {
      demoSeed: true,
      internetResearch: true,
      cuisine: 'turkish',
      cuisineLabel: 'Turkish',
      rating: 4.2,
      reviewCount: 95,
      deliveryMins: '25–35 min',
      minOrder: 8,
      deliveryFee: 2,
      city: 'Yiwu',
      tags: ['Halal', 'Turkish'],
    },
  },
  {
    titleAr: 'Madina Muslim — إيوو',
    titleEn: 'Madina Muslim Restaurant — Yiwu',
    bodyAr: 'مطعم مسلم معروف قرب السوق. مناسب للغداء بعد التوريد.',
    bodyEn: 'Known Muslim restaurant near the market. Good lunch after sourcing.',
    priceLabelAr: 'متوسط 8–14$',
    priceLabelEn: '~$8–14 avg',
    locationLabel: 'Yiwu · Near International Trade City',
    datesLabel: 'Open daily',
    media: img('https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900&q=80'),
    attributes: {
      demoSeed: true,
      internetResearch: true,
      cuisine: 'arabic',
      cuisineLabel: 'Halal',
      rating: 4.3,
      reviewCount: 120,
      deliveryMins: '20–30 min',
      minOrder: 7,
      deliveryFee: 1.5,
      city: 'Yiwu',
      tags: ['Halal', 'Traders'],
    },
  },
];

const FLIGHTS = [
  {
    titleAr: 'CAN → RUH — China Southern — اقتصادية',
    titleEn: 'CAN → RUH — China Southern — Economy',
    bodyAr: 'رحلة مباشرة غوانغتشو–الرياض. 23 كغ أمتعة. تأشيرة واستقبال عبر OBIC.',
    bodyEn: 'Direct Guangzhou–Riyadh. 23 kg baggage. Visa & meet via OBIC.',
    priceLabelAr: 'من 420$',
    priceLabelEn: 'From $420',
    locationLabel: 'CAN → RUH',
    datesLabel: 'Weekly departures',
    media: img('https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=900&q=80'),
    attributes: {
      demoSeed: true,
      airline: 'China Southern',
      airlineCode: 'CZ',
      cabin: 'Economy',
      stops: 0,
      duration: '9h 30m',
      baggage: '23 kg',
      origin: 'CAN',
      destination: 'RUH',
    },
  },
  {
    titleAr: 'CAN → DXB — Emirates — رجال أعمال',
    titleEn: 'CAN → DXB — Emirates — Business',
    bodyAr: 'مقعد رجال أعمال، صالة مطار، وجبة فاخرة. توقف قصير أو مباشر حسب التاريخ.',
    bodyEn: 'Business seat, lounge, premium meal. Short or direct per date.',
    priceLabelAr: 'من 890$',
    priceLabelEn: 'From $890',
    locationLabel: 'CAN → DXB',
    datesLabel: 'Tue / Thu / Sat',
    media: img('https://images.unsplash.com/photo-1464037866557-681279c698d3?w=900&q=80'),
    attributes: {
      demoSeed: true,
      airline: 'Emirates',
      airlineCode: 'EK',
      cabin: 'Business',
      stops: 0,
      duration: '8h 15m',
      baggage: '40 kg',
      origin: 'CAN',
      destination: 'DXB',
    },
  },
  {
    titleAr: 'SZX → CAI — EgyptAir — اقتصادية',
    titleEn: 'SZX → CAI — EgyptAir — Economy',
    bodyAr: 'شنzhen–القاهرة. مناسبة للمسافرين عبر مصر إلى اليمن.',
    bodyEn: 'Shenzhen–Cairo. Good for travelers via Egypt to Yemen.',
    priceLabelAr: 'من 380$',
    priceLabelEn: 'From $380',
    locationLabel: 'SZX → CAI',
    datesLabel: 'Mon / Wed / Fri',
    media: img('https://images.unsplash.com/photo-1474302770737-173ee21ebb63?w=900&q=80'),
    attributes: {
      demoSeed: true,
      airline: 'EgyptAir',
      airlineCode: 'MS',
      cabin: 'Economy',
      stops: 0,
      duration: '11h 05m',
      baggage: '23 kg',
      origin: 'SZX',
      destination: 'CAI',
    },
  },
  {
    titleAr: 'PEK → JED — Saudia — اقتصادية',
    titleEn: 'PEK → JED — Saudia — Economy',
    bodyAr: 'بكين–جدة. خيار موسم الحج والعمرة مع دعم OBIC للمجموعات.',
    bodyEn: 'Beijing–Jeddah. Hajj/Umrah season option with OBIC group support.',
    priceLabelAr: 'من 510$',
    priceLabelEn: 'From $510',
    locationLabel: 'PEK → JED',
    datesLabel: 'Seasonal',
    media: img('https://images.unsplash.com/photo-1583608205776-bfd35f0d9dd2?w=900&q=80'),
    attributes: {
      demoSeed: true,
      airline: 'Saudia',
      airlineCode: 'SV',
      cabin: 'Economy',
      stops: 0,
      duration: '10h 40m',
      baggage: '23 kg',
      origin: 'PEK',
      destination: 'JED',
    },
  },
  {
    titleAr: 'HGH → RUH — طيران مباشر',
    titleEn: 'HGH → RUH — Direct service',
    bodyAr: 'Hangzhou–الرياض مباشرة. مثالي بعد زيارات الموردين في Zhejiang.',
    bodyEn: 'Direct Hangzhou–Riyadh. Ideal after supplier visits in Zhejiang.',
    priceLabelAr: 'من 445$',
    priceLabelEn: 'From $445',
    locationLabel: 'HGH → RUH',
    datesLabel: 'Sat departures',
    media: img('https://images.unsplash.com/photo-1540962351504-0307e7533bb2?w=900&q=80'),
    attributes: {
      demoSeed: true,
      airline: 'Air China',
      airlineCode: 'CA',
      cabin: 'Economy',
      stops: 0,
      duration: '10h 10m',
      baggage: '23 kg',
      origin: 'HGH',
      destination: 'RUH',
    },
  },
  {
    titleAr: 'CAN → IST — Turkish Airlines',
    titleEn: 'CAN → IST — Turkish Airlines',
    bodyAr: 'غوانغتشو–إسطنbul. توقف واحد أو مباشر. ترانزit مريح للأوروبا والشرق الأوسط.',
    bodyEn: 'Guangzhou–Istanbul. One-stop or direct. Comfortable transit to EU & MENA.',
    priceLabelAr: 'من 395$',
    priceLabelEn: 'From $395',
    locationLabel: 'CAN → IST',
    datesLabel: 'Daily',
    media: img('https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=900&q=80'),
    attributes: {
      demoSeed: true,
      airline: 'Turkish Airlines',
      airlineCode: 'TK',
      cabin: 'Economy',
      stops: 1,
      duration: '12h 20m',
      baggage: '30 kg',
      origin: 'CAN',
      destination: 'IST',
    },
  },
];

const MOMENTS = [
  {
    body: 'مرحباً من فرع غوانغتشو OBIC — زيارة مصنع اليوم مع عملائنا 🇨🇳✈️\nOBIC Guangzhou branch — factory visit with clients today.',
    media: [
      'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=800&q=80',
      'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&q=80',
      'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=800&q=80',
    ],
  },
  {
    body: 'عرض فندق جديد في غوانغتشو — 5 نجوم مع إفطار 🏨\nNew 5★ Guangzhou hotel deal with breakfast — ask OBIC desk.',
    media: [
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
      'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&q=80',
    ],
  },
  {
    body: 'Yiwu market day — helping a Yemeni buyer find suppliers 📦\nيوم سوق ييوu — نساعد تاجر يمني في اختيار الموردين.',
    media: [
      'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&q=80',
      'https://images.unsplash.com/photo-1556761175-b413da4baf72?w=800&q=80',
    ],
  },
  {
    body: '✈️ CAN → RUH seats open this month — contact OBIC for group fares.\nمقاعد CAN → RUH متاحة هذا الشهر — تواصل مع OBIC للمجموعات.',
    media: ['https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800&q=80'],
  },
  {
    body: 'Team OBIC at Canton Fair — visit our desk in Hall 12 🎪\nفريق OBIC في معرض Canton Fair — زورونا.',
    media: [
      'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&q=80',
      'https://images.unsplash.com/photo-1511578314322-379afb476865?w=800&q=80',
      'https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=800&q=80',
      'https://images.unsplash.com/photo-1551836022-deb4986cc295?w=800&q=80',
    ],
  },
  {
    body: 'OBIC Super Admin — platform update: hotels, flights & Moments live for demo 🚀\nتحديث المنصة: الفنادق والطيران واللحظات جاهزة للعرض.',
    media: [
      'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800&q=80',
      'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&q=80',
    ],
  },
];

async function ensureOffersAccess(adminToken, email) {
  const staff = asItems(await json('GET', '/v1/admin/staff', null, adminToken));
  const row = staff.find((s) => s.email === email);
  if (!row) throw new Error(`Staff not found: ${email}`);
  if (row.offersAccess === true) return row.id;
  await json(
    'PATCH',
    `/v1/admin/staff/${row.id}`,
    { offersAccess: true },
    adminToken,
  );
  console.log('  enabled offersAccess for', email);
  return row.id;
}

function asItems(data) {
  if (Array.isArray(data)) return data;
  if (data && Array.isArray(data.items)) return data.items;
  return [];
}

async function countDemoOffers(token, kind) {
  const rows = asItems(await json('GET', '/v1/admin/offers', null, token));
  return rows.filter(
    (o) => o.attributes?.demoSeed === true && (!kind || o.kind === kind),
  ).length;
}

async function createOffers(token, kind, rows) {
  let n = 0;
  for (const row of rows) {
    await json(
      'POST',
      '/v1/admin/offers',
      {
        kind,
        ...row,
        isPublished: true,
        isSoldOut: false,
        expiresAt: null,
      },
      token,
    );
    n += 1;
    console.log(`  + ${kind}: ${row.titleEn}`);
  }
  return n;
}

async function createMoments(token, rows) {
  let n = 0;
  for (const row of rows) {
    await json(
      'POST',
      '/v1/moments',
      {
        body: row.body,
        media: row.media.map((url) => ({
          kind: 'image',
          url,
          name: 'photo.jpg',
          mime: 'image/jpeg',
        })),
      },
      token,
    );
    n += 1;
    console.log(`  + moment (${row.media.length} photos)`);
  }
  return n;
}

async function main() {
  console.log('API', API);
  await json('GET', '/v1/health');

  const adminToken = await login('admin@obic.local', 'AdminObic2026!');
  const demoHotels = await countDemoOffers(adminToken, 'hotels');
  const demoFlights = await countDemoOffers(adminToken, 'flights');
  const demoRestaurants = await countDemoOffers(adminToken, 'restaurants');
  const offersComplete =
    demoHotels >= 5 && demoFlights >= 5 && demoRestaurants >= 5;
  if (offersComplete && !FORCE) {
    console.log(
      `Demo offers already seeded (hotels ${demoHotels}, flights ${demoFlights}, restaurants ${demoRestaurants}). Set FORCE_DEMO_SEED=1 to add more.`,
    );
  } else {
    await ensureOffersAccess(adminToken, 'temp.guangzhou.marketing@obic.local');
    await ensureOffersAccess(adminToken, 'temp.yiwu.marketing@obic.local');

    const gzToken = await login(
      'temp.guangzhou.marketing@obic.local',
      'TempObic2026!Guangzhou-Mkt',
    );
    const ywToken = await login(
      'temp.yiwu.marketing@obic.local',
      'TempObic2026!Yiwu-Mkt',
    );

    console.log('Creating hotel offers (Guangzhou Marketing Manager)…');
    let h = 0;
    if (demoHotels < 5 || FORCE) {
      h = await createOffers(gzToken, 'hotels', HOTELS);
    } else {
      console.log(`  skip hotels (${demoHotels} already)`);
    }
    console.log('Creating flight offers (Yiwu Marketing Manager)…');
    let f = 0;
    if (demoFlights < 5 || FORCE) {
      f = await createOffers(ywToken, 'flights', FLIGHTS);
    } else {
      console.log(`  skip flights (${demoFlights} already)`);
    }
    console.log('Creating restaurant vendors (Guangzhou Marketing Manager)…');
    let r = 0;
    if (demoRestaurants < 5 || FORCE) {
      r = await createOffers(gzToken, 'restaurants', RESTAURANTS);
    } else {
      console.log(`  skip restaurants (${demoRestaurants} already)`);
    }
    console.log(`Offers done: ${h} hotels, ${f} flights, ${r} restaurants`);
  }

  const moments = asItems(await json('GET', '/v1/moments'));
  const hasDemo = moments.some((m) => (m.body || '').includes('OBIC Guangzhou branch'));
  if (hasDemo && !FORCE) {
    console.log('Demo moments already present — skip');
  } else {
    console.log('Creating Moments with photos…');
    const gzToken =
      (await login(
        'temp.guangzhou.marketing@obic.local',
        'TempObic2026!Guangzhou-Mkt',
      )) || adminToken;
    await createMoments(gzToken, MOMENTS.slice(0, 4));
    await createMoments(adminToken, MOMENTS.slice(4));
    console.log('Moments done');
  }

  const hotels = asItems(await json('GET', '/v1/offers?kind=hotels'));
  const flights = asItems(await json('GET', '/v1/offers?kind=flights'));
  const restaurants = asItems(await json('GET', '/v1/offers?kind=restaurants'));
  const feed = asItems(await json('GET', '/v1/moments'));
  console.log('Public counts:', {
    hotels: hotels.length,
    flights: flights.length,
    restaurants: restaurants.length,
    moments: feed.length,
  });
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
