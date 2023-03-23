import 'package:flutter/material.dart';
import 'package:karmachain_dash/common_libs.dart';
import 'package:karmachain_dash/ui/helpers/behaviors.dart';
import 'package:karmachain_dash/ui/router.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// The KarmaCoinApp widget is the root of the app
class KarmachainDashboard extends StatelessWidget with GetItMixin {
  KarmachainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('KarmachainDash App build');

    // limit orientations to portrait up and down.
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    final Brightness platformBrightness =
        WidgetsBinding.instance.window.platformBrightness;

    // Theme is used below to have the Material widgets theme adapt to platform brightness

    return Builder(
      builder: (BuildContext context) {
        return DefaultTextStyle(
          style: CupertinoTheme.of(context).textTheme.textStyle,
          child: KeyboardDismisser(
            child: Theme(
              data: ThemeData(brightness: platformBrightness),
              child: CupertinoApp.router(
                scrollBehavior: MouseDragScrollBehavior(),
                routerConfig: appRouter,
                debugShowCheckedModeBanner: false,
                useInheritedMediaQuery: true,
                title: 'Karmachain Dash',
                theme: const CupertinoThemeData(
                  primaryColor: CupertinoColors.activeOrange,
                ),
                localizationsDelegates: const [
                  ...GlobalMaterialLocalizations.delegates,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en', ''),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
