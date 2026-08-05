const ICONS = {
  hotel: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 21h18M5 21V8l7-4 7 4v13M9 21v-6h6v6M9 10h.01M15 10h.01"/></svg>`,
  flight: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M2 12l19-8-4 16-5-5-4 2z"/></svg>`,
  visa: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 10h18M7 15h4"/></svg>`,
  bank: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 10l9-6 9 6M5 10v8M9 10v8M15 10v8M19 10v8M3 18h18"/></svg>`,
  vip: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 3l2.5 6.5L21 10l-5 4.2L17.5 21 12 17.5 6.5 21 8 14.2 3 10l6.5-.5z"/></svg>`,
  legal: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 3v18M5 8l7-4 7 4M6 21h12M8 12l-3 5h6l-3-5zm8 0l-3 5h6l-3-5z"/></svg>`,
  company: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 21V5a1 1 0 011-1h8a1 1 0 011 1v16M14 10h5a1 1 0 011 1v10M8 8h2M8 12h2M8 16h2"/></svg>`,
  scholarship: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M22 10L12 5 2 10l10 5 10-5zM6 12v5c0 1 3 3 6 3s6-2 6-3v-5"/></svg>`,
  transfer: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M7 10H21l-4-4M17 14H3l4 4"/></svg>`,
  ads: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 11l18-7v16L3 13v-2zM11.5 16.5V21"/></svg>`,
  biz: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="7" width="18" height="13" rx="2"/><path d="M8 7V5a2 2 0 012-2h4a2 2 0 012 2v2"/></svg>`,
  hr: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M16 21v-2a4 4 0 00-4-4H6a4 4 0 00-4 4v2M9 11a4 4 0 100-8 4 4 0 000 8zM22 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"/></svg>`,
  insurance: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 3l8 4v5c0 5-3.5 8.5-8 10-4.5-1.5-8-5-8-10V7l8-4z"/></svg>`,
  expand: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 010 18M12 3a14 14 0 000 18"/></svg>`,
  tech: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 18v-2a4 4 0 014-4h2M15 18v-1a3 3 0 013-3h0a3 3 0 013 3v1M9 12a3 3 0 100-6 3 3 0 000 6zM18 11a2.5 2.5 0 100-5 2.5 2.5 0 000 5z"/></svg>`,
  plan: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2M9 12h6M9 16h4"/></svg>`,
  search: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>`,
  home: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 11l9-7 9 7v9a1 1 0 01-1 1h-5v-6H9v6H4a1 1 0 01-1-1v-9z"/></svg>`,
  grid: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>`,
  msg: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M21 12a8 8 0 01-8 8H6l-4 3V12a8 8 0 018-8h3a8 8 0 018 8z"/></svg>`,
  orders: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M7 7h12l-1 11H8L7 7zM7 7l-1-3H3M10 11v4M14 11v4"/></svg>`,
  me: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0116 0"/></svg>`,
  check: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M5 13l4 4L19 7"/></svg>`,
  doc: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M8 3h7l4 4v13a1 1 0 01-1 1H8a1 1 0 01-1-1V4a1 1 0 011-1z"/><path d="M15 3v5h5M9 13h6M9 17h4"/></svg>`,
  bell: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M6 9a6 6 0 1112 0c0 7 2 7 2 9H4c0-2 2-2 2-9zM10 21h4"/></svg>`,
  pin: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 21s7-5.5 7-12a7 7 0 10-14 0c0 6.5 7 12 7 12z"/><circle cx="12" cy="9" r="2.5"/></svg>`,
  web: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 010 18M12 3a14 14 0 000 18"/></svg>`,
  mail: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 7 9-7"/></svg>`,
  phone: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M22 16.9v3a2 2 0 01-2.2 2 19.8 19.8 0 01-8.6-3.1 19.5 19.5 0 01-6-6A19.8 19.8 0 012.1 4.2 2 2 0 014.1 2h3a2 2 0 012 1.7c.1.9.4 1.8.7 2.6a2 2 0 01-.5 2.1L8.1 9.9a16 16 0 006 6l1.5-1.2a2 2 0 012.1-.5c.8.3 1.7.6 2.6.7A2 2 0 0122 16.9z"/></svg>`,
  video: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="2" y="6" width="13" height="12" rx="2"/><path d="M15 10l7-3v10l-7-3v-4z"/></svg>`,
  mic: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0014 0M12 18v3"/></svg>`,
  micOff: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M9 9v2a3 3 0 005.1 2.1M15 9V7a3 3 0 00-5.2-2M5 11a7 7 0 0011.3 5.5M12 18v3M2 2l20 20"/></svg>`,
  speaker: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M11 5L6 9H3v6h3l5 4V5zM16 9a4 4 0 010 6M18.5 7a7 7 0 010 10"/></svg>`,
  camFlip: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M16 4h4v4M20 4l-5 5M8 20H4v-4M4 20l5-5"/><rect x="7" y="7" width="10" height="10" rx="2"/></svg>`,
  image: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="9" cy="10" r="1.5"/><path d="M21 16l-5-5-8 8"/></svg>`,
  attach: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M21.4 11.6l-8.5 8.5a5 5 0 01-7.1-7.1l9.2-9.2a3.2 3.2 0 014.5 4.5L10.4 19.4a1.4 1.4 0 01-2-2l8.1-8.1"/></svg>`,
  hangup: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M10 9a7 7 0 000 6M14 9a7 7 0 010 6M3 10c4-3 14-3 18 0v2c-4-2-14-2-18 0v-2z"/></svg>`,
};

