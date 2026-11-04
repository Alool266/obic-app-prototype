/**
 * Service pages. Details are public. Request does not require an account.
 */
(function () {
  const UI = {
    en: {
      details: "Details",
      back: "All services",
      request: "Chat about this service",
      included: "What's included",
      advisor: "Dedicated advisor",
      advisorBody: "Assigned when you open this chat",
      checklist: "Document checklist",
      checklistBody: "Clear steps inside your order",
      status: "Status updates",
      statusBody: "Track progress in this service chat",
    },
    ar: {
      details: "التفاصيل",
      back: "كل الخدمات",
      request: "محادثة حول هذه الخدمة",
      included: "ما يشمله",
      advisor: "مستشار مخصص",
      advisorBody: "يُعيَّن عند فتح هذه المحادثة",
      checklist: "قائمة المستندات",
      checklistBody: "خطوات واضحة في طلبك",
      status: "تحديثات الحالة",
      statusBody: "تابع التقدم في محادثة هذه الخدمة",
    },
    zh: {
      details: "详情",
      back: "全部服务",
      request: "就此服务咨询",
      included: "包含内容",
      advisor: "专属顾问",
      advisorBody: "打开此会话后为您分配",
      checklist: "材料清单",
      checklistBody: "在订单中查看清晰步骤",
      status: "状态更新",
      statusBody: "在此服务会话中跟踪进度",
    },
  };

  let openId = "";

  function slugFromPath() {
    const m = location.pathname.match(/\/category\/([a-z0-9-]+)/i);
    return m ? m[1].toLowerCase() : "";
  }

  function lang() {
    return window.ObicI18n ? window.ObicI18n.getLang() : "en";
  }

  function copy() {
    return UI[lang()] || UI.en;
  }

  function pick(item, field) {
    const code = lang();
    if (code === "ar") return item[field + "Ar"] || item[field + "En"] || "";
    if (code === "zh") return item[field + "Zh"] || item[field + "En"] || "";
    return item[field + "En"] || "";
  }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function hub() {
    const catalog = window.ObicCatalog;
    if (!catalog) return null;
    return catalog.bySlug(slugFromPath());
  }

  function readOpenId() {
    const hash = decodeURIComponent((location.hash || "").replace(/^#/, ""));
    if (hash) return hash;
    return new URLSearchParams(location.search).get("item") || "";
  }

  function render() {
    const item = hub();
    if (!item) {
      location.replace("/#services");
      return;
    }
    const title = pick(item, "name");
    const desc = pick(item, "desc");
    document.title = "OBIC — " + title;
    const titleEl = document.getElementById("cat-title");
    const descEl = document.getElementById("cat-desc");
    const crumb = document.getElementById("crumb-current");
    if (titleEl) titleEl.textContent = title;
    if (descEl) descEl.textContent = desc;
    if (crumb) crumb.textContent = title;
    const hero = document.getElementById("cat-photo");
    if (hero && window.ObicPhotos) {
      const src = window.ObicPhotos.photo(item.slug, item.icon);
      hero.innerHTML = `<img src="${escapeHtml(src)}" alt="" />`;
    }

    const nav = document.getElementById("cat-nav");
    if (nav && window.ObicCatalog) {
      nav.innerHTML = window.ObicCatalog.PARENTS.map((p) => {
        const on = p.slug === item.slug ? " is-on" : "";
        return `<a class="${on.trim()}" href="/category/${p.slug}">${escapeHtml(pick(p, "name"))}</a>`;
      }).join("");
    }

    const grid = document.getElementById("sub-grid");
    if (!grid) return;
    const text = copy();
    grid.innerHTML = (item.subs || [])
      .map((sub) => {
        const src = window.ObicPhotos
          ? window.ObicPhotos.photo(item.slug, sub.icon, sub.id)
          : "";
        return `<a class="svc-card" href="#${encodeURIComponent(sub.id)}" data-sub="${escapeHtml(sub.id)}">
          <img src="${escapeHtml(src)}" alt="" />
          <div>
            <h2>${escapeHtml(pick(sub, "name"))}</h2>
            <p>${escapeHtml(pick(sub, "desc"))}</p>
          </div>
          <div class="svc-card-foot">
            <strong>${escapeHtml(pick(sub, "price"))}</strong>
            <span>${escapeHtml(text.details)}</span>
          </div>
        </a>`;
      })
      .join("");

    grid.querySelectorAll("[data-sub]").forEach((link) => {
      link.addEventListener("click", (event) => {
        event.preventDefault();
        openDetail(item, link.getAttribute("data-sub"), true);
      });
    });

    const wanted = openId || readOpenId();
    if (wanted && (item.subs || []).some((sub) => sub.id === wanted)) {
      openDetail(item, wanted, false);
    } else {
      closeDetail();
    }
  }

  function chatHref(parent, sub) {
    const q = new URLSearchParams();
    q.set("service", parent.slug || "");
    q.set("item", sub.id || "");
    q.set("name", pick(sub, "name") || pick(parent, "name") || "");
    return "/messages?" + q.toString();
  }

  /** Dedicated website products — full lead forms instead of generic chat. */
  function productFormHref(subId) {
    if (subId === "scholarships") return "/study-china.html";
    if (subId === "company-registration" || subId === "company-hk") {
      return "/open-company.html";
    }
    return null;
  }

  function requestLabel(subId, fallback) {
    if (subId === "scholarships") {
      return lang() === "ar"
        ? "نموذج المنح"
        : lang() === "zh"
          ? "奖学金表单"
          : "Scholarship form";
    }
    if (subId === "company-registration" || subId === "company-hk") {
      return lang() === "ar"
        ? "نموذج الشركة"
        : lang() === "zh"
          ? "公司表单"
          : "Company form";
    }
    return fallback;
  }

  function openDetail(parent, id, push) {
    const sub = (parent.subs || []).find((s) => s.id === id);
    const panel = document.getElementById("svc-detail");
    if (!sub || !panel) return;
    openId = id;
    const text = copy();
    if (push) history.replaceState(null, "", "#" + encodeURIComponent(id));
    document.title = "OBIC — " + pick(sub, "name");
    panel.hidden = false;
    const src = window.ObicPhotos
      ? window.ObicPhotos.photo(parent.slug, sub.icon, sub.id)
      : "";
    panel.innerHTML = `
      <div class="svc-detail-photo" style="background-image:url('${escapeHtml(src)}')"></div>
      <div class="svc-detail-copy">
        <button type="button" class="svc-back" data-back>← ${escapeHtml(text.back)}</button>
        <p class="svc-kicker">${escapeHtml(pick(parent, "name"))}</p>
        <h2>${escapeHtml(pick(sub, "name"))}</h2>
        <p>${escapeHtml(pick(sub, "desc"))}</p>
        <p class="svc-kicker" style="margin-top:1.15rem">${escapeHtml(text.included)}</p>
        <ul class="svc-included">
          <li><strong>${escapeHtml(text.advisor)}</strong><span>${escapeHtml(text.advisorBody)}</span></li>
          <li><strong>${escapeHtml(text.checklist)}</strong><span>${escapeHtml(text.checklistBody)}</span></li>
          <li><strong>${escapeHtml(text.status)}</strong><span>${escapeHtml(text.statusBody)}</span></li>
        </ul>
        <div class="svc-detail-foot">
          <strong>${escapeHtml(pick(sub, "price"))}</strong>
          <a class="btn btn-primary" href="${escapeHtml(
            productFormHref(sub.id) || chatHref(parent, sub),
          )}">${escapeHtml(requestLabel(sub.id, text.request))}</a>
        </div>
      </div>`;
    const back = panel.querySelector("[data-back]");
    if (back) {
      back.addEventListener("click", () => {
        openId = "";
        history.replaceState(null, "", location.pathname);
        closeDetail();
        document.title = "OBIC — " + pick(parent, "name");
      });
    }
    panel.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  function closeDetail() {
    const panel = document.getElementById("svc-detail");
    if (!panel) return;
    panel.hidden = true;
    panel.innerHTML = "";
  }

  document.addEventListener("DOMContentLoaded", () => {
    openId = readOpenId();
    render();
    if (window.ObicI18n && window.ObicI18n.onLangChange) {
      window.ObicI18n.onLangChange(render);
    }
  });
})();
