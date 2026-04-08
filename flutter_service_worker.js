'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "ba1fae5e2dcbe6ef7f1ed84eb0368bc2",
".git/config": "5bfb9cae5994970f64e1786d484cab93",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "38ce1ec390d51aa9825784ed31c69bac",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "65d19c40b2fe6d54157d15f0f89fbf1a",
".git/logs/refs/heads/main": "57bb0ef251d664960a88fb8527ecdaea",
".git/logs/refs/remotes/origin/main": "18c97415af2abf8a612fd840a1224a7f",
".git/objects/03/9365088015c9aee7c784befc03f39a79a3a2f4": "48093db7b13b65abada38e991d527012",
".git/objects/05/534b43693dcb6e9046de97b68d446ca86a90ef": "0203d28ae9dfb7fa310bb6f2f9caa56c",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/0a/0683ca01f4cc0d9cd53ec27a8fae910af70218": "dca13214bd5e96482d2f73ffc756c1ea",
".git/objects/19/49491fe9516a8989f036896a3e154583671459": "c597fc5e3d4267aa11ceba8cade49846",
".git/objects/1b/b9d2f3a16674471fcd7a10f4e429961cd33e5a": "fa269b38444b165d9ef907e80c486659",
".git/objects/1c/b6375b7adecfacc3187ceb7049df089ded26d7": "96043ae940dd518fa1880c33ed3b1671",
".git/objects/1e/727aefc44c39e1197960ea9579a496dc469929": "f822872fb8623c94de480b45c918a3e8",
".git/objects/20/46d6bcf448323fa44b373a6fd654ce8a4b8195": "20ef9e80c8ecabfb96b67aeda78e4bf7",
".git/objects/23/3dd1841f91c5c70856a2e23155df8837c665b8": "fb17e4fa65b12b314fb331437f5f1204",
".git/objects/25/b1aadf0ef99ac11b2441400255517751cd49e9": "6adbb9302207b2fb785c2e1f8491aa72",
".git/objects/29/ff69386f7b74fe24f0cc85dea86771f5b7dc47": "b1cbabcfdd56e7e921a53fb7de937817",
".git/objects/38/74205d6dab7c437dd730a0e992b155ea7ed7b5": "47fe8a4c7da80491e616ed31a194f488",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/3d/841af4581a352c5795c26c1e233366794113ba": "e5cdb95421714e9e6cc65fd9025301d7",
".git/objects/3d/9d660537887e0470d40cdd788edf7638813673": "03b22d07fbc90ed22da341acacadc943",
".git/objects/3e/600b9ae9e877c0df3aeff6bd4e5ceaae9e6852": "71a132ebf8c0061fe057a64e60726d3d",
".git/objects/3f/8ae0fb5ab49d2f635f4fdedcd82b50e55cb377": "f2fb4fc4a0cba0a4aae3417aa8765feb",
".git/objects/42/8386abf6e5eb8e35162ce5ec02c2a92534a72e": "87b15c05a14a73415b1dbc1221db01c4",
".git/objects/44/92f26ab1efeaee23822c9a697ce537627c7212": "b623f2159654a048d3bf38171a15b856",
".git/objects/45/9be7b425037e890ed948954cf8078263c04c21": "1a118cba681bf65073e243819f22fd64",
".git/objects/48/b3a467b9eabb8bca14e89c7d90de7d1b6ac164": "1d38eaab9a671cd3ae82c51c6d5f8e96",
".git/objects/49/4f48035ac0e7c89ff4fca7afe5a8d14aa1b2ae": "54f14c3a6bf7629727a0b26542dbda1e",
".git/objects/4a/0c5c1038eecb9794655b457ab55e65d55fb264": "3b6dfb116c8a0992d38e0ad0605a19a9",
".git/objects/4e/b3393528e2fa37ea5d59d9406f8717c808bd9c": "2a332062f204f30c284afe849c3379b4",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/52/5397da6adfe9d97aac5370e505bc53d7a6dbc3": "792362e9c427ddbad3e37d691ad0db62",
".git/objects/52/b8f4edcd552daad699bb6c3dd51a16268302ba": "1a59bb6f149e6e4da08e73bee2e69cec",
".git/objects/59/36496a3c0f1d93e94e499c064a088f1a287120": "d64eaf1c5b4714c87c2ef703aafa4717",
".git/objects/5a/1e82cbe4a9346ced3cc484a47432e1517bd301": "3f0ca241492383944b5d8b44e9191fc2",
".git/objects/5b/09b35bc1f088db879c950be995530db28b52cb": "6196cd0565d9604a0f121a81a9ecbd29",
".git/objects/5f/05d08e4dbe5266f396c553493979efc5893755": "9082d28596d3152ae4973887361ba0cc",
".git/objects/62/0ba741bddb52f505862ff613e2afca11b6090d": "82a70804484630aecaf90403e2246e91",
".git/objects/67/2e9e49d2f0c4c8aa44b496beb98f32cb36720e": "8b66be9a4797f8f3922fb5816494c68e",
".git/objects/67/803bb642742643c9525b6d25b8ade89383232c": "5d40c4c7976f38c9b005ca506909bdbd",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6d/1e09b240b04076a38937942d51b8f56f701958": "c5ca3e8009f6568e146f72f465e5d5c0",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/75/789b42dc4d57224a6b87e7c094bfff8e3ed0da": "d7dc7680d411b1c1acaab3d3aabeb40f",
".git/objects/75/7e2e61ba2b24b94e30a2490103a4eb09c60ff5": "c886352518f96786dff2e89754449a45",
".git/objects/75/bcd43c4a45af714e6cd4b94d9b0a6d16595d36": "bfef47399228a4217a7e8a0e5b56c5c0",
".git/objects/76/01048e7d85501a2cf4f24b292b4c43c41e0f2f": "d9cf5ab6dafef9c2e63fc2b3eb8f9f81",
".git/objects/77/900a5858ce37e7b5904e9e55aabb782a009b2b": "e27e0426e7206c18ab6a98c3225cd8b9",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/7c/ed21a76727e970628b17072ed94304e3671dac": "d9dabbea8cd90d17548db7d9ff9c7ea9",
".git/objects/7f/c00c82d32295241158deb2d95809c30c75de83": "1404ac25807d8de4e1ecc6b587caa0bc",
".git/objects/80/2200d27a52407e95d91fc629b5e2a062d8bef1": "0f62419c6fa24ae58e6f46622182f508",
".git/objects/83/12b2ce94b9bc54e5978413e0f8d2faabb6c35f": "9756062ff003833f439b004a9b76998d",
".git/objects/85/5892833a465faca741e8c571fd5b49431989f5": "6fcf3cfb724454780afe11a001e89013",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/8e/21753cdb204192a414b235db41da6a8446c8b4": "1e467e19cabb5d3d38b8fe200c37479e",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/98/c74e0a4228f2c6b06c405518e09ea9b79c43cb": "3163734854863bba89a915ef06ea4c4e",
".git/objects/9a/5a64323b68da9495933a602b283a7d8685c9b5": "e9462a69a359e04546a20093e64d4d3c",
".git/objects/9f/caa52ea9155ff70c49a9bc8e1b4052a1cc7f53": "3b1c6aadfd4e0112f3906b6e33dafd24",
".git/objects/a1/5600c69df7e89c15b5dede390067ee3391d46a": "df1a62604a1593ec480bb9a14f3d63ad",
".git/objects/a2/a83ac6cf5041f688d4cd0fda819a514f531f0e": "185503501fb88b8a416aef99c0c2b48d",
".git/objects/a7/3f4b23dde68ce5a05ce4c658ccd690c7f707ec": "ee275830276a88bac752feff80ed6470",
".git/objects/ac/587b482b8c864d180e089366c5a72aa72785f8": "f0837fe85085bd0b80e289f021f11ffc",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/ae/716936e9e4c1d23bd12f7d7e44fdc695627a5d": "1e059eeadfd9100432caf5e408cf079b",
".git/objects/af/e536eef61edb3ca67c0c553849d82ffb17b131": "7718843e70fb87653a6001871c85f563",
".git/objects/b4/3786bb5218a4fe970f255d45391579ef8445e2": "f03bcf7218f7316b8d879ec2b66b1d4d",
".git/objects/b7/dc737d0cedfb138aeeee534066795bab8fe1ce": "9e6ad65ed056fd22fba53b4456a25dd2",
".git/objects/b8/587d8e618e0990bf4316daae50ac3198a3418f": "c5a05238f1a43c29ae7d8f45df6fec40",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/bd/2b0967ab4d099f901ce51efa4260ee67b2c1a6": "22e7dd237f44b06f8a8109bcc77c70e1",
".git/objects/c4/36e9b6f1ca4fe2886232a4381b44d400d4be91": "c62d39a7d1f3914b8d6053fe4fbebe14",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/cd/23e154cf03e06c56be2ad506420d3ad816079c": "12628b0f178ff85e7cd624746ef51969",
".git/objects/d0/924267f9377a60b4388c1020a500265efa9cdd": "2bc01ddd16c502bbe7b2b9b60a467ab6",
".git/objects/d1/73e15c6ad72f7bdacc33fa7c42d0a61d5e48cc": "410145f2961b96fb467635f43b851368",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d6/864b1df3a8acba8860b34ecf7591e10c78debc": "71f8ed823c10ded4cd4bc4a3d4f41b03",
".git/objects/d6/c9bc0ac44b27483553998a6aec468a1851a304": "ca49f1ab5b6dd4fc7bfeacd87c0ee63b",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/dc/927fc95d6fff447787959fd8ee8a9b91eefb7b": "223da056e0f7429b67e2fd7ff6b524f8",
".git/objects/e5/ab464431a87f31075f743d1199081278996827": "d08be40039295e0d2dd5023e281604bd",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/ea/175cc30f115094402fb6d786f467f8ebad3840": "783e69b3df7398e14e8c92d2800bc678",
".git/objects/ec/7ade587b151492bebf4ff95c0f23424a8d1b8b": "8126f4ba49857e6dca97183b8e18d839",
".git/objects/ed/bfe0b7825e31d1f82e65e346852f0ac90a1c85": "b3db7dafaa93c4fb69d5d544b8257510",
".git/objects/ef/a222cb61113b984e798d7d899ff24c5350dd69": "81a48cd55aea164758dab7db4e2acacc",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/f8/3a5774a9a52b0e9c8b326fb1792bd53fd4d003": "e613373bd8cc393cab4e88a684b09df0",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/objects/fd/87f7859845f1fe204d50da7c6393b6f5c501b8": "bdbbaa9f42ff9042e3329e78312cf891",
".git/objects/fd/91b3b0b93e0bf4a497585e86f3e00ee6b248e4": "c055aaddf573d35ccaa018720bbd1f55",
".git/objects/fd/c3ba095b060f8a30393488cd919275b684185d": "64c296635f704d54eecfe2a04485f2a4",
".git/objects/fd/f0a52e5821f34937f99d9c597b99fb991b3263": "dca964b1bab4704f8aeeeaa9088cc483",
".git/objects/ff/f3a37206bbac11d5eab4d8432a0abdb601c836": "3a36463c62311ea82578aa015df4d01d",
".git/refs/heads/main": "9bee15859c231fda9909cd3130d9cfe1",
".git/refs/remotes/origin/main": "9bee15859c231fda9909cd3130d9cfe1",
"akaricon.ico": "4e26f76ca5d50e031c7d0ca6e0c2e0e8",
"assets/AssetManifest.bin": "ade6432c4ba548fb9b7465df22dd3970",
"assets/AssetManifest.bin.json": "d638fbe3258c98227c87d4c384f34aeb",
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
"assets/fonts/MaterialIcons-Regular.otf": "a92a411ad50f02b9ea7f78d53354f48a",
"assets/NOTICES": "e0ab2dc425b5279df91ae4c159167cf8",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/window_manager/images/ic_chrome_close.png": "75f4b8ab3608a05461a31fc18d6b47c2",
"assets/packages/window_manager/images/ic_chrome_maximize.png": "af7499d7657c8b69d23b85156b60298c",
"assets/packages/window_manager/images/ic_chrome_minimize.png": "4282cd84cb36edf2efb950ad9269ca62",
"assets/packages/window_manager/images/ic_chrome_unmaximize.png": "4a90c1909cb74e8f0d35794e2f61d8bf",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets.zip": "95a5054296e83f4dd8f0e60b56639209",
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
"flutter_bootstrap.js": "995c59bff90b2f3f6b4ececb44fd0c57",
"icons/Icon-192.png": "be8a6bea9be3639c5cbfb0e3e28d3add",
"icons/Icon-512.png": "913df617e50ed97440ee54d7a7484f4d",
"icons/Icon-maskable-192.png": "97bd851bd27a7692ef565722dfea5567",
"icons/Icon-maskable-512.png": "a04cbd6bfd5a7926f7fed4de4d81afdf",
"index.html": "20a6ca2e947ff9b78c062875a21ebb22",
"/": "20a6ca2e947ff9b78c062875a21ebb22",
"main.dart.js": "d8c0f96220fada2486a7370d5e753a10",
"manifest.json": "e4048ec44c17cf895dafcabff92803c9",
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
