{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: { canvasKitBaseUrl: "canvaskit/" },
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  }
});