const COLORS = {
  hotels: { bg: "linear-gradient(145deg,#FB7185,#E11D48)", soft: "#FFE4E6", ink: "#E11D48" },
  flights: { bg: "linear-gradient(145deg,#60A5FA,#1A6DFF)", soft: "#DBEAFE", ink: "#1A6DFF" },
  visa: { bg: "linear-gradient(145deg,#2DD4BF,#0D9488)", soft: "#CCFBF1", ink: "#0D9488" },
  bank: { bg: "linear-gradient(145deg,#4ADE80,#16A34A)", soft: "#DCFCE7", ink: "#16A34A" },
  vip: { bg: "linear-gradient(145deg,#FB923C,#EA580C)", soft: "#FFEDD5", ink: "#EA580C" },
  default: { bg: "linear-gradient(145deg,#93C5FD,#1A6DFF)", soft: "#E8F1FF", ink: "#1A6DFF" },
};

const SERVICES = [
  { id: "hotels", name: "Hotels", icon: "hotel", color: "hotels", desc: "Book hotels across China for business trips.", price: "From $45/night" },
  { id: "flights", name: "Flights", icon: "flight", color: "flights", desc: "Flight booking assistance for China routes.", price: "Assist from $20" },
  { id: "visa", name: "Visa", icon: "visa", color: "visa", desc: "China business / tourist visa support.", price: "From $120" },
  { id: "bank", name: "Bank Account", icon: "bank", color: "bank", desc: "Open a local bank account with guidance.", price: "From $299" },
  { id: "vip", name: "VIP Service", icon: "vip", color: "vip", desc: "Full VIP itinerary, pickup, factory visits.", price: "Custom quote" },
  { id: "legal", name: "Legal Services", icon: "legal", desc: "Contracts, compliance, and legal support.", price: "From $199" },
  { id: "company", name: "Company Registration", icon: "company", desc: "Register your company in China.", price: "From $499" },
  { id: "scholarship", name: "Scholarships", icon: "scholarship", desc: "Scholarship application support.", price: "Consult free" },
  { id: "transfer", name: "Money Transfer", icon: "transfer", desc: "Request assistance for transfers (info V1).", price: "Request only" },
  { id: "ads", name: "Advertisements", icon: "ads", desc: "Brand & ads support in China.", price: "From $150" },
  { id: "biz", name: "Business Services", icon: "biz", desc: "Sourcing, meetings, and ops support.", price: "From $99" },
  { id: "hr", name: "Human Resources", icon: "hr", desc: "Hiring and HR coordination.", price: "From $180" },
  { id: "insurance", name: "Insurance", icon: "insurance", desc: "Insurance & protection plans.", price: "From $50" },
  { id: "expand", name: "International Expansion", icon: "expand", desc: "Go-to-market and expansion advisory.", price: "Custom" },
  { id: "tech", name: "Technical Support", icon: "tech", desc: "Tech & ops support packages.", price: "From $80" },
  { id: "plan", name: "Business Planning", icon: "plan", desc: "Business planning workshops.", price: "From $220" },
];

