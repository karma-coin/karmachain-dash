import 'package:karmachain_dash/common/platform_info.dart';
import 'package:karmachain_dash/common_libs.dart';

// todo: add settings interface

// todo: migrate from json file to a hive box

/// App settings logic
class SettingsLogic {
  // constants - should come from config

  /// Set to true to work against localhost servers. Otherwise production servers are used
  final bool localMode = false;

  // dev mode has some text field input shortcuts to save time in dev
  final bool devMode = false;

  Future<void> init() async {
    if (localMode) {
      debugPrint("Wroking against local servers");
      if (await PlatformInfo.isRunningOnAndroidEmulator()) {
        debugPrint('Running in Android emulator');
        // on android emulator, use the host machine ip address
        apiHostName.value = '10.0.2.2';
        verifierHostName.value = '10.0.2.2';
      } else {
        apiHostName.value = '127.0.0.1';
        verifierHostName.value = '127.0.0.1';
      }
      apiSecureConnection.value = false;
      verifierSecureConnection.value = false;
    } else {
      debugPrint('Working against production servers');
      apiHostName.value = 'api.karmaco.in';
      apiHostPort.value = 443;
      apiSecureConnection.value = true;
      verifierHostName.value = 'api.karmaco.in';
      verifierHostPort.value = 443;
      verifierSecureConnection.value = true;
    }
  }

  late final currentLocale = ValueNotifier<String?>(null);
  late final apiHostName = ValueNotifier<String>('127.0.0.1');
  late final apiHostPort = ValueNotifier<int>(9080);
  late final apiSecureConnection = ValueNotifier<bool>(false);
  late final verifierHostName = ValueNotifier<String>('127.0.0.1');
  late final verifierHostPort = ValueNotifier<int>(9080);
  late final verifierSecureConnection = ValueNotifier<bool>(false);

  // this is default dev mode verifier account id.
  late final verifierAccountId = ValueNotifier<String>(
      'a885bf7ac670b0f01a3551740020e115641005a93f59472002bfd1dc665f4a4e');
  // requested user name entered by the user. For the canonical user-name, check AccountLogic

}
