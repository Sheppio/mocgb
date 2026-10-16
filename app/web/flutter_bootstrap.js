{{flutter_js}}
{{flutter_build_config}}

// Same as Flutter's default start-up, plus telling the splash screen (web/index.html) which stage it's at.
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  onEntrypointLoaded: async (engineInitializer) => {
    mocgbSplash.stage("starting");
    const appRunner = await engineInitializer.initializeEngine();
    mocgbSplash.stage("opening");
    await appRunner.runApp();
  },
});
