import 'package:karmachain_dash/common/platform_info.dart';
import 'package:karmachain_dash/common_libs.dart';
import 'package:url_launcher/url_launcher.dart';

// common widget helper functions

const statusAlertWidth = 270.0;

Future<bool> openUrl(String url) async {
  if (!await PlatformInfo.isConnected()) {
    return false;
  }

  final Uri uri = Uri.parse(url);
  return await launchUrl(uri);
}

Widget adjustNavigationBarButtonPosition(Widget button, double x, double y) {
  return Container(
    transform: Matrix4.translationValues(x, y, 0),
    child: button,
  );
}
