import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:media_kit/media_kit.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:jellyflix/providers/router_provider.dart';
import 'package:jellyflix/providers/scaffold_key.dart';
import 'package:jellyflix/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid || Platform.isIOS) {
    await FlutterDownloader.initialize(
        debug: kDebugMode ? true : false,
        ignoreSsl:
            true // option: set to false to disable working with http links (default: false)
        );
  }
  await DatabaseService.initialize();

  // await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  // // save to file
  // var fileName = "NotoSans-Regular.ttf";

  // Necessary initialization for package:media_kit.
  MediaKit.ensureInitialized();
  runApp(ProviderScope(
    child: Shortcuts(shortcuts: <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
    }, child: const MyApp()),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.read(routerProvider).router;
    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      // localization
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // routing
      routeInformationParser: appRouter.routeInformationParser,
      routerDelegate: appRouter.routerDelegate,
      routeInformationProvider: appRouter.routeInformationProvider,
      debugShowCheckedModeBanner: false,
      title: "Jellyflix",
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9E9E9E),
            primary: const Color(0xFFB0BEC5),
            secondary: const Color(0xFF78909C),
            surface: const Color(0xFF1A1A1A),
            brightness: Brightness.dark),
        useMaterial3: true,
      ),
    );
  }
}
