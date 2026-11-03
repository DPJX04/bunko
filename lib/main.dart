import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'routing/app_router.dart';
import 'services/background_service.dart';
import 'state/settings_state.dart';

/// Starts the app inside Riverpod's scope, which holds every provider.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_archivoLicense);
  // Tapping the download notification opens the Downloads tab.
  BackgroundService().onNotificationTapped(() => appRouter.go('/downloads'));
  // Loads the stored settings first, so the first frame already has the
  // picked theme and language instead of flashing the defaults.
  final scope = ProviderContainer();
  await scope.read(settingsProvider.future);
  runApp(UncontrolledProviderScope(container: scope, child: const App()));
}

/// Lists the Archivo font's licence on Flutter's license page.
Stream<LicenseEntry> _archivoLicense() async* {
  final text = await rootBundle.loadString('assets/fonts/Archivo-OFL.txt');
  yield LicenseEntryWithLineBreaks(['Archivo'], text);
}