const SCREENS = [
  { id: "home", label: "01 Home" },
  { id: "services", label: "02 Services" },
  { id: "detail", label: "03 Service Detail" },
  { id: "request", label: "04 Request Order" },
  { id: "orders", label: "05 Orders" },
  { id: "orderDetail", label: "06 Order Timeline" },
  { id: "messages", label: "07 Messages" },
  { id: "chat", label: "08 Chat + Files" },
  { id: "voiceCall", label: "09 Voice Call" },
  { id: "videoCall", label: "10 Video Call" },
  { id: "incomingCall", label: "11 Incoming Call" },
  { id: "me", label: "12 Me / Profile" },
  { id: "login", label: "13 Login" },
  { id: "register", label: "14 Register" },
  { id: "search", label: "15 Search" },
  { id: "about", label: "16 About OBIC" },
];

let state = {
  screen: "home",
  serviceId: "visa",
  toast: null,
  muted: false,
  speakerOn: true,
  callSec: 126,
  chatExtras: [],
};

const app = document.getElementById("app");
const nav = document.getElementById("screenNav");

function go(screen, extra = {}) {
  state = { ...state, screen, ...extra, toast: null };
  render();
}

function toast(msg) {
  state.toast = msg;
  render();
  setTimeout(() => { state.toast = null; render(); }, 1600);
}

function fmtTime(sec) {
  const m = String(Math.floor(sec / 60)).padStart(2, "0");
  const s = String(sec % 60).padStart(2, "0");
  return `${m}:${s}`;
}

function attachImage() {
  state.chatExtras = [...state.chatExtras, { type: "image", side: "me", label: "passport-scan.jpg" }];
  toast("Image attached (prototype)");
  render();
}

function attachFile() {
  state.chatExtras = [...state.chatExtras, { type: "file", side: "me", name: "Invitation_Letter.pdf", size: "240 KB" }];
  toast("File attached (prototype)");
  render();
}

function sendChatText() {
  const el = document.getElementById("chatIn");
  const text = (el && el.value || "").trim();
  if (!text) { toast("Type a message first"); return; }
  state.chatExtras = [...state.chatExtras, { type: "text", side: "me", text }];
  toast("Sent");
  render();
}

function toggleMute() {
  state.muted = !state.muted;
  toast(state.muted ? "Muted" : "Unmuted");
  render();
}

function toggleSpeaker() {
  state.speakerOn = !state.speakerOn;
  toast(state.speakerOn ? "Speaker on" : "Earpiece");
  render();
}

function ico(name) { return ICONS[name] || ICONS.biz; }
function svcById(id) { return SERVICES.find(s => s.id === id) || SERVICES[2]; }
function colorOf(s) { return COLORS[s.color] || COLORS.default; }

function thumb(s, size = 50) {
  const c = colorOf(s);
  return `<div class="thumb" style="width:${size}px;height:${size}px;background:${c.bg};color:#fff">${ico(s.icon)}</div>`;
}

function softThumb(s) {
  const c = colorOf(s);
  return `<div class="thumb" style="background:${c.soft};color:${c.ink}">${ico(s.icon)}</div>`;
}

function tabBar(active) {
  const tabs = [
    ["home", "home", "Home"],
    ["services", "grid", "Services"],
    ["messages", "msg", "Messages"],
    ["orders", "orders", "Orders"],
    ["me", "me", "Me"],
  ];
  return `<nav class="tabbar">${tabs.map(([id, icon, lab]) =>
    `<button class="tab ${active === id ? "active" : ""}" onclick="go('${id}')"><span class="ti">${ico(icon)}</span>${lab}</button>`
  ).join("")}</nav>`;
}

