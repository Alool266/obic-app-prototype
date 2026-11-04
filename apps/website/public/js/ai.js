/**
 * OBIC AI on the website — same assistant, history, translate, and files as the app.
 * No account. History stays in this browser.
 * Photo: JPEG, PNG, WebP. Files: PDF, Excel, CSV. Max 4 MB. The key stays on the server.
 */
(function () {
  var API = "https://api.obicgp.com";
  var STORE_KEY = "obicAiLocalThreads";
  var MAX_BYTES = 4 * 1024 * 1024;
  var UUID = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

  var COPY = {
    en: {
      title: "OBIC AI",
      signTitle: "Sign in",
      signBody: "Use the same account as the OBIC app.",
      account: "Email or phone",
      password: "Password",
      totp: "Authenticator code",
      signIn: "Sign in",
      signOut: "Sign out",
      guideTab: "Guide",
      chatTab: "Chat",
      historyTab: "History",
      newChat: "New chat",
      welcome: "Ask about any app service — property, transport, travel, healthcare, food, shopping, education, logistics, government, business, visas, hotels, offers, or branches — or your order status. Staff can still help anytime.",
      hint: "Ask OBIC AI…",
      offline: "OBIC AI is off on this server until the team enables it. You can still chat with staff.",
      emptyReply: "No reply yet — try again or chat with staff.",
      providerDown: "OBIC AI is busy right now. Send that again in a moment.",
      historyEmpty: "No past chats yet. Ask something in Chat — it will appear here.",
      del: "Delete",
      copy: "Copy",
      copied: "Copied",
      nothing: "Nothing to copy",
      retry: "Retry",
      stop: "Stop",
      send: "Send",
      attach: "Attach",
      photo: "Photo",
      pdf: "PDF",
      sheet: "Spreadsheet",
      remove: "Remove attachment",
      tooBig: "This file is over 4 MB. Choose a smaller one.",
      unsupported: "Only JPEG, PNG, or WebP photos, PDF, and Excel or CSV spreadsheets are supported.",
      unreadable: "Could not read this file.",
      notConfigured: "Image and file reading is not configured.",
      guideTitle: "How to use OBIC AI",
      guide: "What OBIC AI does\n• Answers questions about the full Services catalog — property, transport, travel, healthcare, food, shopping, education, logistics, government, and business — including visas, hotels, delivery, and the other listed items, plus Offers and branches.\n• Replies in your language — Arabic, English, Chinese, French, and others. Write naturally; it matches you.\n\nThis screen vs auto-reply\n• This Chat tab is your dedicated assistant. History keeps past Q&A so you can come back later.\n• Support and order chats may also get a short AI auto-reply.\n• Friend chats stay private — no AI there.\n\nTalk to staff\n• For a human, open Messages → OBIC Support or an order chat → Talk to staff.\n\nLanguages\n• App language (AR / EN / 中文 / FR) controls this screen’s labels.\n• Your message language controls the AI reply.",
      translate: "Translate",
      showOriginal: "Show original",
      showTranslation: "Show translation",
      translating: "Translating…",
      translateFailed: "Translation failed — try again.",
      today: "Today",
      yesterday: "Yesterday",
      you: "You",
      ai: "OBIC AI"
    },
    ar: {
      title: "أوبك AI",
      signTitle: "دخول",
      signBody: "استخدم نفس حساب تطبيق أوبك.",
      account: "البريد أو الجوال",
      password: "كلمة المرور",
      totp: "رمز المصادقة",
      signIn: "دخول",
      signOut: "خروج",
      guideTab: "دليل",
      chatTab: "محادثة",
      historyTab: "السجل",
      newChat: "محادثة جديدة",
      welcome: "اسأل عن أي خدمة في التطبيق: عقارات، نقل، سفر، صحة، طعام، تسوق، تعليم، شحن، حكومة، أعمال، تأشيرات، فنادق، عروض أو فروع، أو عن حالة طلبك. الفريق جاهز للمساعدة دائماً.",
      hint: "اسأل أوبك AI…",
      offline: "مساعد أوبك غير مفعّل على هذا الخادم بعد. يمكنك محادثة الفريق.",
      emptyReply: "لا رد بعد — أعد المحاولة أو تواصل مع الفريق.",
      providerDown: "أوبك AI مشغول الآن. أعد الإرسال بعد لحظة.",
      historyEmpty: "لا محادثات سابقة بعد. اسأل في تبويب المحادثة وستظهر هنا.",
      del: "حذف",
      copy: "نسخ",
      copied: "تم النسخ",
      nothing: "لا يوجد نص للنسخ",
      retry: "إعادة الإجابة",
      stop: "إيقاف",
      send: "إرسال",
      attach: "إرفاق",
      photo: "صورة",
      pdf: "PDF",
      sheet: "جدول",
      remove: "إزالة المرفق",
      tooBig: "الملف أكبر من ٤ ميغابايت. اختر ملفاً أصغر.",
      unsupported: "يُقبل فقط صور JPEG أو PNG أو WebP، أو PDF، أو Excel أو CSV.",
      unreadable: "تعذّر قراءة هذا الملف.",
      notConfigured: "قراءة الصور والملفات غير مهيأة.",
      guideTitle: "كيف تستخدم أوبك AI",
      guide: "ماذا يفعل أوبك AI\n• يجيب عن كامل كتالوج الخدمات: عقارات، نقل، سفر، رعاية صحية، طعام، تسوق، تعليم، شحن، خدمات حكومية وأعمال، بما فيها التأشيرات والفنادق والتوصيل وباقي البنود، إضافة إلى العروض والفروع.\n• يرد بلغتك — العربية والإنجليزية والصينية والفرنسية وغيرها. اكتب بحرية؛ يطابق لغتك.\n\nهذه الشاشة مقابل الرد التلقائي\n• تبويب المحادثة هو مساعدك المخصص. السجل يحفظ الأسئلة والأجوبة لتعود إليها لاحقاً.\n• محادثات الدعم والطلبات قد تحصل أيضاً على رد تلقائي قصير من الذكاء الاصطناعي.\n• محادثات الأصدقاء تبقى خاصة — بلا ذكاء اصطناعي.\n\nتحدث مع الفريق\n• للمساعدة البشرية: الرسائل ← دعم أوبك أو محادثة طلب ← تحدث مع الفريق.\n\nاللغات\n• لغة التطبيق (ع / EN / 中文 / FR) تتحكم بعناوين هذه الشاشة.\n• لغة رسالتك تتحكم برد المساعد.",
      translate: "ترجمة",
      showOriginal: "إظهار الأصل",
      showTranslation: "إظهار الترجمة",
      translating: "جارٍ الترجمة…",
      translateFailed: "تعذّرت الترجمة — أعد المحاولة.",
      today: "اليوم",
      yesterday: "أمس",
      you: "أنت",
      ai: "أوبك AI"
    },
    zh: {
      title: "OBIC AI",
      signTitle: "登录",
      signBody: "使用与 OBIC 应用相同的账号。",
      account: "邮箱或手机",
      password: "密码",
      totp: "验证器验证码",
      signIn: "登录",
      signOut: "退出",
      guideTab: "说明",
      chatTab: "对话",
      historyTab: "历史",
      newChat: "新对话",
      welcome: "可咨询应用里的全部服务：房产、交通、旅游、医疗、餐饮、购物、教育、物流、政务、商务、签证、酒店、优惠或网点，也可查询订单状态。人工客服随时可帮助您。",
      hint: "问 OBIC AI…",
      offline: "本服务器尚未开启 OBIC AI。您仍可联系人工客服。",
      emptyReply: "暂无回复 — 请重试或联系客服。",
      providerDown: "OBIC AI 这会儿正忙。请稍后再发一次。",
      historyEmpty: "暂无历史对话。在「对话」提问后会显示在这里。",
      del: "删除",
      copy: "复制",
      copied: "已复制",
      nothing: "没有可复制的文字",
      retry: "重新生成",
      stop: "停止",
      send: "发送",
      attach: "添加附件",
      photo: "照片",
      pdf: "PDF",
      sheet: "表格",
      remove: "移除附件",
      tooBig: "文件超过 4 MB，请选择更小的文件。",
      unsupported: "仅支持 JPEG、PNG、WebP 图片，以及 PDF、Excel 或 CSV。",
      unreadable: "无法读取此文件。",
      notConfigured: "图片和文件阅读尚未配置。",
      guideTitle: "如何使用 OBIC AI",
      guide: "OBIC AI 能做什么\n• 回答服务目录中的全部内容：房产、交通、旅游、医疗、餐饮、购物、教育、物流、政务与商务，以及签证、酒店、配送等子项，还有优惠与网点。\n• 用您的语言回复——阿拉伯语、英语、中文、法语及其他语言。自然书写即可，它会跟随您的语言。\n\n本页与自动回复\n• 「对话」是您的专属助手。「历史」保存问答，方便稍后回来查看。\n• 客服与订单会话也可能收到简短 AI 自动回复。\n• 好友聊天保持社交私密——没有 AI。\n\n联系人工\n• 需要人工：消息 → OBIC 客服或订单会话 →「联系人工」。\n\n语言\n• 应用语言（阿 / EN / 中文 / FR）控制本页界面文案。\n• 您消息的语言控制 AI 回复语言。",
      translate: "翻译",
      showOriginal: "显示原文",
      showTranslation: "显示译文",
      translating: "正在翻译…",
      translateFailed: "翻译失败 — 请重试。",
      today: "今天",
      yesterday: "昨天",
      you: "你",
      ai: "OBIC AI"
    }
  };

  var tab = "chat";
  var turns = [];
  var threads = [];
  var threadId = null;
  var pending = null;
  var sending = false;
  var enabled = true;
  var abortCtl = null;
  var askSerial = 0;
  var translations = {};
  var translating = {};
  var translationHidden = {};
  var totpSession = "";

  function lang() {
    var code = window.ObicI18n && ObicI18n.getLang ? ObicI18n.getLang() : "en";
    return COPY[code] ? code : "en";
  }
  function t() { return COPY[lang()]; }
  function localeCode() {
    var code = lang();
    return code === "ar" || code === "zh" ? code : "en";
  }
  function el(id) { return document.getElementById(id); }
  function token() { return ""; }

  function toast(message) {
    var node = el("ai-toast");
    if (!node) return;
    node.hidden = !message;
    node.textContent = message || "";
    if (!message) return;
    clearTimeout(toast._timer);
    toast._timer = setTimeout(function () { node.hidden = true; }, 1600);
  }

  function showError(message) {
    var node = el("ai-error");
    node.hidden = !message;
    node.textContent = message || "";
  }

  function applyCopy() {
    var copy = t();
    document.title = copy.title;
    el("ai-title").textContent = copy.title;
    el("ai-sign-title").textContent = copy.signTitle;
    el("ai-sign-body").textContent = copy.signBody;
    el("ai-account-label").textContent = copy.account;
    el("ai-password-label").textContent = copy.password;
    el("ai-totp-label").textContent = copy.totp;
    el("ai-sign-in").textContent = copy.signIn;
    el("ai-sign-out").textContent = copy.signOut;
    el("ai-tab-guide").textContent = copy.guideTab;
    el("ai-tab-chat").textContent = copy.chatTab;
    el("ai-tab-history").textContent = copy.historyTab;
    el("ai-new").textContent = copy.newChat;
    el("ai-input").placeholder = copy.hint;
    el("ai-attach").textContent = copy.attach;
    el("ai-send").textContent = sending ? copy.stop : copy.send;
    el("ai-offline").textContent = copy.offline;
    var menu = el("ai-attach-menu");
    menu.querySelector('[data-kind="photo"]').textContent = copy.photo;
    menu.querySelector('[data-kind="pdf"]').textContent = copy.pdf;
    menu.querySelector('[data-kind="sheet"]').textContent = copy.sheet;
    el("ai-pane-guide").textContent = copy.guideTitle + "\n\n" + copy.guide;
    render();
  }

  function setTab(next) {
    tab = next;
    ["guide", "chat", "history"].forEach(function (name) {
      el("ai-tab-" + name).classList.toggle("is-on", name === next);
      el("ai-pane-" + name).hidden = name !== next;
    });
    el("ai-new").hidden = next === "guide";
  }

  function showDesk(on) {
    el("ai-gate").hidden = on;
    el("ai-desk").hidden = !on;
    el("ai-new").hidden = !on || tab === "guide";
  }

  async function readJson(res) {
    var bodyText = await res.text();
    var json = {};
    if (bodyText) {
      try { json = JSON.parse(bodyText); } catch (e) { json = {}; }
    }
    if (!res.ok) {
      var message = json.message;
      if (Array.isArray(message)) message = message.join("\n");
      if (typeof message !== "string") message = "Request failed (" + res.status + ")";
      var err = new Error(message);
      err.status = res.status;
      throw err;
    }
    return json;
  }

  function jsonHeaders() {
    return {
      Accept: "application/json",
      "Content-Type": "application/json"
    };
  }

  function loadStore() {
    try {
      var raw = JSON.parse(localStorage.getItem(STORE_KEY) || "[]");
      return Array.isArray(raw) ? raw : [];
    } catch (e) {
      return [];
    }
  }

  function slimTurn(turn) {
    var out = {
      role: turn.role === "assistant" ? "assistant" : "user",
      text: turn.text || "",
      createdAt: turn.createdAt || null,
      attachmentKind: turn.attachmentKind || null,
      attachmentName: turn.attachmentName || null
    };
    if (Array.isArray(turn.artifacts) && turn.artifacts.length) {
      out.artifacts = turn.artifacts;
    }
    return out;
  }

  function saveStore() {
    var slim = threads.slice(0, 30).map(function (thread) {
      return {
        id: thread.id,
        title: thread.title || "",
        updatedAt: thread.updatedAt || null,
        turns: (thread.turns || []).map(slimTurn)
      };
    });
    try { localStorage.setItem(STORE_KEY, JSON.stringify(slim)); } catch (e) {}
  }

  function rememberThread() {
    if (!turns.length) return;
    if (!threadId) threadId = "local-" + Date.now();
    var title = "";
    for (var i = 0; i < turns.length; i++) {
      if (turns[i].role === "user" && (turns[i].text || "").trim()) {
        title = turns[i].text.trim().slice(0, 80);
        break;
      }
    }
    if (!title) title = t().title;
    var record = {
      id: threadId,
      title: title,
      updatedAt: new Date().toISOString(),
      turns: turns.map(slimTurn)
    };
    var found = false;
    threads = threads.map(function (thread) {
      if (thread.id !== threadId) return thread;
      found = true;
      return record;
    });
    if (!found) threads.unshift(record);
    saveStore();
  }

  function mimeForName(name) {
    var lower = String(name || "").toLowerCase();
    if (lower.endsWith(".png")) return "image/png";
    if (lower.endsWith(".webp")) return "image/webp";
    if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
    if (lower.endsWith(".pdf")) return "application/pdf";
    if (lower.endsWith(".csv")) return "text/csv";
    if (lower.endsWith(".xlsx")) return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
    if (lower.endsWith(".xls")) return "application/vnd.ms-excel";
    return "";
  }

  function bytesToBase64(bytes) {
    var binary = "";
    var chunk = 0x8000;
    for (var i = 0; i < bytes.length; i += chunk) {
      binary += String.fromCharCode.apply(null, bytes.subarray(i, i + chunk));
    }
    return btoa(binary);
  }

  function readFile(file) {
    return new Promise(function (resolve, reject) {
      var reader = new FileReader();
      reader.onload = function () { resolve(new Uint8Array(reader.result)); };
      reader.onerror = function () { reject(new Error("read")); };
      reader.readAsArrayBuffer(file);
    });
  }

  function compressPhoto(file) {
    return new Promise(function (resolve, reject) {
      var url = URL.createObjectURL(file);
      var img = new Image();
      img.onload = function () {
        var maxW = 1280;
        var scale = img.width > maxW ? maxW / img.width : 1;
        var canvas = document.createElement("canvas");
        canvas.width = Math.max(1, Math.round(img.width * scale));
        canvas.height = Math.max(1, Math.round(img.height * scale));
        var ctx = canvas.getContext("2d");
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
        canvas.toBlob(function (blob) {
          URL.revokeObjectURL(url);
          if (!blob) reject(new Error("read"));
          else resolve(blob);
        }, "image/jpeg", 0.7);
      };
      img.onerror = function () {
        URL.revokeObjectURL(url);
        reject(new Error("read"));
      };
      img.src = url;
    });
  }

  async function stageFile(file, expected) {
    var copy = t();
    if (!file) return;
    var mime = mimeForName(file.name);
    if (expected === "photo") {
      if (!mime || mime.indexOf("image/") !== 0) {
        toast(copy.unsupported);
        return;
      }
      var blob;
      try { blob = await compressPhoto(file); }
      catch (e) { toast(copy.unreadable); return; }
      if (blob.size > MAX_BYTES) {
        toast(copy.tooBig);
        return;
      }
      var photoBytes = new Uint8Array(await blob.arrayBuffer());
      var name = file.name && /\.(jpe?g|png|webp)$/i.test(file.name) ? file.name : "photo.jpg";
      if (!/\.jpe?g$/i.test(name)) name = name.replace(/\.[^.]+$/, "") + ".jpg";
      pending = {
        kind: "image",
        filename: name,
        mime: "image/jpeg",
        dataBase64: bytesToBase64(photoBytes),
        preview: URL.createObjectURL(blob)
      };
      renderPending();
      return;
    }
    if (!mime || mime.indexOf("image/") === 0) {
      toast(copy.unsupported);
      return;
    }
    if (expected === "pdf" && mime !== "application/pdf") {
      toast(copy.unsupported);
      return;
    }
    if (expected === "sheet" && mime !== "text/csv" && mime.indexOf("spreadsheet") === -1 && mime !== "application/vnd.ms-excel") {
      toast(copy.unsupported);
      return;
    }
    if (file.size > MAX_BYTES) {
      toast(copy.tooBig);
      return;
    }
    var bytes;
    try { bytes = await readFile(file); }
    catch (e) { toast(copy.unreadable); return; }
    if (!bytes.length) {
      toast(copy.unreadable);
      return;
    }
    pending = {
      kind: "file",
      filename: file.name,
      mime: mime,
      dataBase64: bytesToBase64(bytes),
      preview: ""
    };
    renderPending();
  }

  function renderPending() {
    var box = el("ai-pending");
    var copy = t();
    if (!pending) {
      box.hidden = true;
      box.replaceChildren();
      return;
    }
    box.hidden = false;
    box.replaceChildren();
    if (pending.kind === "image" && pending.preview) {
      var img = document.createElement("img");
      img.alt = "";
      img.src = pending.preview;
      box.appendChild(img);
    }
    var name = document.createElement("span");
    name.textContent = pending.filename;
    box.appendChild(name);
    var remove = document.createElement("button");
    remove.type = "button";
    remove.className = "btn btn-ghost";
    remove.textContent = copy.remove;
    remove.disabled = sending;
    remove.addEventListener("click", function () {
      if (pending && pending.preview) URL.revokeObjectURL(pending.preview);
      pending = null;
      renderPending();
    });
    box.appendChild(remove);
  }

  function historyContent(turn) {
    var text = (turn.text || "").trim();
    var name = (turn.attachmentName || "").trim();
    if (turn.attachmentKind === "image") {
      if (!text) return name ? "User sent a photo (" + name + ")." : "User sent a photo.";
      return name ? "User sent a photo (" + name + ") and wrote: " + text : "User sent a photo and wrote: " + text;
    }
    if (turn.attachmentKind === "file") {
      if (!text) return name ? "User sent a file (" + name + ")." : "User sent a file.";
      return name ? "User sent a file (" + name + ") and wrote: " + text : "User sent a file and wrote: " + text;
    }
    return text;
  }

  function historyBefore(index) {
    var history = [];
    for (var i = 0; i < index && i < turns.length; i++) {
      var turn = turns[i];
      if (turn.isError) continue;
      var content = historyContent(turn).trim();
      if (!content) continue;
      history.push({ role: turn.role, content: content });
    }
    if (history.length > 6) history = history.slice(history.length - 6);
    return history;
  }

  function recentImageAttachment() {
    var start = turns.length > 6 ? turns.length - 6 : 0;
    for (var i = turns.length - 1; i >= start; i--) {
      var turn = turns[i];
      if (turn.role !== "user" || turn.attachmentKind !== "image") continue;
      if (!turn.dataBase64 || !turn.attachmentName || !turn.attachmentMime) continue;
      return {
        kind: "image",
        filename: turn.attachmentName,
        mime: turn.attachmentMime,
        dataBase64: turn.dataBase64
      };
    }
    return null;
  }

  function dayLabel(date) {
    var copy = t();
    var now = new Date();
    var day = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    var today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    var yesterday = new Date(today.getTime() - 86400000);
    if (day.getTime() === today.getTime()) return copy.today;
    if (day.getTime() === yesterday.getTime()) return copy.yesterday;
    return date.toLocaleDateString(lang() === "zh" ? "zh-CN" : lang() === "ar" ? "ar" : "en", {
      weekday: "short", year: "numeric", month: "short", day: "numeric"
    });
  }

  function lastIndexes() {
    var lastAssistant = -1;
    var lastUser = -1;
    for (var i = turns.length - 1; i >= 0; i--) {
      if (lastAssistant < 0 && turns[i].role === "assistant") lastAssistant = i;
      if (lastUser < 0 && turns[i].role === "user" && ((turns[i].text || "").trim() || turns[i].attachmentKind)) lastUser = i;
      if (lastAssistant >= 0 && lastUser >= 0) break;
    }
    return { lastAssistant: lastAssistant, lastUser: lastUser };
  }

  function render() {
    if (!el("ai-stream")) return;
    renderPending();
    var copy = t();
    var stream = el("ai-stream");
    stream.replaceChildren();
    if (!turns.length) {
      var welcome = document.createElement("p");
      welcome.className = "chat-empty";
      welcome.textContent = copy.welcome;
      stream.appendChild(welcome);
    }
    var marks = lastIndexes();
    var prev = null;
    turns.forEach(function (turn, index) {
      var at = turn.createdAt ? new Date(turn.createdAt) : null;
      if (at && (!prev || prev.toDateString() !== at.toDateString())) {
        var chip = document.createElement("div");
        chip.className = "ai-day";
        chip.textContent = dayLabel(at);
        stream.appendChild(chip);
      }
      if (at) prev = at;
      var mine = turn.role === "user";
      var row = document.createElement("div");
      row.className = "ai-row" + (mine ? " is-me" : "");
      var bubble = document.createElement("div");
      bubble.className = "chat-bubble" + (mine ? " is-me" : "");
      var who = document.createElement("div");
      who.className = "chat-who";
      who.textContent = mine ? copy.you : copy.ai;
      bubble.appendChild(who);
      if (turn.attachmentKind === "image" && turn.preview) {
        var shot = document.createElement("img");
        shot.alt = turn.attachmentName || "";
        shot.src = turn.preview;
        shot.style.cssText = "width:180px;height:140px;object-fit:cover;border-radius:10px;display:block";
        bubble.appendChild(shot);
      } else if (turn.attachmentName) {
        var chipName = document.createElement("div");
        chipName.className = "ai-file-chip";
        chipName.textContent = turn.attachmentName;
        bubble.appendChild(chipName);
      }
      var arts = Array.isArray(turn.artifacts) ? turn.artifacts : [];
      arts.forEach(function (art) {
        if (!art || !art.url) return;
        var href = art.url.indexOf("http") === 0 ? art.url : API + art.url;
        var isImg = art.kind === "image" || (art.mime && art.mime.indexOf("image/") === 0);
        if (isImg) {
          var img = document.createElement("img");
          img.alt = art.name || "";
          img.src = href;
          img.style.cssText = "width:200px;max-height:180px;object-fit:cover;border-radius:10px;display:block;margin:6px 0";
          bubble.appendChild(img);
        }
        var link = document.createElement("a");
        link.className = "ai-file-chip";
        link.href = href;
        link.target = "_blank";
        link.rel = "noopener";
        link.download = art.name || "obic-file";
        link.textContent = (art.name || "Download") + (isImg ? "" : " ↓");
        link.style.cssText = "display:inline-block;margin:4px 0;text-decoration:none";
        bubble.appendChild(link);
      });
      if ((turn.text || "").trim()) {
        var text = document.createElement("div");
        text.className = "chat-text";
        text.textContent = turn.text;
        text.dir = "auto";
        bubble.appendChild(text);
      }
      var line = document.createElement("div");
      line.className = "ai-line";
      if (!mine) {
        var mark = document.createElement("img");
        mark.className = "ai-mark";
        mark.src = "/ai-mark.svg";
        mark.alt = "";
        line.appendChild(mark);
      }
      line.appendChild(bubble);
      row.appendChild(line);
      var canRetry = !sending && marks.lastUser >= 0 && (
        (marks.lastAssistant > marks.lastUser && index === marks.lastAssistant) ||
        (marks.lastAssistant < marks.lastUser && index === marks.lastUser)
      );
      var showTranslate = !turn.isError && turn.attachmentKind !== "image" && (turn.text || "").trim();
      var actions = document.createElement("div");
      actions.className = "ai-actions";
      if (!mine) {
        var copyBtn = document.createElement("button");
        copyBtn.type = "button";
        copyBtn.textContent = copy.copy;
        copyBtn.addEventListener("click", function () { copyText(turn.text); });
        actions.appendChild(copyBtn);
      }
      if (canRetry) {
        var retryBtn = document.createElement("button");
        retryBtn.type = "button";
        retryBtn.textContent = copy.retry;
        retryBtn.addEventListener("click", retryLast);
        actions.appendChild(retryBtn);
      }
      if (showTranslate && !translations[index]) {
        var tr = document.createElement("button");
        tr.type = "button";
        tr.textContent = translating[index] ? copy.translating : copy.translate;
        tr.disabled = !!translating[index];
        tr.addEventListener("click", function () { translateTurn(index); });
        actions.appendChild(tr);
      }
      if (actions.childNodes.length) row.appendChild(actions);
      if (translating[index]) {
        var wait = document.createElement("div");
        wait.className = "ai-translation";
        wait.textContent = copy.translating;
        row.appendChild(wait);
      }
      if (translations[index] && !translationHidden[index]) {
        var translated = document.createElement("div");
        translated.className = "ai-translation";
        translated.textContent = translations[index];
        if (/[\u0600-\u06FF]/.test(translations[index])) translated.dir = "rtl";
        row.appendChild(translated);
        var hide = document.createElement("button");
        hide.type = "button";
        hide.className = "ai-actions";
        hide.textContent = copy.showOriginal;
        hide.addEventListener("click", function () {
          translationHidden[index] = true;
          render();
        });
        row.appendChild(hide);
      } else if (translations[index]) {
        var show = document.createElement("button");
        show.type = "button";
        show.className = "ai-actions";
        show.textContent = copy.showTranslation;
        show.addEventListener("click", function () {
          translationHidden[index] = false;
          render();
        });
        row.appendChild(show);
      }
      stream.appendChild(row);
    });
    if (sending) {
      var stopRow = document.createElement("div");
      var stop = document.createElement("button");
      stop.type = "button";
      stop.className = "btn btn-ghost";
      stop.textContent = copy.stop;
      stop.addEventListener("click", stopAsk);
      stopRow.appendChild(stop);
      stream.appendChild(stopRow);
    }
    stream.scrollTop = stream.scrollHeight;
    renderHistory();
    el("ai-send").textContent = sending ? copy.stop : copy.send;
  }

  function renderHistory() {
    var box = el("ai-history");
    var copy = t();
    box.replaceChildren();
    if (!threads.length) {
      var empty = document.createElement("p");
      empty.className = "chat-empty";
      empty.textContent = copy.historyEmpty;
      box.appendChild(empty);
      var start = document.createElement("button");
      start.type = "button";
      start.className = "btn btn-primary";
      start.textContent = copy.newChat;
      start.addEventListener("click", newChat);
      box.appendChild(start);
      return;
    }
    threads.forEach(function (thread) {
      var row = document.createElement("div");
      row.className = "ai-history-item" + (thread.id === threadId ? " is-on" : "");
      var body = document.createElement("button");
      body.type = "button";
      body.style.cssText = "flex:1;border:0;background:transparent;text-align:inherit;font:inherit;cursor:pointer";
      var title = document.createElement("strong");
      title.textContent = thread.title || copy.title;
      var when = document.createElement("span");
      var updated = thread.updatedAt ? new Date(thread.updatedAt) : null;
      when.textContent = updated ? formatWhen(updated) : "";
      body.appendChild(title);
      body.appendChild(when);
      body.addEventListener("click", function () { openThread(thread.id); });
      var del = document.createElement("button");
      del.type = "button";
      del.className = "btn btn-ghost";
      del.textContent = copy.del;
      del.addEventListener("click", function (event) {
        event.stopPropagation();
        deleteThread(thread.id);
      });
      row.appendChild(body);
      row.appendChild(del);
      box.appendChild(row);
    });
  }

  function formatWhen(date) {
    var y = date.getFullYear();
    var m = String(date.getMonth() + 1).padStart(2, "0");
    var d = String(date.getDate()).padStart(2, "0");
    var hh = String(date.getHours()).padStart(2, "0");
    var mm = String(date.getMinutes()).padStart(2, "0");
    return y + "-" + m + "-" + d + " " + hh + ":" + mm;
  }

  async function copyText(text) {
    var value = (text || "").trim();
    if (!value) {
      toast(t().nothing);
      return;
    }
    try {
      await navigator.clipboard.writeText(value);
      toast(t().copied);
    } catch (e) {
      toast(t().nothing);
    }
  }

  function stopAsk() {
    askSerial += 1;
    if (abortCtl) abortCtl.abort();
    abortCtl = null;
    sending = false;
    render();
  }

  function clearTranslations() {
    translations = {};
    translating = {};
    translationHidden = {};
  }

  function newChat() {
    stopAsk();
    threadId = null;
    turns = [];
    if (pending && pending.preview) URL.revokeObjectURL(pending.preview);
    pending = null;
    showError("");
    clearTranslations();
    setTab("chat");
    render();
  }

  async function openThread(id) {
    stopAsk();
    showError("");
    clearTranslations();
    try {
      var thread = null;
      for (var i = 0; i < threads.length; i++) {
        if (threads[i].id === id) thread = threads[i];
      }
      if (!thread) return;
      threadId = thread.id;
      turns = (thread.turns || []).map(function (message) {
        return {
          role: message.role === "assistant" ? "assistant" : "user",
          text: message.text || message.content || "",
          createdAt: message.createdAt || null,
          attachmentKind: message.attachmentKind || null,
          attachmentName: message.attachmentName || null
        };
      });
      setTab("chat");
      render();
    } catch (err) {
      showError(err && err.message ? err.message : t().emptyReply);
    }
  }

  function deleteThread(id) {
    threads = threads.filter(function (thread) { return thread.id !== id; });
    saveStore();
    if (threadId === id) newChat();
    else renderHistory();
  }

  function loadThreads(openLatest) {
    threads = loadStore();
    renderHistory();
    if (openLatest && threads.length && !turns.length) openThread(threads[0].id);
  }

  async function loadStatus() {
    var res = await fetch(API + "/v1/ai/public/status", { headers: jsonHeaders() });
    var json = await readJson(res);
    enabled = json.enabled !== false;
    el("ai-offline").hidden = enabled;
  }

  function wireFrom(source) {
    if (!source || !source.dataBase64) return null;
    return {
      kind: source.kind,
      filename: source.filename || source.attachmentName,
      mime: source.mime || source.attachmentMime,
      dataBase64: source.dataBase64
    };
  }

  async function dispatchAsk(message, history, attachment, replaceAt) {
    var copy = t();
    var serial = ++askSerial;
    sending = true;
    render();
    for (var attempt = 1; attempt <= 2; attempt++) {
      abortCtl = new AbortController();
      var timedOut = false;
      var timer = setTimeout(function () {
        timedOut = true;
        if (abortCtl) abortCtl.abort();
      }, 20000);
      try {
        var body = {
          message: message,
          locale: localeCode(),
          history: history
        };
        if (attachment) body.attachment = attachment;
        var res = await fetch(API + "/v1/ai/public/assistant", {
          method: "POST",
          headers: jsonHeaders(),
          body: JSON.stringify(body),
          signal: abortCtl.signal
        });
        clearTimeout(timer);
        var json = await readJson(res);
        if (serial !== askSerial) return;
        enabled = json.enabled !== false;
        el("ai-offline").hidden = enabled;
        var reply = (json.reply || "").trim();
        var arts = Array.isArray(json.artifacts) ? json.artifacts : [];
        if (!reply && !arts.length) reply = copy.emptyReply;
        var replyTurn = {
          role: "assistant",
          text: reply,
          createdAt: new Date().toISOString(),
          artifacts: arts
        };
        if (typeof replaceAt === "number" && replaceAt >= 0 && replaceAt < turns.length) {
          turns[replaceAt] = replyTurn;
          delete translations[replaceAt];
          delete translationHidden[replaceAt];
        } else {
          turns.push(replyTurn);
        }
        sending = false;
        showError("");
        rememberThread();
        render();
        return;
      } catch (err) {
        clearTimeout(timer);
        if (serial !== askSerial) return;
        if (err && err.name === "AbortError" && !timedOut) return;
        var messageText = timedOut
          ? "AI provider unreachable"
          : (err && err.message ? err.message : copy.emptyReply);
        if (/not configured/i.test(messageText)) messageText = copy.notConfigured;
        var busy = /provider error|provider unreachable|provider busy|empty reply/i.test(messageText);
        if (busy && attempt < 2) continue;
        sending = false;
        showError(busy ? copy.providerDown : messageText);
        render();
        return;
      }
    }
  }

  async function sendMessage(event) {
    if (event) event.preventDefault();
    if (sending) {
      stopAsk();
      return;
    }
    var text = el("ai-input").value.trim();
    var held = pending;
    if (!text && !held) return;
    var attachment = held ? wireFrom(held) : recentImageAttachment();
    var userTurn = {
      role: "user",
      text: text,
      createdAt: new Date().toISOString(),
      attachmentKind: held ? held.kind : null,
      attachmentName: held ? held.filename : null,
      attachmentMime: held ? held.mime : null,
      dataBase64: held ? held.dataBase64 : null,
      preview: held ? held.preview : ""
    };
    turns.push(userTurn);
    pending = held ? null : pending;
    if (held) pending = null;
    el("ai-input").value = "";
    showError("");
    var index = turns.length - 1;
    await dispatchAsk(text, historyBefore(index), attachment);
  }

  async function retryLast() {
    if (sending) return;
    var marks = lastIndexes();
    if (marks.lastUser < 0) return;
    var userTurn = turns[marks.lastUser];
    var attachment = null;
    if (userTurn.dataBase64 && userTurn.attachmentKind) {
      attachment = {
        kind: userTurn.attachmentKind,
        filename: userTurn.attachmentName,
        mime: userTurn.attachmentMime,
        dataBase64: userTurn.dataBase64
      };
    }
    var replaceAt = marks.lastAssistant > marks.lastUser ? marks.lastAssistant : null;
    await dispatchAsk(userTurn.text || "", historyBefore(marks.lastUser), attachment, replaceAt);
  }

  async function translateTurn(index) {
    var turn = turns[index];
    if (!turn || turn.isError || !(turn.text || "").trim() || translating[index]) return;
    if (translations[index]) {
      translationHidden[index] = false;
      render();
      return;
    }
    translating[index] = true;
    render();
    try {
      var res = await fetch(API + "/v1/ai/public/translate", {
        method: "POST",
        headers: jsonHeaders(),
        body: JSON.stringify({
          text: turn.text,
          targetLocale: localeCode()
        })
      });
      var json = await readJson(res);
      var translation = (json.translation || "").trim();
      translating[index] = false;
      if (!translation) {
        toast(t().translateFailed);
        render();
        return;
      }
      translations[index] = translation;
      translationHidden[index] = false;
      render();
    } catch (err) {
      translating[index] = false;
      toast(t().translateFailed);
      render();
    }
  }

  async function boot() {
    showError("");
    showDesk(true);
    loadThreads(true);
    try {
      await loadStatus();
    } catch (err) {
      showError(err && err.message ? err.message : t().emptyReply);
    }
  }

  document.querySelectorAll(".ai-tabs button").forEach(function (button) {
    button.addEventListener("click", function () { setTab(button.getAttribute("data-tab")); });
  });
  el("ai-new").addEventListener("click", newChat);
  el("ai-form").addEventListener("submit", sendMessage);
  var signOut = el("ai-sign-out");
  if (signOut) signOut.hidden = true;
  el("ai-attach").addEventListener("click", function () {
    el("ai-attach-menu").hidden = !el("ai-attach-menu").hidden;
  });
  el("ai-attach-menu").addEventListener("click", function (event) {
    var kind = event.target.getAttribute("data-kind");
    if (!kind) return;
    el("ai-attach-menu").hidden = true;
    el("ai-file-" + kind).click();
  });
  ["photo", "pdf", "sheet"].forEach(function (kind) {
    el("ai-file-" + kind).addEventListener("change", async function (event) {
      var file = event.target.files && event.target.files[0];
      event.target.value = "";
      await stageFile(file, kind);
    });
  });

  if (window.ObicI18n && ObicI18n.onLangChange) {
    ObicI18n.onLangChange(function () { applyCopy(); });
  }
  applyCopy();
  setTab("chat");
  boot();
})();
