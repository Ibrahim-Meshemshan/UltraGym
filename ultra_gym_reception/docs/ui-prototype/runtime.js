/* UltraGym prototype runtime: renders design-canvas pages (x-dc templates) standalone. */
(function () {
  'use strict';
  var HOLE = /\{\{\s*([^}]+?)\s*\}\}/g;
  var Q = new URLSearchParams(location.search);
  function store(k, v) { try { if (v === undefined) return localStorage.getItem(k); localStorage.setItem(k, v); } catch (e) { return null; } }
  function lit(expr, scopes) {
    expr = expr.trim();
    if (expr === 'true') return true;
    if (expr === 'false') return false;
    if (/^-?\d+(\.\d+)?$/.test(expr)) return Number(expr);
    if (/^'.*'$/.test(expr)) return expr.slice(1, -1);
    var parts = expr.split('.');
    for (var i = scopes.length - 1; i >= 0; i--) {
      if (scopes[i] && Object.prototype.hasOwnProperty.call(scopes[i], parts[0])) {
        var v = scopes[i][parts[0]];
        for (var j = 1; j < parts.length && v != null; j++) v = v[parts[j]];
        return v;
      }
    }
    return undefined;
  }
  function interp(str, scopes) {
    return str.replace(HOLE, function (_, e) { var v = lit(e, scopes); return v == null ? '' : String(v); });
  }
  function whole(str) { var m = /^\s*\{\{\s*([^}]+?)\s*\}\}\s*$/.exec(str); return m ? m[1] : null; }

  function build(node, scopes, out) {
    if (node.nodeType === 3) { out.appendChild(document.createTextNode(node.nodeValue.indexOf('{{') < 0 ? node.nodeValue : interp(node.nodeValue, scopes))); return; }
    if (node.nodeType !== 1) return;
    if (node.tagName === 'TEMPLATE' && node.hasAttribute('data-for')) {
      var list = lit(whole(node.getAttribute('list')) || 'undefined', scopes) || [];
      var as = node.getAttribute('as') || 'item';
      for (var i = 0; i < list.length; i++) {
        var sc = {}; sc[as] = list[i];
        kids(node.content, scopes.concat([sc]), out);
      }
      return;
    }
    if (node.tagName === 'TEMPLATE' && node.hasAttribute('data-if')) {
      if (lit(whole(node.getAttribute('value')) || 'false', scopes)) kids(node.content, scopes, out);
      return;
    }
    var el = node.cloneNode(false);
    for (var a = node.attributes.length - 1; a >= 0; a--) {
      var at = node.attributes[a], name = at.name, val = at.value;
      if (name.indexOf('hint-placeholder') === 0) { el.removeAttribute(name); continue; }
      if (/^on/.test(name)) {
        var w = whole(val);
        el.removeAttribute(name);
        if (w) { var fn = lit(w, scopes); if (typeof fn === 'function') el.addEventListener(name.slice(2).toLowerCase(), fn); }
        continue;
      }
      if (val.indexOf('{{') >= 0) {
        var w2 = whole(val);
        if (w2 && (name === 'disabled' || name === 'checked' || name === 'readonly')) { if (lit(w2, scopes)) el.setAttribute(name, ''); else el.removeAttribute(name); continue; }
        el.setAttribute(name, interp(val, scopes));
      }
    }
    if (node.tagName === 'TEMPLATE') { el.content.appendChild(node.content.cloneNode(true)); out.appendChild(el); return; }
    kids(node, scopes, el);
    out.appendChild(el);
  }
  function kids(parent, scopes, out) { for (var c = parent.firstChild; c; c = c.nextSibling) build(c, scopes, out); }

  var src = document.getElementById('dc-src');
  var propsDef = JSON.parse(document.getElementById('dc-props').textContent || '{}');
  var logic = document.getElementById('dc-logic').textContent;
  var props = {};
  Object.keys(propsDef).forEach(function (k) { if (k !== '$preview' && propsDef[k] && 'default' in propsDef[k]) props[k] = propsDef[k].default; });
  if ('theme' in props) { var t = store('ug-theme'); if (t) props.theme = t; }
  Q.forEach(function (v, k) { if (k in props) props[k] = (v === 'true') ? true : (v === 'false') ? false : v; });
  var H = (location.hash || '').replace('#', '');
  if ('theme' in props && (H === 'dark' || H === 'light')) { props.theme = H; store('ug-theme', H); }

  var root = document.getElementById('dc-root');
  var comp;
  function DCLogic() {}
  DCLogic.prototype.setState = function (p) { this.state = Object.assign({}, this.state || {}, p); render(); };
  try {
    var Comp = new Function('DCLogic', logic + '\n;return typeof Component !== "undefined" ? Component : null;')(DCLogic);
    comp = Comp ? new Comp() : null;
  } catch (e) { console.error('logic error', e); comp = null; }
  if (comp) { comp.props = props; comp.state = {}; }
  function render() {
    var vals = {};
    try { vals = comp ? (comp.renderVals() || {}) : {}; } catch (e) { console.error('renderVals error', e); }
    var frag = document.createDocumentFragment();
    kids(src.content, [vals], frag);
    root.replaceChildren(frag);
    if (comp && comp.state && comp.state.__th) store('ug-theme', comp.state.__th);
  }
  render();
  document.addEventListener('submit', function (e) { e.preventDefault(); });
  document.addEventListener('click', function (e) { var a = e.target.closest && e.target.closest('a[href="#"]'); if (a) e.preventDefault(); });

  // State panel: every tweak of the page, to try states without editing.
  var keys = Object.keys(propsDef).filter(function (k) { return k !== '$preview'; });
  var btn = document.createElement('button');
  btn.type = 'button'; btn.className = 'ugp-fab'; btn.textContent = 'الحالات'; btn.setAttribute('aria-expanded', 'false');
  var panel = document.createElement('div');
  panel.className = 'ugp-panel'; panel.hidden = true; panel.setAttribute('role', 'dialog'); panel.setAttribute('aria-label', 'حالات الشاشة');
  var html = '<div class="ugp-h"><strong>حالات الشاشة</strong><a href="index.html">كل الشاشات</a></div>';
  if (!keys.length) html += '<p class="ugp-n">لا توجد حالات إضافية لهذه الشاشة.</p>';
  keys.forEach(function (k) {
    var d = propsDef[k], id = 'ugp-' + k, lab = (d.section || k);
    if (d.editor === 'enum') {
      html += '<label class="ugp-r" for="' + id + '"><span>' + lab + '</span><select id="' + id + '" data-k="' + k + '">' + d.options.map(function (o) { return '<option' + (String(props[k]) === String(o) ? ' selected' : '') + '>' + o + '</option>'; }).join('') + '</select></label>';
    } else if (d.editor === 'boolean') {
      html += '<label class="ugp-r" for="' + id + '"><span>' + lab + '</span><input type="checkbox" id="' + id + '" data-k="' + k + '"' + (props[k] ? ' checked' : '') + '></label>';
    }
  });
  panel.innerHTML = html;
  panel.addEventListener('change', function (e) {
    var k = e.target.getAttribute('data-k'); if (!k) return;
    props[k] = e.target.type === 'checkbox' ? e.target.checked : e.target.value;
    if (k === 'theme') store('ug-theme', props[k]);
    var keep = comp && comp.state && k !== 'theme' ? {} : {};
    if (comp) comp.state = keep;
    render();
  });
  btn.addEventListener('click', function () { panel.hidden = !panel.hidden; btn.setAttribute('aria-expanded', String(!panel.hidden)); });
  document.body.appendChild(btn); document.body.appendChild(panel);
})();
