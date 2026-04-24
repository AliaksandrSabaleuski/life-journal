import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/config/ga_keys.dart';
import 'core/services/analytics_service.dart';
import 'core/services/appmetrica_service.dart';
import 'core/services/iap_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/subscription_service.dart';

Future<({String gameKey, String secretKey})?> _loadGaKeysFromDisk() async {
  // Local-only convenience: keep secrets outside the repo.
  // Accept both names (Windows may append .txt).
  const candidates = [
    r'D:\keystore\key\ga_keys.json',
    r'D:\keystore\key\ga_keys.json.txt',
  ];
  for (final path in candidates) {
    final f = File(path);
    if (!await f.exists()) continue;
    try {
      final raw = await f.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) continue;
      final gameKey = decoded['gameKey'];
      final secretKey = decoded['secretKey'];
      if (gameKey is String && secretKey is String) {
        return (gameKey: gameKey.trim(), secretKey: secretKey.trim());
      }
    } catch (_) {
      // ignore bad file
    }
  }
  return null;
}

Future<String?> _loadAppMetricaKeyFromDisk() async {
  const candidates = [
    r'D:\keystore\key\appmetrica.json',
    r'D:\keystore\key\appmetrica.json.txt',
  ];
  for (final path in candidates) {
    final f = File(path);
    if (!await f.exists()) continue;
    try {
      final raw = await f.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) continue;
      final apiKey = decoded['apiKey'];
      if (apiKey is String && apiKey.trim().isNotEmpty) {
        return apiKey.trim();
      }
    } catch (_) {
      // ignore bad file
    }
  }
  return null;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  Object? _error;
  StackTrace? _st;
  bool? _onboardingCompleted;
  bool _loadingEntered = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    const minLoading = Duration(seconds: 2);
    final sw = Stopwatch()..start();
    try {
      // Intl: форматирование дат/дней недели на русском.
      await initializeDateFormatting('ru');

      // GameAnalytics: configure in lib/core/config/ga_keys.dart or via --dart-define
      // Disk keys are a Windows-only convenience.
      final diskKeys = (Platform.isWindows) ? await _loadGaKeysFromDisk() : null;
      const envGameKey =
          String.fromEnvironment('GA_GAME_KEY', defaultValue: gaGameKey);
      const envSecretKey =
          String.fromEnvironment('GA_SECRET_KEY', defaultValue: gaSecretKey);
      final gameKey = (diskKeys?.gameKey.isNotEmpty ?? false)
          ? diskKeys!.gameKey
          : envGameKey;
      final secretKey = (diskKeys?.secretKey.isNotEmpty ?? false)
          ? diskKeys!.secretKey
          : envSecretKey;
      await AnalyticsService.instance.init(gameKey: gameKey, secretKey: secretKey);

      // AppMetrica: configure via Windows disk file or --dart-define.
      final diskAppMetricaKey =
          (Platform.isWindows) ? await _loadAppMetricaKeyFromDisk() : null;
      const envAppMetricaKey =
          String.fromEnvironment('APPMETRICA_API_KEY', defaultValue: '');
      final appMetricaKey = (diskAppMetricaKey?.isNotEmpty ?? false)
          ? diskAppMetricaKey!
          : envAppMetricaKey;
      await AppMetricaService.instance.init(apiKey: appMetricaKey);

      // Services
      await NotificationService.instance.init();
      await NotificationService.instance.onAppOpened();
      await SubscriptionService.init();
      await IapService.instance.init();

      await SharedPreferences.getInstance();

      final completed = await OnboardingService.isCompleted();

      sw.stop();
      if (sw.elapsed < minLoading) {
        await Future<void>.delayed(minLoading - sw.elapsed);
      }
      assert(() {
        // ignore: avoid_print
        print('[bootstrap] init took ${sw.elapsedMilliseconds}ms');
        return true;
      }());

      if (!mounted) return;
      setState(() => _onboardingCompleted = completed);
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _st = st;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _onboardingCompleted;
    if (completed != null) {
      return JournalApp(onboardingCompleted: completed);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF3EFE9),
        body: _error == null
            ? _BootstrapLoadingScreen(
                entered: _loadingEntered,
                onEntered: () {
                  if (!_loadingEntered && mounted) {
                    setState(() => _loadingEntered = true);
                  }
                },
              )
            : SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ошибка запуска',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text('$_error'),
                          const SizedBox(height: 10),
                          Text(
                            _st?.toString() ?? '',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _BootstrapLoadingScreen extends StatefulWidget {
  const _BootstrapLoadingScreen({
    required this.entered,
    required this.onEntered,
  });

  final bool entered;
  final VoidCallback onEntered;

  @override
  State<_BootstrapLoadingScreen> createState() => _BootstrapLoadingScreenState();
}

class _BootstrapLoadingScreenState extends State<_BootstrapLoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onEntered());
  }

  @override
  Widget build(BuildContext context) {
    const warmBase = Color(0xFFF3EFE9);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: const BoxDecoration(color: warmBase),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/LoadingBack.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 200),
                  Text(
                    'About Me',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          color: const Color(0xFF6B5A4E).withValues(alpha: 0.92),
                        ),
                  ),
                  const SizedBox(height: 22),
                  _ThreeDotsSpinner(color: primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreeDotsSpinner extends StatefulWidget {
  const _ThreeDotsSpinner({
    required this.color,
    this.dotSize = 7,
    this.gap = 10,
  });

  final Color color;
  final double dotSize;
  final double gap;

  @override
  State<_ThreeDotsSpinner> createState() => _ThreeDotsSpinnerState();
}

class _ThreeDotsSpinnerState extends State<_ThreeDotsSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _dotT(int index) {
    // phase shift: 0, 0.18, 0.36
    final t = (_c.value + index * 0.18) % 1.0;
    // triangle wave 0..1..0
    final v = t < 0.5 ? (t / 0.5) : ((1.0 - t) / 0.5);
    return v.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        Widget dot(int i) {
          final t = _dotT(i);
          final opacity = (0.35 + 0.65 * t).clamp(0.0, 1.0);
          final scale = 0.86 + 0.24 * t;
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(0),
            SizedBox(width: widget.gap),
            dot(1),
            SizedBox(width: widget.gap),
            dot(2),
          ],
        );
      },
    );
  }
}
