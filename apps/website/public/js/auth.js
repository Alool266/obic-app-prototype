(function () {
  /** CSRF must come from a Laravel HTML page (not our static /login). */
  async function fetchCsrf() {
    const candidates = ["/forgot-password", "/register", "/"];
    for (const url of candidates) {
      try {
        const res = await fetch(url, {
          credentials: "same-origin",
          headers: { Accept: "text/html" },
        });
        if (!res.ok) continue;
        const html = await res.text();
        const m =
          html.match(/name=["']_token["']\s+value=["']([^"']+)["']/i) ||
          html.match(/value=["']([^"']+)["']\s+name=["']_token["']/i) ||
          html.match(/csrf-token"\s+content="([^"]+)"/i);
        if (m && m[1] && m[1].length > 10) return m[1];
      } catch (_) {}
    }
    // XSRF-TOKEN cookie (Laravel)
    const row = document.cookie.split(";").map((s) => s.trim()).find((s) => s.startsWith("XSRF-TOKEN="));
    if (row) {
      try {
        return decodeURIComponent(row.slice("XSRF-TOKEN=".length));
      } catch (_) {}
    }
    return "";
  }

  async function applyTokens() {
    const token = await fetchCsrf();
    document.querySelectorAll('input[name="_token"]').forEach((el) => {
      el.value = token;
    });
    const err = document.getElementById("auth-error");
    if (!token && err) {
      const host = location.hostname;
      if (host === "obicgp.com" || host === "www.obicgp.com") {
        err.hidden = false;
        err.textContent = "Could not load security token. Refresh the page and try again.";
      } else {
        err.hidden = false;
        err.textContent =
          "Local preview: login submits to the live site after upload. Open https://obicgp.com/login when deployed.";
      }
    }
    return token;
  }

  function bindTabs() {
    const tabs = document.querySelectorAll(".auth-tabs button");
    const emailForm = document.getElementById("form-email");
    const phoneForm = document.getElementById("form-phone");
    if (!tabs.length || !emailForm || !phoneForm) return;

    tabs.forEach((btn) => {
      btn.addEventListener("click", () => {
        const tab = btn.dataset.tab;
        tabs.forEach((b) => {
          b.classList.toggle("is-on", b === btn);
          b.setAttribute("aria-selected", b === btn ? "true" : "false");
        });
        emailForm.hidden = tab !== "email";
        phoneForm.hidden = tab !== "phone";
      });
    });
  }

  function showError(msg) {
    const err = document.getElementById("auth-error");
    if (!err) return;
    err.hidden = !msg;
    err.textContent = msg || "";
  }

  function firstError(payload) {
    if (!payload) return "Something went wrong. Please try again.";
    if (payload.message) return payload.message;
    if (payload.errors) {
      const vals = Object.values(payload.errors);
      if (vals.length) {
        const first = vals[0];
        return Array.isArray(first) ? first[0] : String(first);
      }
    }
    return "Something went wrong. Please try again.";
  }

  function bindAjaxForms() {
    const forms = [
      document.getElementById("form-email"),
      document.getElementById("form-phone"),
      document.getElementById("form-register"),
    ].filter(Boolean);

    forms.forEach((form) => {
      form.addEventListener("submit", async (e) => {
        e.preventDefault();
        showError("");
        const btn = form.querySelector('button[type="submit"]');
        if (btn) btn.disabled = true;

        try {
          let token = form.querySelector('input[name="_token"]')?.value || "";
          if (!token) token = await applyTokens();

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
          if (ct.includes("application/json")) {
            data = await res.json();
          }

          if (res.ok && data && data.ok && data.redirect) {
            location.href = data.redirect;
            return;
          }

          if (res.status === 422 || (data && data.ok === false)) {
            showError(firstError(data));
            return;
          }

          // Fallback: non-JSON success redirect body
          if (res.redirected && res.url) {
            location.href = res.url;
            return;
          }

          showError(firstError(data) || "Could not continue. Please try again.");
        } catch (_) {
          showError("Network error. Please try again.");
        } finally {
          if (btn) btn.disabled = false;
        }
      });
    });
  }

  document.addEventListener("DOMContentLoaded", () => {
    bindTabs();
    applyTokens();
    bindAjaxForms();

    const params = new URLSearchParams(location.search);
    if (params.get("registered") === "1") {
      showError("");
      const err = document.getElementById("auth-error");
      if (err) {
        err.hidden = false;
        err.classList.add("auth-ok");
        err.textContent = "Registration successful. You can sign in now.";
      }
    }
  });
})();
