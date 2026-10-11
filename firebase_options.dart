import 'package:firebase_core/firebase_core.dart';

/// Bu fayl `flutterfire configure` o'rniga qo'lda to'ldiriladi.
/// Qiymatlarni Firebase'dan yuklab olingan google-services.json faylidan oling.
class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'SHU_YERGA_current_key',            // api_key -> current_key
    appId: 'SHU_YERGA_mobilesdk_app_id',        // client_info -> mobilesdk_app_id
    messagingSenderId: 'SHU_YERGA_project_number', // project_info -> project_number
    projectId: 'SHU_YERGA_project_id',          // project_info -> project_id
    storageBucket: 'SHU_YERGA_storage_bucket',  // project_info -> storage_bucket
  );
}
