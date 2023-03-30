import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:karmachain_dash/common_libs.dart';
import 'package:karmachain_dash/data/kc_amounts_formatter.dart';
import 'package:karmachain_dash/services/api/types.pb.dart';
import 'package:karmachain_dash/ui/router.dart';
import 'package:time_ago_provider/time_ago_provider.dart' as time_ago;

CupertinoListTile getBlockWidget(BuildContext context, Block b, String title) {
  DateTime time = DateTime.fromMillisecondsSinceEpoch(b.time.toInt());

  String fees = KarmaCoinAmountFormatter.format(b.fees);
  String rewards = KarmaCoinAmountFormatter.format(b.reward);
  // String minted = KarmaCoinAmountFormatter.format(b.minted);

  int txCount = b.transactionsHashes.length;
  String txs = txCount == 1 ? '1 transaction' : '$txCount transactions';

  return CupertinoListTile.notched(
    onTap: () {
      context.pushNamed(
        ScreenNames.block,
        params: {'blockId': b.digest.toHexString()},
        extra: b.transactionsHashes,
      );
    },
    padding: const EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 12),
    title: Text(title,
        style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${time_ago.format(time)} - $txs',
            style: CupertinoTheme.of(context)
                .textTheme
                .textStyle
                .merge(const TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 6),
          Text(
            'Reward: $rewards',
            style: CupertinoTheme.of(context)
                .textTheme
                .textStyle
                .merge(const TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 6),
          /*
          Text(
            'Minted: $minted',
            style: CupertinoTheme.of(context)
                .textTheme
                .textStyle
                .merge(const TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 6),
          */
          Text(
            'Fees: $fees',
            style: CupertinoTheme.of(context)
                .textTheme
                .textStyle
                .merge(const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    ),
    trailing: const CupertinoListTileChevron(),
    leading: const FaIcon(FontAwesomeIcons.square, size: 20),
  );
}