function renderHome() {
  const primary = SERVICES.slice(0, 5);
  const secondary = SERVICES.slice(5, 13);
  const ranked = [SERVICES[2], SERVICES[4], SERVICES[3], SERVICES[0]];
  return `
  <div class="app-body">
    <div class="topbar">
      <div class="topbar-row">
        <div class="brand-lockup">
          <div class="brand-mark">O</div>
          <div>
            <div class="brand">OBIC</div>
            <div class="brand-tag">China · Business · Travel</div>
          </div>
        </div>
        <div class="chip">EN ▾</div>
      </div>
      <div class="search" onclick="go('search')">
        <span class="si">${ico("search")}</span>
        Search visas, hotels, VIP trips…
      </div>
    </div>

    <div class="section">
      <div class="primary-tiles">
        ${primary.map(s => `
          <button class="ptile ${s.color}" onclick="go('detail',{serviceId:'${s.id}'})">
            <span class="ico">${ico(s.icon)}</span>
            <span class="lbl">${s.name}</span>
          </button>`).join("")}
      </div>
    </div>

    <div class="section">
      <div class="sec-tiles">
        ${secondary.map(s => `
          <button class="stile" onclick="go('detail',{serviceId:'${s.id}'})">
            <span class="ico">${ico(s.icon)}</span>
            <span class="lbl">${s.name}</span>
          </button>`).join("")}
      </div>
    </div>

    <div class="section">
      <div class="banner-wrap">
        <div class="banner-track">
          <div class="banner b1" onclick="go('detail',{serviceId:'vip'})">
            <div class="eyebrow">Featured</div>
            <h3>VIP China Trip</h3>
            <p>Airport pickup · Hotels · Factory visits · One dedicated manager</p>
            <span class="cta-pill">Book package →</span>
          </div>
          <div class="banner b2" onclick="go('detail',{serviceId:'visa'})">
            <div class="eyebrow">Fast track</div>
            <h3>Visa Express</h3>
            <p>Business & tourist visa support with checklist and advisor</p>
            <span class="cta-pill">From $120 →</span>
          </div>
          <div class="banner b3" onclick="go('detail',{serviceId:'bank'})">
            <div class="eyebrow">Setup</div>
            <h3>Open Bank Account</h3>
            <p>Guided local account opening with branch coordination</p>
            <span class="cta-pill">Start request →</span>
          </div>
        </div>
        <div class="banner-dots"><i class="on"></i><i></i><i></i></div>
      </div>
      <div class="promo-row">
        <div class="promo" onclick="go('detail',{serviceId:'visa'})">
          <div class="ph"><span class="ph-label">Visa</span></div>
          <div class="txt">Visa express<div><small>From $120 · Advisor included</small></div></div>
        </div>
        <div class="promo" onclick="go('detail',{serviceId:'bank'})">
          <div class="ph alt"><span class="ph-label">Bank</span></div>
          <div class="txt">Bank open guide<div><small>Yiwu & Guangzhou</small></div></div>
        </div>
      </div>
    </div>

    <div class="section">
      <div class="section-title">Top services <span onclick="go('services')">See all</span></div>
      <div class="rank-card">
        ${ranked.map((s, i) => `
          <div class="rank-item" onclick="go('detail',{serviceId:'${s.id}'})">
            <div class="rank-n">${i + 1}</div>
            ${softThumb(s)}
            <div><h4>${s.name}</h4><p>${s.desc.slice(0, 36)}…</p></div>
            <div class="price">${s.price.replace("From ", "")}</div>
          </div>`).join("")}
      </div>
    </div>

    <div class="section" style="padding-bottom:18px">
      <div class="section-title">Recommended</div>
      ${SERVICES.slice(0, 3).map(s => `
        <div class="list-card" onclick="go('detail',{serviceId:'${s.id}'})">
          ${thumb(s)}
          <div><h4>${s.name}</h4><p>${s.desc.slice(0, 40)}…</p></div>
          <div class="price">${s.price}</div>
        </div>`).join("")}
    </div>
  </div>
  ${tabBar("home")}`;
}

function renderServices() {
  return `
  <div class="page-header"><h2>All Services</h2><div class="svc-count">16</div></div>
  <div class="app-body">
    <div class="section">
      <div class="sec-tiles" style="grid-template-columns:repeat(4,1fr)">
        ${SERVICES.map(s => `
          <button class="stile" onclick="go('detail',{serviceId:'${s.id}'})">
            <span class="ico" style="${s.color ? `background:${colorOf(s).soft};color:${colorOf(s).ink}` : ""}">${ico(s.icon)}</span>
            <span class="lbl">${s.name}</span>
          </button>`).join("")}
      </div>
    </div>
  </div>
  ${tabBar("services")}`;
}

