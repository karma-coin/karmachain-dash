import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:karmachain_dash/logic/app_logic.dart';
import 'package:karmachain_dash/ui/widgets/app.dart';
//import 'package:url_strategy/url_strategy.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  AppLogic.registerSingletons();

  // this removes the # from web routes for go router
  // setPathUrlStrategy();

  await appLogic.bootstrap();

  runApp(KarmachainDashboard());
  FlutterNativeSplash.remove();
}
