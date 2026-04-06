import 'package:firebase_core/firebase_core.dart';

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
    final options = Firebase.app().options;
    final projectId = options.projectId.trim();
    final apiKey = options.apiKey.trim();
    if (projectId.isEmpty || apiKey.isEmpty) {
      return false;
    }
    return true;
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
          'Firebase options look like a placeholder (empty project id or api key).';
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
          'Firebase options still look like a placeholder. Use hot restart after replacing native config files.';
      return FirebaseInitResult.placeholder;
    }
    return FirebaseInitResult.success;
  }
}
