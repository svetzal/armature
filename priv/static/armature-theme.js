/*
 * Armature theme switch for pages rendered without a LiveView socket.
 *
 * Load this file from your own origin, for example in the root layout's head:
 *   <script src="/armature/armature-theme.js"></script>
 * Loaded in the head, it restores a remembered theme before the page paints.
 *
 * It works under a strict content security policy (script-src 'self'): it has
 * no inline script, no eval and sets no inline styles. It enhances every
 * Armature theme switch outside a LiveView. A switch inside a LiveView belongs
 * to the server, which receives its event and applies the theme itself.
 *
 * Light and Dark set data-armature-theme on the document element. Auto
 * removes the attribute; there is no "auto" value.
 */
(function () {
  "use strict";

  var ATTRIBUTE = "data-armature-theme";
  var STORAGE_KEY = "armature-theme";
  var EXPLICIT = ["light", "dark"];
  var root = document.documentElement;

  function explicit(theme) {
    return EXPLICIT.indexOf(theme) !== -1;
  }

  function remembered() {
    try {
      var theme = window.localStorage.getItem(STORAGE_KEY);
      return explicit(theme) ? theme : null;
    } catch (_error) {
      return null;
    }
  }

  function remember(theme) {
    try {
      if (explicit(theme)) {
        window.localStorage.setItem(STORAGE_KEY, theme);
      } else {
        window.localStorage.removeItem(STORAGE_KEY);
      }
    } catch (_error) {
      // Storage is unavailable or full; the choice lasts for this page only.
    }
  }

  function apply(theme) {
    if (explicit(theme)) {
      root.setAttribute(ATTRIBUTE, theme);
    } else {
      root.removeAttribute(ATTRIBUTE);
    }
  }

  function current() {
    var theme = root.getAttribute(ATTRIBUTE);
    return explicit(theme) ? theme : "auto";
  }

  function choicesOf(form) {
    return form.querySelectorAll("input[type='radio'][name='theme']");
  }

  function chosen(form) {
    return form.querySelector("input[type='radio'][name='theme']:checked");
  }

  function check(form, theme) {
    Array.prototype.forEach.call(choicesOf(form), function (radio) {
      radio.checked = radio.value === theme;
    });
  }

  function unmanagedSwitches() {
    var forms = document.querySelectorAll("form[data-armature-theme-switch]");
    return Array.prototype.filter.call(forms, function (form) {
      return form.closest("[data-phx-session]") === null && choicesOf(form).length > 0;
    });
  }

  // A live region must exist before its text changes, or nothing is announced.
  function statusOf(form) {
    var status = form.querySelector("[data-armature-theme-status]");

    if (status === null) {
      status = document.createElement("p");
      status.className = "armature-sr-only";
      status.setAttribute("role", "status");
      status.setAttribute("data-armature-theme-status", "");
      form.appendChild(status);
    }

    return status;
  }

  function words(element) {
    return element ? element.textContent.replace(/\s+/g, " ").trim() : "";
  }

  // Built from the switch's own legend and the chosen radio's label, so it
  // reads in the page's language: "Theme: Dark".
  function announce(form, radio) {
    var legend = words(form.querySelector("legend"));
    var name = words(radio.labels && radio.labels[0]) || radio.value;
    statusOf(form).textContent = legend ? legend + ": " + name : name;
  }

  function choose(form) {
    var radio = chosen(form);
    if (radio === null) return;

    apply(radio.value);
    remember(radio.value);

    unmanagedSwitches().forEach(function (other) {
      if (other !== form) check(other, current());
    });

    announce(form, radio);
  }

  function enhance() {
    var theme = current();

    unmanagedSwitches().forEach(function (form) {
      if (form.hasAttribute("data-armature-theme-enhanced")) return;
      form.setAttribute("data-armature-theme-enhanced", "");

      check(form, theme);
      statusOf(form);

      form.addEventListener("change", function (event) {
        if (event.target.name === "theme") choose(form);
      });

      form.addEventListener("submit", function (event) {
        event.preventDefault();
        choose(form);
      });
    });
  }

  // A theme the server rendered on the document element wins over a
  // remembered one.
  if (!root.hasAttribute(ATTRIBUTE)) {
    var theme = remembered();
    if (theme) apply(theme);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", enhance);
  } else {
    enhance();
  }
})();
