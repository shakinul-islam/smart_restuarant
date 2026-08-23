{{flutter_js}}
{{flutter_build_config}}

// Service Worker (ক্যাশিং) পুরোপুরি ডিজেবল করা হলো যাতে ব্ল্যাংক স্ক্রিন না আসে
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: null, // Service worker বন্ধ
  },
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  }
});