function renderDetail() {
  const s = svcById(state.serviceId);
  const c = colorOf(s);
  return `
  <div class="page-header"><button class="back" onclick="go('home')">←</button><h2>Service</h2></div>
  <div class="app-body">
    <div class="hero-svc ${s.color || ""}">
      <div class="badge" style="background:rgba(255,255,255,.18);color:#fff">OBIC Official</div>
      <h3>${s.name}</h3>
      <p>${s.desc}</p>
    </div>
    <div class="section">
      <div class="section-title">What's included</div>
      <div class="list-card"><div class="thumb" style="background:${c.soft};color:${c.ink}">${ico("check")}</div><div><h4>Dedicated advisor</h4><p>Assigned after you submit</p></div></div>
      <div class="list-card"><div class="thumb" style="background:${c.soft};color:${c.ink}">${ico("doc")}</div><div><h4>Document checklist</h4><p>Clear steps in your order</p></div></div>
      <div class="list-card"><div class="thumb" style="background:${c.soft};color:${c.ink}">${ico("bell")}</div><div><h4>Status updates</h4><p>Track progress in Orders</p></div></div>
      <p style="font-size:15px;margin:14px 0 12px;font-weight:800;font-family:var(--font-display);color:var(--navy)">${s.price}</p>
      <div class="btn-row">
        <button class="btn btn-primary" onclick="go('request')">Request this service</button>
        <button class="btn btn-ghost" onclick="go('chat')">Chat with support</button>
      </div>
    </div>
  </div>`;
}

function renderRequest() {
  const s = svcById(state.serviceId);
  return `
  <div class="page-header"><button class="back" onclick="go('detail')">←</button><h2>Request</h2></div>
  <div class="app-body">
    <div class="form">
      <div><label>Service</label><input value="${s.name}" readonly /></div>
      <div><label>Preferred branch</label>
        <select><option>Yiwu-OBIC</option><option>Guangzhou-OBIC</option><option>Yemen-OBIC</option><option>Foshan-OBIC</option><option>Hangzhou-OBIC</option><option>Hainan-OBIC</option></select>
      </div>
      <div><label>Full name</label><input placeholder="Your name" /></div>
      <div><label>Phone (+country code)</label><input placeholder="+86 ..." /></div>
      <div><label>Email</label><input placeholder="you@email.com" /></div>
      <div><label>Notes</label><textarea rows="3" placeholder="Dates, goals, documents..."></textarea></div>
      <button class="btn btn-primary" onclick="toast('Order submitted (prototype)'); setTimeout(()=>go('orderDetail'),500)">Submit order</button>
    </div>
  </div>`;
}

function renderOrders() {
  return `
  <div class="page-header"><h2>Orders</h2></div>
  <div class="app-body">
    <div class="section">
      <div class="list-card" onclick="go('orderDetail')">
        ${thumb(SERVICES[2])}
        <div><h4>Visa · #OB-1042</h4><p><span class="badge warn">In progress</span></p></div>
        <div class="price">$120</div>
      </div>
      <div class="list-card" onclick="go('orderDetail')">
        ${thumb(SERVICES[3])}
        <div><h4>Bank Account · #OB-1031</h4><p><span class="badge">Submitted</span></p></div>
        <div class="price">$299</div>
      </div>
      <div class="list-card">
        ${thumb(SERVICES[0])}
        <div><h4>Hotels · #OB-1010</h4><p><span class="badge ok">Completed</span></p></div>
        <div class="price">$180</div>
      </div>
    </div>
  </div>
  ${tabBar("orders")}`;
}

function renderOrderDetail() {
  return `
  <div class="page-header"><button class="back" onclick="go('orders')">←</button><h2>Order #OB-1042</h2></div>
  <div class="app-body">
    <div class="section">
      <div class="list-card">${thumb(SERVICES[2])}<div><h4>China Visa Support</h4><p>Yiwu branch · $120</p></div><span class="badge warn">In progress</span></div>
    </div>
    <div class="section-title" style="padding:0 16px">Timeline</div>
    <div class="status-steps">
      <div class="step done"><div><h4>Submitted</h4><p>Today 09:12</p></div></div>
      <div class="step done"><div><h4>Advisor assigned</h4><p>Today 10:05 · Lily</p></div></div>
      <div class="step done"><div><h4>Documents checklist sent</h4><p>Waiting on passport scan</p></div></div>
      <div class="step"><div><h4>Under review</h4><p>Pending</p></div></div>
      <div class="step"><div><h4>Completed</h4><p>Pending</p></div></div>
    </div>
    <div class="section"><button class="btn btn-primary" onclick="go('chat')">Message advisor</button></div>
  </div>`;
}

