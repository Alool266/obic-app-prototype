/**
 * OBIC profile page — load session user, tabs, save via Laravel JSON APIs.
 */
(function () {
  async function csrfToken() {
    const candidates = ["/forgot-password", "/account", "/"];
    for (const url of candidates) {
      try {
        const res = await fetch(url, { credentials: "same-origin", headers: { Accept: "text/html" } });
        if (!res.ok) continue;
        const html = await res.text();
        const m =
          html.match(/name=["']_token["']\s+value=["']([^"']+)["']/i) ||
          html.match(/value=["']([^"']+)["']\s+name=["']_token["']/i) ||
          html.match(/csrf-token"\s+content="([^"]+)"/i);
        if (m && m[1] && m[1].length > 10) return m[1];
      } catch (_) {}
    }
    const row = document.cookie.split(";").map((s) => s.trim()).find((s) => s.startsWith("XSRF-TOKEN="));
    if (row) {
      try {
        return decodeURIComponent(row.slice("XSRF-TOKEN=".length));
      } catch (_) {}
    }
    return "";
  }

  function t(key, fallback) {
    try {
      if (window.ObicI18n && typeof window.ObicI18n.t === "function") {
        const v = window.ObicI18n.t(key);
        if (v && v !== key) return v;
      }
    } catch (_) {}
    return fallback;
  }

  function flash(msg, ok) {
    const el = document.getElementById("profile-flash");
    if (!el) return;
    if (!msg) {
      el.hidden = true;
      el.textContent = "";
      return;
    }
    el.hidden = false;
    el.textContent = msg;
    el.classList.toggle("is-ok", !!ok);
    el.classList.toggle("is-err", !ok);
  }

  function firstError(data) {
    if (!data) return t("profileError", "Something went wrong.");
    if (data.message) return data.message;
    if (data.errors) {
      const vals = Object.values(data.errors);
      if (vals.length) {
        const first = vals[0];
        return Array.isArray(first) ? first[0] : String(first);
      }
    }
    return t("profileError", "Something went wrong.");
  }

  function initials(name) {
    return (name || "OB")
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((p) => p[0].toUpperCase())
      .join("") || "OB";
  }

  function setAvatar(user) {
    const box = document.getElementById("profile-avatar");
    const img = document.getElementById("profile-avatar-img");
    const initialsEl = document.getElementById("profile-avatar-initials");
    const removeBtn = document.getElementById("btn-delete-photo");
    if (!box || !img) return;

    const label = initials(user.name);
    if (initialsEl) initialsEl.textContent = label;

    if (user.photo_url) {
      img.src = user.photo_url;
      img.hidden = false;
      box.classList.add("has-photo");
      if (removeBtn) removeBtn.hidden = false;
    } else {
      img.hidden = true;
      img.removeAttribute("src");
      box.classList.remove("has-photo");
      if (removeBtn) removeBtn.hidden = true;
    }
  }

  function fillForm(user) {
    const setVal = (id, v) => {
      const el = document.getElementById(id);
      if (el) el.value = v || "";
    };
    setVal("pf-name", user.name);
    setVal("pf-email", user.email);
    setVal("pf-phone", user.phone);
    setVal("pf-passport", user.passport_number);
    setVal("pf-address", user.address);
    const hello = document.getElementById("profile-hello");
    const sub = document.getElementById("profile-sub-email");
    const status = document.getElementById("profile-status");
    const role = document.getElementById("profile-role");
    const statusText = document.getElementById("profile-status-text");
    if (hello) hello.textContent = user.name || "—";
    if (sub) sub.textContent = user.email || user.phone_display || "—";
    if (status) status.textContent = user.status || "—";
    if (role) role.textContent = user.role || "—";
    if (statusText) statusText.textContent = user.status || "—";
    setAvatar(user);
    const country = document.getElementById("pf-country");
    if (country && user.country_id != null) country.value = String(user.country_id);
  }

  async function loadCountries(selectedId) {
    const select = document.getElementById("pf-country");
    if (!select) return;
    try {
      const res = await fetch("/api/obic/countries", {
        credentials: "same-origin",
        headers: { Accept: "application/json" },
      });
      if (!res.ok) return;
      const data = await res.json();
      const pick = select.querySelector("option[value='']");
      select.innerHTML = "";
      const opt0 = document.createElement("option");
      opt0.value = "";
      opt0.textContent = t("profileCountryPick", "Select country");
      select.appendChild(opt0);
      (data.items || []).forEach((c) => {
        const o = document.createElement("option");
        o.value = String(c.id);
        o.textContent = c.name;
        select.appendChild(o);
      });
      if (selectedId != null && selectedId !== "") select.value = String(selectedId);
      if (pick) {/* noop */}
    } catch (_) {}
  }

  function bindTabs() {
    const tabs = document.querySelectorAll(".profile-tabs button");
    const panes = {
      info: document.getElementById("pane-info"),
      password: document.getElementById("pane-password"),
      settings: document.getElementById("pane-settings"),
    };
    tabs.forEach((btn) => {
      btn.addEventListener("click", () => {
        const tab = btn.dataset.tab;
        tabs.forEach((b) => {
          b.classList.toggle("is-on", b === btn);
          b.setAttribute("aria-selected", b === btn ? "true" : "false");
        });
        Object.keys(panes).forEach((k) => {
          if (!panes[k]) return;
          const on = k === tab;
          panes[k].hidden = !on;
          panes[k].classList.toggle("is-on", on);
        });
      });
    });
  }

  async function postForm(form) {
    const token = form.querySelector('input[name="_token"]')?.value || (await csrfToken());
    document.querySelectorAll('input[name="_token"]').forEach((el) => {
      el.value = token;
    });
    const fd = new FormData(form);
    if (token) fd.set("_token", token);
    const res = await fetch(form.action, {
      method: "POST",
      body: fd,
      credentials: "same-origin",
      headers: {
        Accept: "application/json",
        "X-Requested-With": "XMLHttpRequest",
        "X-XSRF-TOKEN": token,
      },
    });
    let data = null;
    const ct = res.headers.get("content-type") || "";
    if (ct.includes("application/json")) data = await res.json();
    return { res, data };
  }

  function bindForms() {
    const profileForm = document.getElementById("form-profile");
    const passwordForm = document.getElementById("form-password");
    const deleteForm = document.getElementById("form-delete");

    if (profileForm) {
      profileForm.addEventListener("submit", async (e) => {
        e.preventDefault();
        flash("");
        const btn = profileForm.querySelector('button[type="submit"]');
        if (btn) btn.disabled = true;
        try {
          const { res, data } = await postForm(profileForm);
          if (res.ok && data && data.ok) {
            flash(data.message || t("profileSaved", "Profile updated."), true);
            if (window.ObicSession && window.ObicSession.refresh) await window.ObicSession.refresh();
            const me = window.ObicSession && window.ObicSession.user;
            if (me && me.authenticated) fillForm(me);
          } else {
            flash(firstError(data), false);
          }
        } catch (_) {
          flash(t("profileError", "Something went wrong."), false);
        } finally {
          if (btn) btn.disabled = false;
        }
      });
    }

    if (passwordForm) {
      passwordForm.addEventListener("submit", async (e) => {
        e.preventDefault();
        flash("");
        const btn = passwordForm.querySelector('button[type="submit"]');
        if (btn) btn.disabled = true;
        try {
          const { res, data } = await postForm(passwordForm);
          if (res.ok && data && data.ok) {
            flash(data.message || t("profilePasswordSaved", "Password updated."), true);
            passwordForm.reset();
          } else {
            flash(firstError(data), false);
          }
        } catch (_) {
          flash(t("profileError", "Something went wrong."), false);
        } finally {
          if (btn) btn.disabled = false;
        }
      });
    }

    if (deleteForm) {
      deleteForm.addEventListener("submit", async (e) => {
        e.preventDefault();
        const ok = window.confirm(t("profileDeleteConfirmAsk", "Delete your account permanently?"));
        if (!ok) return;
        flash("");
        try {
          const { res, data } = await postForm(deleteForm);
          if (res.ok && data && data.ok) {
            location.href = data.redirect || "/";
            return;
          }
          flash(firstError(data), false);
        } catch (_) {
          flash(t("profileError", "Something went wrong."), false);
        }
      });
    }

    const photoInput = document.getElementById("profile-photo-input");
    if (photoInput) {
      photoInput.addEventListener("change", async () => {
        if (!photoInput.files || !photoInput.files[0]) return;
        flash("");
        const token = await csrfToken();
        const fd = new FormData();
        fd.set("_token", token);
        fd.set("photo", photoInput.files[0]);
        try {
          const res = await fetch("/profile/update-photo", {
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
          if (res.ok && data && data.ok) {
            flash(data.message || t("profilePhotoSaved", "Photo updated."), true);
            if (window.ObicSession && window.ObicSession.refresh) await window.ObicSession.refresh();
            const me = window.ObicSession && window.ObicSession.user;
            if (me && me.authenticated) fillForm(me);
            else if (data.photo_url) setAvatar({ photo_url: data.photo_url, name: document.getElementById("profile-hello")?.textContent });
          } else {
            flash(firstError(data), false);
          }
        } catch (_) {
          flash(t("profileError", "Something went wrong."), false);
        } finally {
          photoInput.value = "";
        }
      });
    }

    const removePhoto = document.getElementById("btn-delete-photo");
    if (removePhoto) {
      removePhoto.addEventListener("click", async () => {
        if (!window.confirm(t("profileRemovePhotoAsk", "Remove profile photo?"))) return;
        const token = await csrfToken();
        const fd = new FormData();
        fd.set("_token", token);
        fd.set("_method", "DELETE");
        try {
          const res = await fetch("/profile/delete-photo", {
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
          if (res.ok && data && data.ok) {
            flash(data.message || t("profilePhotoRemoved", "Photo removed."), true);
            if (window.ObicSession && window.ObicSession.refresh) await window.ObicSession.refresh();
            const me = window.ObicSession && window.ObicSession.user;
            if (me && me.authenticated) fillForm(me);
          } else {
            flash(firstError(data), false);
          }
        } catch (_) {
          flash(t("profileError", "Something went wrong."), false);
        }
      });
    }
  }

  async function showProfile(user) {
    const loading = document.getElementById("profile-loading");
    const guest = document.getElementById("profile-guest");
    const panel = document.getElementById("profile-panel");
    if (!panel) return;

    if (loading) loading.hidden = true;

    if (!user || !user.authenticated) {
      if (guest) guest.hidden = false;
      panel.hidden = true;
      return;
    }

    if (guest) guest.hidden = true;
    panel.hidden = false;

    const token = await csrfToken();
    document.querySelectorAll('input[name="_token"]').forEach((el) => {
      el.value = token;
    });

    await loadCountries(user.country_id);
    fillForm(user);
  }

  let bound = false;
  function ensureBound() {
    if (bound) return;
    bound = true;
    bindTabs();
    bindForms();
  }

  async function initProfile() {
    const run = async (user) => {
      ensureBound();
      await showProfile(user);
    };

    if (window.ObicSession && typeof window.ObicSession.onUser === "function") {
      window.ObicSession.onUser(run);
      return;
    }

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
  }

  document.addEventListener("DOMContentLoaded", initProfile);
})();
