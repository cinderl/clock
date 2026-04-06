/**
 * sw.js — Digital Clock Service Worker
 *
 * Strategy: cache-first with network fallback.
 * All app assets are pre-cached on install so the clock works
 * fully offline after the first load.
 *
 * Cache is versioned — bumping CACHE_NAME triggers the old cache
 * to be deleted and all assets to be re-fetched.
 */

const CACHE_NAME   = 'dclock-v1';
const CACHE_URLS   = [
  './digital-clock.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  // External font — cached on first fetch via the fetch handler below
  'https://fonts.cdnfonts.com/css/seven-segment',
];

/* ── Install: pre-cache all local assets ─────────────────────────── */
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(CACHE_URLS))
      .then(() => self.skipWaiting())   // Activate immediately
  );
});

/* ── Activate: delete stale caches ──────────────────────────────── */
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => key !== CACHE_NAME)
          .map((key) => caches.delete(key))
      )
    ).then(() => self.clients.claim())  // Take control of open pages
  );
});

/* ── Fetch: cache-first, fall back to network ────────────────────── */
self.addEventListener('fetch', (event) => {
  // Only handle GET requests
  if (event.request.method !== 'GET') return;

  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;

      // Not in cache — fetch from network and store for next time
      return fetch(event.request).then((response) => {
        // Only cache valid responses (not errors, not opaque cross-origin failures)
        if (!response || response.status !== 200) return response;

        const clone = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        return response;
      }).catch(() => {
        // Network failed and nothing in cache — nothing we can do
        return new Response('Offline', { status: 503 });
      });
    })
  );
});
