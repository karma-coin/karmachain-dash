import 'package:fixnum/fixnum.dart';
import 'package:go_router/go_router.dart';
import 'package:karmachain_dash/common_libs.dart';
import 'package:karmachain_dash/ui/screens/block_screen.dart';
import 'package:karmachain_dash/ui/screens/blocks_screen.dart';
import 'package:karmachain_dash/ui/screens/karmachain.dart';
import 'package:karmachain_dash/ui/widgets/transaction.dart';

/// Shared paths / urls used across the app
class ScreenPaths {
  /// Guest home screen (playground for now)
  static String home = '/';
  static String blocks = '/blocks';
  static String txDetails = '/tx/:txId';
  static String userTxs = '/user/:accountId/txs';
  static String user = '/user/:accountId';
  static String block = '/block/:blockHeight';
}

class ScreenNames {
  /// Guest home screen (playground for now)
  static String home = 'home';
  static String blocks = 'blocks';
  static String txDetails = 'txDetials';
  static String userTxs = 'userTransactions';
  static String user = 'user';
  static String block = 'block';
}

popUntil(String path) {
  String currentRoute = appRouter.location;
  while (appRouter.canPop() && path != currentRoute) {
    currentRoute = appRouter.location;
    if (path != currentRoute) {
      appRouter.pop();
    }
  }
}

void pushNamedAndRemoveUntil(String path) {
  while (appRouter.canPop()) {
    appRouter.pop();
  }
  appRouter.go(path);
}

String _getInitialLocation() {
  return ScreenPaths.home;
}

/// The route configuration
final GoRouter appRouter = GoRouter(
    redirect: (context, state) {
      return null;
    },
    initialLocation: _getInitialLocation(),
    routes: <RouteBase>[
      GoRoute(
          path: ScreenPaths.home,
          builder: (BuildContext context, GoRouterState state) {
            return const Karmachain();
          }),
      GoRoute(
          path: ScreenPaths.blocks,
          builder: (BuildContext context, GoRouterState state) {
            return const Blocks();
          }),
      GoRoute(
          path: ScreenPaths.txDetails,
          builder: (BuildContext context, GoRouterState state) {
            var txId = state.params['txId'];
            if (txId == null) {
              // todo: redirect to home screen
            }

            return Transaction(key: Key(txId!), txHash: txId.toHex());
          }),
      GoRoute(
          name: ScreenNames.block,
          path: ScreenPaths.block,
          builder: (BuildContext context, GoRouterState state) {
            var blockId = state.params['blockHeight'];
            if (blockId == null) {
              // todo: redirect to home screen
            }

            Int64 blockHeight = Int64.parseInt(blockId!);

            return BlockScreen(
                blockHeight: blockHeight, title: 'Block $blockId');
          }),
    ]);
