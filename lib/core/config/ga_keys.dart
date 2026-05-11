/// GameAnalytics keys from gameanalytics.com → Your Game → Game Settings.
///
/// Option 1: Replace values here (do NOT commit real keys to git).
/// Option 2: One local file (gitignored) — copy dart_defines.example.json to dart_defines.json in repo root, fill keys, then:
///   flutter build appbundle --dart-define-from-file=dart_defines.json
///   or on Windows: .\\scripts\\build_appbundle.ps1 (reads dart_defines.json or D:\\keystore\\key\\*.json)
///
/// Option 3: Inline defines (CI / one-off):
///   flutter build appbundle --dart-define=GA_GAME_KEY=xxx --dart-define=GA_SECRET_KEY=yyy --dart-define=APPMETRICA_API_KEY=zzz
const String gaGameKey = '';
const String gaSecretKey = '';