function renderMessages() {
  return `
  <div class="page-header"><h2>Messages</h2></div>
  <div class="app-body">
    <div class="msg-item" onclick="go('chat')">
      <div class="avatar">O</div>
      <div><h4>Lily · Visa Advisor</h4><p>Photo · File · Voice &amp; video ready</p></div>
      <div class="time">10:05</div>
    </div>
    <div class="msg-item" onclick="go('chat')">
      <div class="avatar" style="background:linear-gradient(145deg,#94A3B8,#475569)">S</div>
      <div><h4>System</h4><p>Order #OB-1042 is in progress</p></div>
      <div class="time">09:12</div>
    </div>
  </div>
  ${tabBar("messages")}`;
}

function renderChatExtras() {
  return state.chatExtras.map(m => {
    if (m.type === "image") {
      return `<div class="chat-bubble me media">
        <div class="img-bubble"><div class="img-ph">${ico("image")}<span>${m.label}</span></div></div>
        <div class="msg-meta">Delivered · Just now</div>
      </div>`;
    }
    if (m.type === "file") {
      return `<div class="chat-bubble me file-chip">
        <div class="file-row"><span class="file-ico">${ico("doc")}</span><div><strong>${m.name}</strong><small>${m.size} · Sent</small></div></div>
      </div>`;
    }
    return `<div class="chat-bubble me">${m.text}<div class="msg-meta">Delivered</div></div>`;
  }).join("");
}

function renderChat() {
  return `
  <div class="page-header chat-header">
    <button class="back" onclick="go('messages')">←</button>
    <div class="chat-title">
      <h2>Lily · Visa</h2>
      <span class="online">Online · OBIC Support</span>
    </div>
    <div class="chat-actions">
      <button class="icon-btn" title="Voice call" onclick="go('voiceCall')">${ico("phone")}</button>
      <button class="icon-btn" title="Video call" onclick="go('videoCall')">${ico("video")}</button>
    </div>
  </div>
  <div class="app-body" style="display:flex;flex-direction:column">
    <div class="chat-box">
      <div class="day-sep">Today</div>
      <div class="chat-bubble them">Hello! I'm Lily from OBIC Visa team. How can I help?</div>
      <div class="chat-bubble me">I need a business visa for next month.</div>
      <div class="chat-bubble them">Great — please upload your passport scan. I also sent the checklist.</div>
      <div class="chat-bubble them media">
        <div class="file-row them-file"><span class="file-ico">${ico("doc")}</span><div><strong>Visa_Checklist.pdf</strong><small>128 KB · Tap to open</small></div></div>
      </div>
      <div class="chat-bubble them media">
        <div class="img-bubble them-img"><div class="img-ph alt">${ico("image")}<span>Sample photo guide</span></div></div>
      </div>
      ${renderChatExtras()}
    </div>
    <div class="composer">
      <div class="composer-tools">
        <button class="tool-btn" onclick="attachImage()">${ico("image")}<span>Photo</span></button>
        <button class="tool-btn" onclick="attachFile()">${ico("attach")}<span>File</span></button>
        <button class="tool-btn" onclick="go('incomingCall')">${ico("phone")}<span>Demo call</span></button>
      </div>
      <div class="chat-input">
        <input placeholder="Message Lily..." id="chatIn" />
        <button class="btn btn-primary" style="padding:10px 16px" onclick="sendChatText()">Send</button>
      </div>
    </div>
  </div>`;
}

function renderVoiceCall() {
  return `
  <div class="call-screen voice">
    <div class="call-top">
      <span class="call-brand">OBIC</span>
      <span class="call-type">Voice call</span>
    </div>
    <div class="call-center">
      <div class="call-avatar pulse">L</div>
      <h2>Lily Chen</h2>
      <p>OBIC Visa Advisor · Yiwu</p>
      <div class="call-timer">${fmtTime(state.callSec)}</div>
      <div class="wave"><i></i><i></i><i></i><i></i><i></i></div>
    </div>
    <div class="call-controls">
      <button class="call-btn ${state.muted ? "on" : ""}" onclick="toggleMute()"><span>${state.muted ? ico("micOff") : ico("mic")}</span>Mute</button>
      <button class="call-btn ${state.speakerOn ? "on" : ""}" onclick="toggleSpeaker()"><span>${ico("speaker")}</span>Speaker</button>
      <button class="call-btn end" onclick="toast('Call ended'); go('chat')"><span>${ico("hangup")}</span>End</button>
    </div>
  </div>`;
}

