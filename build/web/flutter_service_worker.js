'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".vercel/project.json": "c02f0082e75acc1e228caa7e74f44d99",
".vercel/README.txt": "2b13c79d37d6ed82a3255b83b6815034",
"akaricon.ico": "4e26f76ca5d50e031c7d0ca6e0c2e0e8",
"assets/AssetManifest.bin": "b32c86a254dd9fadbf66e45f2e64b938",
"assets/AssetManifest.bin.json": "58f77bfce690522b05bef77bc8c9956a",
"assets/assets/fonts/MaterialIcons-Regular.otf": "e9f8caaded65b9becdf625b25dd07438",
"assets/assets/fonts/OpenSans-Bold.ttf": "0a191f83602623628320f3d3c667a276",
"assets/assets/fonts/OpenSans-BoldItalic.ttf": "3dc8fca5496b8d2ad16a9800cc8c2883",
"assets/assets/fonts/OpenSans-ExtraBold.ttf": "f0af8434e183f500acf62135a577c739",
"assets/assets/fonts/OpenSans-ExtraBoldItalic.ttf": "ae6ca7d3e0ab887a9d9731508592303a",
"assets/assets/fonts/OpenSans-Italic-VariableFont_wdth,wght.ttf": "31d95e96058490552ea28f732456d002",
"assets/assets/fonts/OpenSans-Italic.ttf": "60fdf6ed7b4901c1ff534577a68d9c0c",
"assets/assets/fonts/OpenSans-Light.ttf": "c87e3b21e46c872774d041a71e181e61",
"assets/assets/fonts/OpenSans-LightItalic.ttf": "07f95dc31e4f5c166051e95f554a8dff",
"assets/assets/fonts/OpenSans-Medium.ttf": "dac0e601db6e3601159b4aae5c1fda39",
"assets/assets/fonts/OpenSans-MediumItalic.ttf": "349744a1905053fad6b9ef13c74657db",
"assets/assets/fonts/OpenSans-Regular.ttf": "931aebd37b54b3e5df2fedfce1432d52",
"assets/assets/fonts/OpenSans-SemiBold.ttf": "e2ca235bf1ddc5b7a350199cf818c9c8",
"assets/assets/fonts/OpenSans-SemiBoldItalic.ttf": "223ce0be939cafef0fb807eb0ea8d7de",
"assets/assets/fonts/OpenSans-VariableFont_wdth,wght.ttf": "78609089d3dad36318ae0190321e6f3e",
"assets/assets/fonts/OpenSans_Condensed-Bold.ttf": "5df2bb0a5dc244b8fe88ba3eb3ff3eda",
"assets/assets/fonts/OpenSans_Condensed-BoldItalic.ttf": "9fa8f9e4df5aca8b0e10f589a91793a2",
"assets/assets/fonts/OpenSans_Condensed-ExtraBold.ttf": "10af970680f2d4b8a8414e8eedcf3605",
"assets/assets/fonts/OpenSans_Condensed-ExtraBoldItalic.ttf": "b4b3789f2bc95af95536cb7f7f3ec1ed",
"assets/assets/fonts/OpenSans_Condensed-Italic.ttf": "1bdd899fc93c5247e68103da20b7b26c",
"assets/assets/fonts/OpenSans_Condensed-Light.ttf": "73e3f737e5e416273389662092a666b1",
"assets/assets/fonts/OpenSans_Condensed-LightItalic.ttf": "cd015954b9609b30486bf93dcf0ff213",
"assets/assets/fonts/OpenSans_Condensed-Medium.ttf": "70e41d5efaae749f6aaa68561da7f1b1",
"assets/assets/fonts/OpenSans_Condensed-MediumItalic.ttf": "a684f4bc4e3d33d11a40b2f101399da6",
"assets/assets/fonts/OpenSans_Condensed-Regular.ttf": "78b69821a6c0cc6fdcd1f4c3bb768fb7",
"assets/assets/fonts/OpenSans_Condensed-SemiBold.ttf": "2d70d77113ff88765d4a2e3e9ad8a9d9",
"assets/assets/fonts/OpenSans_Condensed-SemiBoldItalic.ttf": "ad76c64801d7b1b8375adf4b535c9f06",
"assets/assets/fonts/OpenSans_SemiCondensed-Bold.ttf": "f2a40b2ae2605e847aa935b7567688cd",
"assets/assets/fonts/OpenSans_SemiCondensed-BoldItalic.ttf": "e6db506e680bd887710b918b762f64f9",
"assets/assets/fonts/OpenSans_SemiCondensed-ExtraBold.ttf": "58788af3238842a6438278ff581124ca",
"assets/assets/fonts/OpenSans_SemiCondensed-ExtraBoldItalic.ttf": "8b3d3e856f6be6295e17e8539182084c",
"assets/assets/fonts/OpenSans_SemiCondensed-Italic.ttf": "4f1cb41e14ba244ac1ddd0208e3bd4a6",
"assets/assets/fonts/OpenSans_SemiCondensed-Light.ttf": "158d178df4e3f63ac7cf7a151a855e1e",
"assets/assets/fonts/OpenSans_SemiCondensed-LightItalic.ttf": "c2b7941c139fe149a4766fbf3d42d997",
"assets/assets/fonts/OpenSans_SemiCondensed-Medium.ttf": "7c51e9756da66db9f515c8bb5ea9920f",
"assets/assets/fonts/OpenSans_SemiCondensed-MediumItalic.ttf": "c24586aed8015d848dbf63cf0d412208",
"assets/assets/fonts/OpenSans_SemiCondensed-Regular.ttf": "a4524de69e40328e8bbaae81c74cf87e",
"assets/assets/fonts/OpenSans_SemiCondensed-SemiBold.ttf": "4e5cd43941bf45121d159dc4493a9c4a",
"assets/assets/fonts/OpenSans_SemiCondensed-SemiBoldItalic.ttf": "92ba379a002c359ddd247eb1c32cce00",
"assets/assets/texpilot_icon.png": "948e2413d7d72066859491a4cf236702",
"assets/FontManifest.json": "dc31df05984682cba0a4f5be4eb65892",
"assets/fonts/MaterialIcons-Regular.otf": "e9f8caaded65b9becdf625b25dd07438",
"assets/NOTICES": "e0ab2dc425b5279df91ae4c159167cf8",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/window_manager/images/ic_chrome_close.png": "75f4b8ab3608a05461a31fc18d6b47c2",
"assets/packages/window_manager/images/ic_chrome_maximize.png": "af7499d7657c8b69d23b85156b60298c",
"assets/packages/window_manager/images/ic_chrome_minimize.png": "4282cd84cb36edf2efb950ad9269ca62",
"assets/packages/window_manager/images/ic_chrome_unmaximize.png": "4a90c1909cb74e8f0d35794e2f61d8bf",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "13f68bfcb3f52c4ba42c2d975c3e487b",
"favicon.svg": "eb168e80ed7f9f675782960a7137b642",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "cfacd2bdca77972cb9464df1d5bd7f21",
"icons/Icon-192.png": "be8a6bea9be3639c5cbfb0e3e28d3add",
"icons/Icon-512.png": "913df617e50ed97440ee54d7a7484f4d",
"icons/Icon-maskable-192.png": "97bd851bd27a7692ef565722dfea5567",
"icons/Icon-maskable-512.png": "a04cbd6bfd5a7926f7fed4de4d81afdf",
"index.html": "20a6ca2e947ff9b78c062875a21ebb22",
"/": "20a6ca2e947ff9b78c062875a21ebb22",
"main.dart.js": "c27ab73cd0a868ed151fe2c984121355",
"manifest.json": "e4048ec44c17cf895dafcabff92803c9",
"vercel.json": "ae85aeb78deb0cae58146a0d86b11ed2",
"version.json": "3f37dfee0382c521a1406fbec4d20c35"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
