// DOM helpers and ready hook
export function onReady(fn) {
  const run = () => { try { fn(); } catch(_) {} };
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', run);
  } else {
    run();
  }
  document.addEventListener('turbo:load', run);
  document.addEventListener('turbo:render', run);
  window.addEventListener('pageshow', run);
}

export function el(tag, attrs, children) {
  const e = document.createElement(tag);
  if (attrs) for (const k in attrs) {
    if (k === 'style' && typeof attrs[k] === 'object') {
      Object.assign(e.style, attrs[k]);
    } else if (k === 'class') {
      e.className = attrs[k];
    } else if (k.startsWith('on') && typeof attrs[k] === 'function') {
      e.addEventListener(k.slice(2), attrs[k]);
    } else {
      e.setAttribute(k, attrs[k]);
    }
  }
  (children || []).forEach(c => e.appendChild(typeof c === 'string' ? document.createTextNode(c) : c));
  return e;
}

export function jsonPretty(obj) {
  try { return JSON.stringify(obj, null, 2); } catch(_) { return String(obj); }
}