function renderVideoCall() {
  return `
  <div class="call-screen video">
    <div class="remote-video">
      <div class="remote-label">Lily Chen · OBIC</div>
      <div class="remote-avatar">L</div>
      <div class="video-timer">${fmtTime(state.callSec + 42)}</div>
    </div>
    <div class="local-video">
      <div class="local-ph">You</div>
    </div>
    <div class="video-controls">
      <button class="vbtn ${state.muted ? "on" : ""}" onclick="toggleMute()">${state.muted ? ico("micOff") : ico("mic")}</button>
      <button class="vbtn" onclick="toast('Camera flipped (prototype)')">${ico("camFlip")}</button>
      <button class="vbtn end" onclick="toast('Call ended'); go('chat')">${ico("hangup")}</button>
      <button class="vbtn" onclick="toast('Speaker toggled')">${ico("speaker")}</button>
    </div>
  </div>`;
}

function renderIncomingCall() {
  return `
  <div class="call-screen incoming">
    <div class="incoming-bg"></div>
    <div class="call-center" style="z-index:1">
      <div class="call-brand" style="margin-bottom:18px">OBIC</div>
      <div class="call-avatar">L</div>
      <h2>Lily Chen</h2>
      <p class="ring-label"><span class="ring-dot"></span> Incoming video call…</p>
    </div>
    <div class="incoming-actions">
      <button class="in-btn decline" onclick="toast('Declined'); go('chat')"><span>${ico("hangup")}</span>Decline</button>
      <button class="in-btn accept" onclick="go('videoCall')"><span>${ico("video")}</span>Accept</button>
    </div>
    <button class="voice-alt" onclick="go('voiceCall')">Answer with voice only</button>
  </div>`;
}

function renderMe() {
  return `
  <div class="app-body">
    <div class="me-header">
      <div class="row">
        <div class="av">G</div>
        <div>
          <h3 style="font-size:20px;font-family:var(--font-display);font-weight:800;letter-spacing:-.3px">Guest</h3>
          <p style="font-size:12px;opacity:.88;margin-top:2px">Sign in to sync orders & chat</p>
        </div>
      </div>
      <div style="display:flex;gap:8px;margin-top:16px">
        <button class="btn btn-ghost" style="flex:1;padding:11px;background:rgba(255,255,255,.14);border-color:rgba(255,255,255,.3);color:#fff" onclick="go('login')">Login</button>
        <button class="btn btn-primary" style="flex:1;padding:11px;box-shadow:none" onclick="go('register')">Register</button>
      </div>
    </div>
    <div class="wallet">
      <div><strong>—</strong><span>Wallet</span></div>
      <div><strong>0</strong><span>Coupons</span></div>
      <div><strong>0</strong><span>Favorites</span></div>
    </div>
    <div class="menu-list">
      <div class="menu-item" onclick="go('orders')">My Orders <span>›</span></div>
      <div class="menu-item">My Documents <span>›</span></div>
      <div class="menu-item">Branch <span>Yiwu ›</span></div>
      <div class="menu-item">Language <span>English ›</span></div>
      <div class="menu-item" onclick="go('about')">About OBIC <span>›</span></div>
      <div class="menu-item" onclick="go('chat')">Support <span>›</span></div>
    </div>
  </div>
  ${tabBar("me")}`;
}

function renderLogin() {
  return `
  <div class="page-header"><button class="back" onclick="go('me')">←</button><h2>Login</h2></div>
  <div class="app-body"><div class="form">
    <div class="auth-hero"><div class="brand">OBIC</div><p>Welcome back — continue your China journey</p></div>
    <div><label>Phone or Email</label><input placeholder="+86 / you@email.com" /></div>
    <div><label>Password</label><input type="password" placeholder="••••••••" /></div>
    <button class="btn btn-primary" onclick="toast('Logged in (prototype)'); go('me')">Login</button>
    <button class="btn btn-ghost" onclick="go('register')">Create account</button>
    <p style="text-align:center;font-size:12px;color:var(--muted)">Guest browse stays available from Home</p>
  </div></div>`;
}

