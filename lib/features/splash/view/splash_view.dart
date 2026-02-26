// features/splash/view/splash_view.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:music_music/app/app_info.dart';
import 'package:music_music/app/routes.dart';
import 'package:music_music/core/preferences/welcome_prefs.dart';
import 'package:music_music/features/home/view_model/home_view_model.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  Timer? _canSkipTimer;
  bool _canSkip = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final vm = context.read<HomeViewModel>();
    await _requestNotificationPermissionIfNeeded();

    _canSkipTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _canSkip = true);
    });

    await Future.any([
      _waitForReady(vm),
      Future.delayed(const Duration(seconds: 4)),
    ]);

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 400));

    _goNext();
  }

  Future<void> _requestNotificationPermissionIfNeeded() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> _waitForReady(HomeViewModel vm) {
    if (!vm.isLoading && !vm.isScanning) {
      return Future.value();
    }

    final completer = Completer<void>();

    void listener() {
      if (!vm.isLoading && !vm.isScanning) {
        vm.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }

    vm.addListener(listener);
    return completer.future;
  }

  Future<void> _goNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    final showWelcome = await WelcomePrefs.shouldShowWelcomeToday();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      showWelcome ? AppRoutes.welcome : AppRoutes.home,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Icon(
                    Icons.music_note,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppInfo.appName,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Carregando sua biblioteca',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Preparando tudo para você',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      if (_canSkip)
                        TextButton(
                          onPressed: _goNext,
                          child: const Text('Pular'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _canSkipTimer?.cancel();
    super.dispose();
  }
}


