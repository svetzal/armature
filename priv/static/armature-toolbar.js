/*
 * Armature toolbar hook: one tab stop and arrow-key movement for
 * Armature.Components.Molecules.toolbar/1, following the ARIA toolbar pattern.
 *
 * Register it in your LiveSocket under the name the markup uses:
 *
 *   import ArmatureToolbar from "../../deps/armature/priv/static/armature-toolbar.js";
 *   let liveSocket = new LiveSocket("/live", Socket, {
 *     hooks: { ArmatureToolbar },
 *     params: { _csrf_token: csrfToken },
 *   });
 *
 * The toolbar's markup works without it: every control is a native element
 * reachable with Tab. When the hook mounts it gives the controls a roving
 * tabindex, so the toolbar is one tab stop. The arrow keys along the
 * toolbar's aria-orientation move between enabled controls and wrap; Home and
 * End go to the first and last. Natively disabled controls cannot take focus
 * and are skipped; controls marked only aria-disabled stay reachable, as the
 * pattern allows. Keys typed into a text field, select or radio keep their
 * native meaning.
 *
 * A LiveView patch can replace or reset the controls, so the hook applies the
 * roving tabindex again after every update. It keeps the control that last
 * had focus as the tab stop while that control is still present and enabled.
 *
 * It has no dependencies, no inline script, no eval and sets no inline
 * styles, so it runs under a strict content security policy.
 */

var CONTROLS = "a[href], button, input, select, textarea, [tabindex]";
var NATIVE_KEYS = "input:not([type=button]):not([type=checkbox]):not([type=reset]):not([type=submit]), select, textarea, [contenteditable]";
var NEXT = { horizontal: "ArrowRight", vertical: "ArrowDown" };
var PREVIOUS = { horizontal: "ArrowLeft", vertical: "ArrowUp" };

function orientation(toolbar) {
  return toolbar.getAttribute("aria-orientation") === "vertical" ? "vertical" : "horizontal";
}

// Separators and groups are not controls. A control that is disabled or not
// rendered cannot take focus, so it never becomes the tab stop.
function controls(toolbar) {
  return Array.prototype.filter.call(toolbar.querySelectorAll(CONTROLS), function (control) {
    return !control.disabled && control.getClientRects().length > 0;
  });
}

function rove(hook, chosen) {
  var items = controls(hook.el);
  var stop = items.indexOf(chosen) !== -1 ? chosen : items[0];

  items.forEach(function (control) {
    control.setAttribute("tabindex", control === stop ? "0" : "-1");
  });

  hook.stop = stop || null;
}

function move(hook, target) {
  rove(hook, target);
  target.focus();
}

function onKeydown(hook, event) {
  if (event.altKey || event.ctrlKey || event.metaKey) return;
  if (event.target.closest(NATIVE_KEYS)) return;

  var items = controls(hook.el);
  var index = items.indexOf(event.target);
  if (index === -1) return;

  var axis = orientation(hook.el);
  var target;

  if (event.key === NEXT[axis]) {
    target = items[(index + 1) % items.length];
  } else if (event.key === PREVIOUS[axis]) {
    target = items[(index - 1 + items.length) % items.length];
  } else if (event.key === "Home") {
    target = items[0];
  } else if (event.key === "End") {
    target = items[items.length - 1];
  } else {
    return;
  }

  event.preventDefault();
  move(hook, target);
}

var ArmatureToolbar = {
  mounted: function () {
    var hook = this;

    hook.el.addEventListener("keydown", function (event) {
      onKeydown(hook, event);
    });

    // Focus that arrives by pointer or script also moves the tab stop, so
    // Tab returns to the control the person last used.
    hook.el.addEventListener("focusin", function (event) {
      if (controls(hook.el).indexOf(event.target) !== -1) rove(hook, event.target);
    });

    rove(hook, null);
  },

  updated: function () {
    rove(this, this.stop);
  },
};

export default ArmatureToolbar;
