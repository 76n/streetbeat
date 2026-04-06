import 'package:firebase_core/firebase_core.dart';

import '../../core/constants/firebase_config_check.dart';

enum FirebaseInitResult {
  success,
  placeholder,
  failed,
}

class FirebaseService {
  String? lastFailureMessage;

  bool isEffectivelyConfigured() {
    if (Firebase.apps.isEmpty) {
      return false;
    }
    return areFirebaseOptionsConfigured(Firebase.app().options);
  }

  Future<FirebaseInitResult> initialize() async {
    lastFailureMessage = null;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } on FirebaseException catch (e) {
      lastFailureMessage = '${e.code}: ${e.message}';
      return FirebaseInitResult.failed;
    } catch (e, st) {
      lastFailureMessage = '$e\n$st';
      return FirebaseInitResult.failed;
    }

    if (!isEffectivelyConfigured()) {
      lastFailureMessage ??=
          'Firebase options look like a placeholder (empty or invalid project id, api key, or app id).';
      return FirebaseInitResult.placeholder;
    }

    return FirebaseInitResult.success;
  }

  Future<FirebaseInitResult> revalidateAfterConfigChange() async {
    if (Firebase.apps.isEmpty) {
      return initialize();
    }
    if (!isEffectivelyConfigured()) {
      lastFailureMessage ??=
          'Firebase options still look invalid. Do a full restart after replacing google-services.json.';
      return FirebaseInitResult.placeholder;
    }
    return FirebaseInitResult.success;
  }
}
