const V = "hidayah-v2",
  SHELL = [
    "./",
    "index.html",
    "about.html",
    "courses.html",
    "login.html",
    "signup.html",
    "dashboard.html",
    "contact.html",
    "learn.html",
    "quiz.html",
    "teacher.html",
    "chat.html",
    "js/app.js",
    "offline.html",
    "css/style.css",
    "js/main.js",
    "js/supabase.js",
    "js/auth.js",
    "assets/logo.png",
    "icons/icon-192.png",
    "manifest.webmanifest",
  ];
self.addEventListener("install", (e) => {
  e.waitUntil(
    caches
      .open(V)
      .then((c) => c.addAll(SHELL))
      .then(() => self.skipWaiting()),
  );
});
self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches
      .keys()
      .then((k) =>
        Promise.all(k.filter((x) => x !== V).map((x) => caches.delete(x))),
      )
      .then(() => self.clients.claim()),
  );
});
self.addEventListener("fetch", (e) => {
  const r = e.request,
    u = new URL(r.url);
  if (r.method !== "GET") return;
  if (u.hostname.endsWith("supabase.co")) return; // never cache auth or data calls
  const cdn = /jsdelivr|googleapis|gstatic/.test(u.hostname);
  if (u.origin !== location.origin && !cdn) return;
  if (r.mode === "navigate") {
    // pages: network first, then cache, then offline page
    e.respondWith(
      fetch(r)
        .then((res) => {
          const c = res.clone();
          caches.open(V).then((x) => x.put(r, c));
          return res;
        })
        .catch(() =>
          caches.match(r).then((m) => m || caches.match("offline.html")),
        ),
    );
    return;
  }
  e.respondWith(
    caches.match(r).then((m) => {
      // assets: stale while revalidate
      const net = fetch(r)
        .then((res) => {
          if (res.ok || res.type === "opaque") {
            const c = res.clone();
            caches.open(V).then((x) => x.put(r, c));
          }
          return res;
        })
        .catch(() => m);
      return m || net;
    }),
  );
});
