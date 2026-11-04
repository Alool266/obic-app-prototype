/**
 * OBIC orders page — list bookings from /api/obic/orders
 */
(function () {
  function t(key, fallback) {
    try {
      if (window.ObicI18n && typeof window.ObicI18n.t === "function") {
        const v = window.ObicI18n.t(key);
        if (v && v !== key) return v;
      }
    } catch (_) {}
    return fallback;
  }

  let currentStatus = "all";
  let cache = null;

  function statusClass(status) {
    const s = (status || "").toLowerCase();
    if (s === "pending") return "is-pending";
    if (s === "confirmed") return "is-confirmed";
    if (s === "completed") return "is-completed";
    if (s === "cancelled") return "is-cancelled";
    return "";
  }

  function render(items) {
    const list = document.getElementById("orders-list");
    const empty = document.getElementById("orders-empty");
    if (!list) return;
    list.innerHTML = "";
    const filtered =
      currentStatus === "all" ? items : items.filter((o) => (o.status || "").toLowerCase() === currentStatus);

    if (!filtered.length) {
      if (empty) empty.hidden = false;
      return;
    }
    if (empty) empty.hidden = true;

    filtered.forEach((o) => {
      const card = document.createElement("article");
      card.className = "order-card";
      const price =
        o.total_price != null && o.total_price !== ""
          ? Number(o.total_price).toLocaleString(undefined, { maximumFractionDigits: 2 })
          : "—";

      const actions = document.createElement("div");
      actions.className = "order-actions";
      const detail = document.createElement("a");
      detail.className = "btn btn-ghost";
      detail.href = o.detail_url || "/order/" + o.id;
      detail.textContent = t("ordersView", "View");
      actions.appendChild(detail);
      if (o.can_pay) {
        const pay = document.createElement("a");
        pay.className = "btn btn-primary";
        pay.href = o.pay_url || "/order/" + o.id + "/pay";
        pay.textContent = t("ordersPay", "Pay");
        actions.appendChild(pay);
      }
      if (o.can_cancel) {
        const cancel = document.createElement("button");
        cancel.type = "button";
        cancel.className = "btn btn-ghost";
        cancel.textContent = t("ordersCancel", "Cancel");
        cancel.addEventListener("click", async () => {
          if (!window.confirm(t("ordersCancelAsk", "Cancel this order?"))) return;
          try {
            const tokenEl = document.querySelector('meta[name="csrf-token"]');
            let token = tokenEl ? tokenEl.content : "";
            if (!token) {
              const html = await (await fetch("/forgot-password", { credentials: "same-origin" })).text();
              const m = html.match(/name=["']_token["']\s+value=["']([^"']+)/i);
              token = m ? m[1] : "";
            }
            const fd = new FormData();
            fd.set("_token", token);
            const res = await fetch("/order/" + o.id + "/cancel", {
              method: "POST",
              body: fd,
              credentials: "same-origin",
              headers: {
                Accept: "application/json",
                "X-Requested-With": "XMLHttpRequest",
                "X-XSRF-TOKEN": token,
              },
            });
            const data = await res.json().catch(() => null);
            if (res.ok && data && data.success) {
              await loadOrders();
            } else {
              alert((data && data.message) || t("profileError", "Something went wrong."));
            }
          } catch (_) {
            alert(t("profileError", "Something went wrong."));
          }
        });
        actions.appendChild(cancel);
      }

      card.innerHTML =
        '<div class="order-top">' +
        "<div><strong>#" +
        o.id +
        "</strong> <span class=\"order-date\">" +
        (o.created_label || "") +
        "</span></div>" +
        '<span class="order-badge ' +
        statusClass(o.status) +
        '">' +
        (o.status || "") +
        "</span></div>" +
        "<h2>" +
        (o.service_label || o.service_type || "Service") +
        "</h2>" +
        (o.summary ? "<p class=\"order-summary\">" + o.summary + "</p>" : "") +
        '<div class="order-meta"><span>' +
        t("ordersPrice", "Total") +
        ": <strong>" +
        price +
        "</strong></span>" +
        (o.payment_status
          ? "<span>" + t("ordersPayment", "Payment") + ": " + o.payment_status + "</span>"
          : "") +
        "</div>";
      card.appendChild(actions);
      list.appendChild(card);
    });
  }

  async function loadOrders() {
    const res = await fetch("/api/obic/orders?status=all", {
      credentials: "same-origin",
      headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
    });
    if (res.status === 401) {
      cache = { items: [] };
      render([]);
      return false;
    }
    if (!res.ok) throw new Error("orders " + res.status);
    cache = await res.json();
    render(cache.items || []);
    return true;
  }

  function bindFilters() {
    document.querySelectorAll("#orders-filters button").forEach((btn) => {
      btn.addEventListener("click", () => {
        currentStatus = btn.dataset.status || "all";
        document.querySelectorAll("#orders-filters button").forEach((b) => b.classList.toggle("is-on", b === btn));
        render((cache && cache.items) || []);
      });
    });
  }

  async function show(user) {
    const loading = document.getElementById("orders-loading");
    const guest = document.getElementById("orders-guest");
    const panel = document.getElementById("orders-panel");
    if (loading) loading.hidden = true;
    if (!user || !user.authenticated) {
      if (guest) guest.hidden = false;
      if (panel) panel.hidden = true;
      return;
    }
    if (guest) guest.hidden = true;
    if (panel) panel.hidden = false;
    bindFilters();
    try {
      await loadOrders();
    } catch (_) {
      const empty = document.getElementById("orders-empty");
      if (empty) {
        empty.hidden = false;
        empty.textContent = t("profileError", "Something went wrong.");
      }
    }
  }

  function boot() {
    const run = (user) => show(user);
    if (window.ObicSession && typeof window.ObicSession.onUser === "function") {
      window.ObicSession.onUser(run);
      return;
    }
    (async () => {
      for (let i = 0; i < 60; i++) {
        if (window.ObicSession && typeof window.ObicSession.onUser === "function") {
          window.ObicSession.onUser(run);
          return;
        }
        if (window.ObicSession && window.ObicSession.user) {
          await run(window.ObicSession.user);
          return;
        }
        await new Promise((r) => setTimeout(r, 50));
      }
      await run({ authenticated: false });
    })();
  }

  document.addEventListener("DOMContentLoaded", boot);
})();