function renderRegister() {
  return `
  <div class="page-header"><button class="back" onclick="go('me')">←</button><h2>Register</h2></div>
  <div class="app-body"><div class="form">
    <div class="auth-hero"><div class="brand">OBIC</div><p>Create your account in under a minute</p></div>
    <div><label>Mobile (+country code)</label><input placeholder="+966 ..." /></div>
    <div><label>Email (required)</label><input placeholder="you@email.com" /></div>
    <div><label>Password</label><input type="password" placeholder="6–12 letters+numbers+symbol" /></div>
    <div><label>SMS code</label><input placeholder="6-digit code" /></div>
    <label style="display:flex;gap:8px;align-items:flex-start;font-size:12px;color:var(--navy);font-weight:500">
      <input type="checkbox" style="width:auto;margin-top:2px" /> I agree to User Agreement & Privacy Policy
    </label>
    <button class="btn btn-primary" onclick="toast('Account created (prototype)'); go('me')">Register</button>
  </div></div>`;
}

function renderSearch() {
  return `
  <div class="page-header"><button class="back" onclick="go('home')">←</button><h2>Search</h2></div>
  <div class="app-body">
    <div class="section"><div class="search" style="margin:0"><span class="si">${ico("search")}</span>visa</div></div>
    <div class="section">
      <div class="section-title">Hot searches</div>
      <div class="hot-tags">
        ${[["Visa","visa"],["VIP","vip"],["Bank","bank"],["Hotel","hotels"],["Company","company"]].map(([t,id]) =>
          `<button class="chip" onclick="go('detail',{serviceId:'${id}'})">${t}</button>`).join("")}
      </div>
      ${SERVICES.filter(s => /visa|vip|bank|hotel/i.test(s.name)).map(s => `
        <div class="list-card" onclick="go('detail',{serviceId:'${s.id}'})">
          ${thumb(s)}<div><h4>${s.name}</h4><p>${s.price}</p></div>
        </div>`).join("")}
    </div>
  </div>`;
}

function renderAbout() {
  return `
  <div class="page-header"><button class="back" onclick="go('me')">←</button><h2>About OBIC</h2></div>
  <div class="app-body"><div class="section">
    <div class="banner-wrap" style="margin-bottom:12px">
      <div class="banner b1" style="width:100%">
        <div class="eyebrow">Brand</div>
        <h3>OBIC</h3>
        <p>Corporate services across China & beyond — visas, banking, travel, company setup, VIP.</p>
      </div>
    </div>
    <div class="list-card"><div class="thumb" style="background:#E8F1FF;color:var(--blue)">${ico("pin")}</div><div><h4>Branches</h4><p>Yiwu · Guangzhou · Yemen · Foshan · Hangzhou · Hainan</p></div></div>
    <div class="list-card"><div class="thumb" style="background:#E8F1FF;color:var(--blue)">${ico("web")}</div><div><h4>Website</h4><p>www.obicgp.com</p></div></div>
    <div class="list-card"><div class="thumb" style="background:#E8F1FF;color:var(--blue)">${ico("mail")}</div><div><h4>Contact</h4><p>Support via in-app chat</p></div></div>
    <p style="font-size:11px;color:var(--muted);margin-top:16px;text-align:center">© 2026 OBIC · Confidential prototype · English V1</p>
  </div></div>`;
}

const RENDERERS = {
  home: renderHome,
  services: renderServices,
  detail: renderDetail,
  request: renderRequest,
  orders: renderOrders,
  orderDetail: renderOrderDetail,
  messages: renderMessages,
  chat: renderChat,
  voiceCall: renderVoiceCall,
  videoCall: renderVideoCall,
  incomingCall: renderIncomingCall,
  me: renderMe,
  login: renderLogin,
  register: renderRegister,
  search: renderSearch,
  about: renderAbout,
};

function render() {
  nav.innerHTML = SCREENS.map(s =>
    `<button class="${state.screen === s.id ? "active" : ""}" onclick="go('${s.id}')">${s.label}</button>`
  ).join("");
  const html = (RENDERERS[state.screen] || renderHome)();
  app.innerHTML = html + (state.toast ? `<div class="toast">${state.toast}</div>` : "");
}

window.go = go;
window.toast = toast;
window.attachImage = attachImage;
window.attachFile = attachFile;
window.sendChatText = sendChatText;
window.toggleMute = toggleMute;
window.toggleSpeaker = toggleSpeaker;
render();
