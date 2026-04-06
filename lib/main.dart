import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'shared/services/firebase_service.dart';
import 'shared/widgets/app_loading_screen.dart';
import 'shared/widgets/configure_firebase_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const _StreetbeatBootstrap());
}

class _StreetbeatBootstrap extends StatefulWidget {
  const _StreetbeatBootstrap();

  @override
  State<_StreetbeatBootstrap> createState() => _StreetbeatBootstrapState();
}

class _StreetbeatBootstrapState extends State<_StreetbeatBootstrap> {
  bool _loading = true;
  bool _firebaseReady = false;
  String? _failureDetail;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initFirebase();
        }
      });
    }
  }

  Future<void> _initFirebase() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _failureDetail = null;
    });
    final service = sl<FirebaseService>();
    final result = Firebase.apps.isEmpty
        ? await service.initialize()
        : await service.revalidateAfterConfigChange();
    if (!mounted) {
      return;
    }
    switch (result) {
      case FirebaseInitResult.success:
        _firebaseReady = true;
        _failureDetail = null;
      case FirebaseInitResult.placeholder:
      case FirebaseInitResult.failed:
        _firebaseReady = false;
        _failureDetail = service.lastFailureMessage ??
            'Firebase is not configured for this build.';
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppLoadingScreen();
    }
    if (!_firebaseReady) {
      return ConfigureFirebaseScreen(
        details: _failureDetail,
        onRetry: _initFirebase,
      );
    }
    return const StreetbeatApp();
  }
}
