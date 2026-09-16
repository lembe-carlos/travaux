// =============================================================================
// SAHEL BTP — Service Worker
// =============================================================================
// Rôle : permettre l'installation de l'application sur l'écran d'accueil du
// téléphone, et faire fonctionner l'interface même sans connexion (les
// données, elles, restent gérées par app.js : localStorage en mode local,
// ou synchronisation Supabase en mode connecté — ce service worker ne touche
// jamais à ces données, seulement aux fichiers de l'application elle-même).

const CACHE_NAME = "sahelbtp-shell-v1";
const APP_SHELL = [
  "./",
  "./index.html",
  "./style.css",
  "./app.js",
  "./config.js",
  "./manifest.json",
  "./icon-192.png",
  "./icon-512.png",
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);

  // Ne jamais intercepter les appels vers d'autres origines (Supabase, CDN
  // des bibliothèques, etc.) : ils doivent toujours passer par le réseau
  // normalement, avec leur propre gestion d'erreur déjà prévue dans app.js.
  if (url.origin !== self.location.origin) return;
  if (event.request.method !== "GET") return;

  event.respondWith(
    caches.match(event.request).then((cached) => {
      const network = fetch(event.request)
        .then((response) => {
          if (response && response.ok) {
            const copy = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
          }
          return response;
        })
        .catch(() => cached);
      // Affiche immédiatement la version en cache si elle existe (rapide,
      // fonctionne hors-ligne), tout en rafraîchissant en arrière-plan.
      return cached || network;
    })
  );
});
