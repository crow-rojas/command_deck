const KEY_PREFIX = 'command-deck-';

export const store = {
  get(key, fallback = null) {
    try {
      const v = localStorage.getItem(KEY_PREFIX + key);
      return v == null ? fallback : v;
    } catch(_) { return fallback; }
  },
  set(key, value) {
    try { localStorage.setItem(KEY_PREFIX + key, value); } catch(_) {}
  }
};
