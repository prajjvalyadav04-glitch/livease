// PLACEHOLDER - replace by running `flutterfire configure` in the project root.
//
// That command generates the real file for your Firebase project and
// overwrites this one. Until then the app will throw at startup on purpose,
// so you never ship without a real Firebase configuration.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured yet. Run `flutterfire configure` '
      'in the project root (see README.md, step 2).',
    );
  }
}
