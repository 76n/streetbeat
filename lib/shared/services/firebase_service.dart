import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  Future<void> initialize() async {
    await Firebase.initializeApp();
  }
}
