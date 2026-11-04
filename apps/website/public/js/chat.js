/**
 * OBIC customer chat — general support + per-service threads.
 */
(function () {
  let roomId = null;
  let pollTimer = null;
  let myId = null;
  let activeServiceKey = "";

  function t(key, fallback) {
    try {
      if (window.ObicI18n && typeof window.ObicI18n.t === "function") {
        const v = window.ObicI18n.t(key);
        if (v && v !== key) return v;
      }
    } catch (_) {}
    return fallback;
  }

  function params() {
    return new URLSearchParams(location.search);
  }

  function serviceFromUrl() {
    const q = params();
    const parent = (q.get("service") || q.get("category") || "").trim();
    const item = (q.get("item") || q.get("sub") || "").trim();
    const name = (q.get("name") || "").trim();
    const key = [parent, item].filter(Boolean).join("/");
    return { key, name, parent, item };
  }

  async function csrfToken() {
    const html = await (await fetch("/forgot-password", { credentials: "same-origin" })).text();
    const m =
      html.match(/name=["']_token["']\s+value=["']([^"']+)/i) ||
      html.match(/csrf-token"\s+content="([^"]+)/i);
    if (m && m[1]) return m[1];
    const row = document.cookie.split(";").map((s) => s.trim()).find((s) => s.startsWith("XSRF-TOKEN="));
    if (row) {
      try {
        return decodeURIComponent(row.slice("XSRF-TOKEN=".length));
      } catch (_) {}
    }
    return "";
  }

  function showError(msg) {
    const el = document.getElementById("chat-error");
    if (!el) return;
    el.hidden = !msg;
    el.textContent = msg || "";
  }

  function setHeader(title, sub) {
    const h = document.getElementById("chat-title");
    const s = document.getElementById("chat-sub");
    if (h) h.textContent = title || t("accountChat", "Messages");
    if (s) s.textContent = sub || t("accountChatSub", "Chat with your OBIC advisor");
  }

  function renderMessages(messages) {
    const stream = document.getElementById("chat-stream");
    if (!stream) return;
    stream.innerHTML = "";
    if (!messages || !messages.length) {
      const empty = document.createElement("p");
      empty.className = "chat-empty";
      empty.textContent = t("chatEmpty", "Say hello — our team will reply here.");
      stream.appendChild(empty);
      return;
    }
    messages.forEach((m) => {
      const mine = myId != null && String(m.sender_id) === String(myId);
      const bubble = document.createElement("div");
      bubble.className = "chat-bubble" + (mine ? " is-me" : "");
      const who = document.createElement("div");
      who.className = "chat-who";
      who.textContent = mine
        ? t("chatYou", "You")
        : (m.sender && m.sender.name) || t("chatAdvisor", "OBIC advisor");
      const body = document.createElement("div");
      body.className = "chat-text";
      body.textContent = m.message || "";
      const time = document.createElement("div");
      time.className = "chat-time";
      try {
        time.textContent = new Date(m.created_at).toLocaleString();
      } catch (_) {
        time.textContent = m.created_at || "";
      }
      bubble.appendChild(who);
      bubble.appendChild(body);
      bubble.appendChild(time);
      stream.appendChild(bubble);
    });
    stream.scrollTop = stream.scrollHeight;
  }

  async function loadMessages() {
    if (!roomId) return;
    const res = await fetch("/chat/messages/" + roomId, {
      credentials: "same-origin",
      headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
    });
    if (!res.ok) return;
    const data = await res.json();
    renderMessages(Array.isArray(data) ? data : []);
  }

  function previewText(room) {
    const lm = room && (room.last_message || room.lastMessage);
    if (!lm) return t("chatEmptyShort", "No messages yet");
    return lm.message || lm.body || t("chatEmptyShort", "No messages yet");
  }

  function renderThreadList(rooms) {
    const list = document.getElementById("chat-threads");
    if (!list) return;
    list.innerHTML = "";

    const rows = [];
    let generalPreview = t("chatEmptyShort", "No messages yet");
    (rooms || []).forEach((r) => {
      const key = r.service_key || "";
      if (key) {
        rows.push({
          key,
          name: r.room_name || key,
          preview: previewText(r),
        });
      } else {
        generalPreview = previewText(r);
      }
    });
    rows.unshift({
      key: "",
      name: t("chatGeneral", "General support"),
      preview: generalPreview,
    });

    rows.forEach((r) => {
      const on =
        (r.key && r.key === activeServiceKey) || (!r.key && !activeServiceKey);
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "chat-thread" + (on ? " is-on" : "");
      const title = document.createElement("strong");
      title.textContent = r.name;
      const prev = document.createElement("span");
      prev.textContent = r.preview;
      btn.appendChild(title);
      btn.appendChild(prev);
      btn.addEventListener("click", () => openRoom(r.key, r.name));
      list.appendChild(btn);
    });
  }

  async function loadThreads() {
    const res = await fetch("/chat/customer-rooms", {
      credentials: "same-origin",
      headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
    });
    if (!res.ok) return;
    const data = await res.json();
    renderThreadList(Array.isArray(data.rooms) ? data.rooms : []);
  }

  async function ensureRoom(serviceKey, serviceName) {
    const q = new URLSearchParams();
    if (serviceKey) {
      q.set("service_key", serviceKey);
      if (serviceName) q.set("service_name", serviceName);
    }
    const url = "/chat/customer-room" + (q.toString() ? "?" + q.toString() : "");
    const res = await fetch(url, {
      credentials: "same-origin",
      headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
    });
    if (!res.ok) {
      const err = await res.json().catch(() => null);
      throw new Error((err && err.error) || "chat room failed");
    }
    const data = await res.json();
    roomId = data.room_id || (data.room && data.room.id);
    if (!roomId) throw new Error("no room");
    const name =
      serviceName ||
      (data.room && data.room.room_name) ||
      (serviceKey ? serviceKey : t("chatGeneral", "General support"));
    if (serviceKey) {
      setHeader(name, t("chatServiceSub", "Chat about this service with your OBIC advisor"));
    } else {
      setHeader(t("accountChat", "Messages"), t("accountChatSub", "Chat with your OBIC advisor"));
    }
    return data;
  }

  async function openRoom(serviceKey, serviceName) {
    activeServiceKey = serviceKey || "";
    showError("");
    try {
      await ensureRoom(serviceKey || "", serviceName || "");
      await loadMessages();
      await loadThreads();
      if (pollTimer) clearInterval(pollTimer);
      pollTimer = setInterval(loadMessages, 8000);

      const q = new URLSearchParams(location.search);
      if (serviceKey) {
        const parts = serviceKey.split("/");
        q.set("service", parts[0] || serviceKey);
        if (parts[1]) q.set("item", parts[1]);
        else q.delete("item");
        if (serviceName) q.set("name", serviceName);
      } else {
        q.delete("service");
        q.delete("item");
        q.delete("name");
        q.delete("service_key");
        q.delete("category");
        q.delete("sub");
      }
      const next = q.toString() ? "/messages?" + q.toString() : "/messages";
      if (location.pathname + location.search !== next && (location.pathname === "/messages" || location.pathname === "/chat")) {
        history.replaceState(null, "", next);
      }
    } catch (_) {
      showError(t("chatUnavailable", "Chat is temporarily unavailable. Please try again later."));
    }
  }

  function bindForm() {
    const form = document.getElementById("chat-form");
    if (!form || form.dataset.bound) return;
    form.dataset.bound = "1";
    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      showError("");
      const input = document.getElementById("chat-input");
      const text = ((input && input.value) || "").trim();
      if (!text || !roomId) return;
      const btn = form.querySelector('button[type="submit"]');
      if (btn) btn.disabled = true;
      try {
        const token = await csrfToken();
        form.querySelector('input[name="_token"]').value = token;
        const fd = new FormData();
        fd.set("_token", token);
        fd.set("room_id", roomId);
        fd.set("message", text);
        fd.set("message_type", "text");
        const res = await fetch("/chat/send", {
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
        if (!res.ok || !(data && data.success)) {
          showError((data && (data.message || data.error)) || t("profileError", "Something went wrong."));
          return;
        }
        input.value = "";
        await loadMessages();
        await loadThreads();
      } catch (_) {
        showError(t("profileError", "Something went wrong."));
      } finally {
        if (btn) btn.disabled = false;
      }
    });
  }

  async function show(user) {
    const loading = document.getElementById("chat-loading");
    const guest = document.getElementById("chat-guest");
    const panel = document.getElementById("chat-panel");
    if (loading) loading.hidden = true;

    if (!user || !user.authenticated) {
      if (guest) guest.hidden = false;
      if (panel) panel.hidden = true;
      if (pollTimer) clearInterval(pollTimer);
      return;
    }

    myId = user.id;
    if (guest) guest.hidden = true;
    if (panel) panel.hidden = false;
    bindForm();

    const svc = serviceFromUrl();
    activeServiceKey = svc.key || "";
    if (svc.key && svc.name) {
      setHeader(svc.name, t("chatServiceSub", "Chat about this service with your OBIC advisor"));
    }
    await openRoom(svc.key, svc.name);
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
