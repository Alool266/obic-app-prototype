/**
 * OBIC website session — detect Laravel login and update nav / account page.
 */
(function (global) {
  const ME_URL = "/api/obic/me";

  async function fetchMe() {
    try {
      const res = await fetch(ME_URL, {
        credentials: "same-origin",
        headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
      });
      if (res.status === 401) return { authenticated: false };
      if (!res.ok) return { authenticated: false };
      return await res.json();
    } catch (_) {
      return { authenticated: false };
    }
  }

  function t(key, fallback) {
    try {
      if (global.ObicI18n && typeof global.ObicI18n.t === "function") {
        const v = global.ObicI18n.t(key);
        if (v && v !== key) return v;
      }
    } catch (_) {}
    return fallback;
  }

  function isStaff(user) {
    if (!user || !user.authenticated) return false;
    const role = String(user.role || "").toUpperCase();
    return role === "ADMIN" || role === "OWNER";
  }

  function accountHomeHref(user) {
    return isStaff(user) ? "/admin" : "/account";
  }

  function applyNav(user) {
    const actions = document.querySelectorAll(".nav-actions");
    actions.forEach((box) => {
      const login = box.querySelector(
        'a[href="/login"], a[href="/login.html"], a[href*="/login"]'
      );
      const register = box.querySelector(
        'a[href="/register"], a[href="/register.html"], a[href*="/register"]'
      );
      box.querySelectorAll("[data-obic-auth-dyn]").forEach((el) => el.remove());

      if (!user || !user.authenticated) {
        if (login) {
          login.hidden = false;
          login.style.display = "";
        }
        if (register) {
          register.hidden = false;
          register.style.display = "";
        }
        return;
      }

      if (login) {
        login.hidden = true;
        login.style.display = "none";
      }
      if (register) {
        register.hidden = true;
        register.style.display = "none";
      }

      const name = document.createElement("a");
      name.className = "btn btn-ghost";
      name.href = accountHomeHref(user);
      name.setAttribute("data-obic-auth-dyn", "1");
      name.textContent = isStaff(user)
        ? t("navAdmin", "Admin")
        : user.name || t("navAccount", "Account");

      const logout = document.createElement("a");
      logout.className = "btn btn-primary";
      logout.href = "/logout";
      logout.setAttribute("data-obic-auth-dyn", "1");
      logout.textContent = t("navLogout", "Logout");

      const menu = box.querySelector(".menu-toggle");
      if (menu) {
        box.insertBefore(name, menu);
        box.insertBefore(logout, menu);
      } else {
        box.appendChild(name);
        box.appendChild(logout);
      }
    });

    // Footer login → account (or admin desk) when signed in
    document.querySelectorAll('footer a[href="/login"], footer a[href="/login.html"]').forEach((a) => {
      if (!user || !user.authenticated) return;
      a.href = accountHomeHref(user);
      a.textContent = isStaff(user)
        ? t("navAdmin", "Admin")
        : user.name || t("navAccount", "Account");
      a.removeAttribute("data-i18n");
    });
  }

  function fillAccount(user) {
    const root = document.getElementById("account-root");
    if (!root) return;

    // Staff land on the operations desk, not the customer account page.
    if (isStaff(user)) {
      window.location.replace("/admin");
      return;
    }

    const loading = document.getElementById("account-loading");
    const guest = document.getElementById("account-guest");
    const panel = document.getElementById("account-panel");

    if (loading) loading.hidden = true;

    if (!user || !user.authenticated) {
      if (guest) guest.hidden = false;
      if (panel) panel.hidden = true;
      return;
    }

    if (guest) guest.hidden = true;
    if (panel) panel.hidden = false;

    const set = (id, val) => {
      const el = document.getElementById(id);
      if (el) el.textContent = val || "—";
    };
    set("account-name", user.name);
    set("account-email", user.email);
    set("account-phone", user.phone_display || user.phone);
    set("account-hello", user.name);

    const avatar = document.getElementById("account-avatar");
    if (avatar) {
      const initials = (user.name || "OB")
        .split(/\s+/)
        .filter(Boolean)
        .slice(0, 2)
        .map((p) => p[0].toUpperCase())
        .join("");
      avatar.textContent = initials || "OB";
    }
  }

  const userListeners = [];

  function notifyUser(user) {
    userListeners.forEach((fn) => {
      try {
        fn(user);
      } catch (_) {}
    });
  }

  async function init() {
    const user = await fetchMe();
    global.ObicSession = {
      user,
      refresh: init,
      onUser(fn) {
        if (typeof fn === "function") {
          userListeners.push(fn);
          fn(user);
        }
      },
    };
    applyNav(user);
    fillAccount(user);
    notifyUser(user);
  }

  document.addEventListener("DOMContentLoaded", init);
})(window);
