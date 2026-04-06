import 'package:firebase_core/firebase_core.dart';
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

  Future<void> _initFirebase() async {
    try {
      await sl<FirebaseService>().initialize();
      if (Firebase.apps.isEmpty) {
        setState(() {
          _firebaseReady = false;
          _failureDetail = 'Firebase.apps is empty after initializeApp.';
        });
      } else {
        setState(() => _firebaseReady = true);
      }
    } on FirebaseException catch (e) {
      setState(() {
        _firebaseReady = false;
        _failureDetail = '${e.code}: ${e.message}';
      });
    } catch (e, st) {
      setState(() {
        _firebaseReady = false;
        _failureDetail = '$e\n$st';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppLoadingScreen();
    }
    if (!_firebaseReady) {
      return ConfigureFirebaseScreen(details: _failureDetail);
    }
    return const StreetbeatApp();
  }
}
