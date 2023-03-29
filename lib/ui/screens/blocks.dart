import 'package:fixnum/fixnum.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:karmachain_dash/common_libs.dart';
import 'package:karmachain_dash/data/kc_amounts_formatter.dart';
import 'package:karmachain_dash/services/api/types.pb.dart';
import 'package:karmachain_dash/ui/helpers/widget_utils.dart';
import 'package:status_alert/status_alert.dart';
import 'package:karmachain_dash/services/api/api.pbgrpc.dart';
import 'package:time_ago_provider/time_ago_provider.dart' as time_ago;
import 'package:karmachain_dash/common/extensions.dart';

/// Display user details for provided user or for local user
class Blocks extends StatefulWidget {
  /// Set user to display] details for or null for local user
  const Blocks({super.key});

  @override
  State<Blocks> createState() => _BlocksState();
}

class _BlocksState extends State<Blocks> {
  _BlocksState();

  List<Block> blocks = [];

  bool apiOffline = false;

  @override
  void initState() {
    super.initState();
    apiOffline = false;

    Future.delayed(Duration.zero, () async {
      try {
        GetBlockchainDataResponse data = await api.apiServiceClient
            .getBlockchainData(GetBlockchainDataRequest());

        GetBlocksResponse resp = await api.apiServiceClient.getBlocks(
            GetBlocksRequest(
                fromBlockHeight: Int64.ZERO,
                toBlockHeight: data.stats.tipHeight));

        resp.blocks.sort((a, b) => b.height.compareTo(a.height));

        setState(() {
          blocks = resp.blocks;
          debugPrint(resp.toString());
          // debugPrint(genesis_data.toString());
        });
      } catch (e) {
        apiOffline = true;
        if (!mounted) return;
        StatusAlert.show(context,
            duration: const Duration(seconds: 2),
            title: 'Server Error',
            subtitle: 'Please try later',
            configuration: const IconConfiguration(
                icon: CupertinoIcons.exclamationmark_triangle),
            dismissOnBackgroundTap: true,
            maxWidth: statusAlertWidth);
        debugPrint('error getting karmachain data: $e');
      }
    });
  }

  /// Return the list secionts
  List<CupertinoListSection> _getSections(BuildContext context) {
    List<CupertinoListTile> tiles = [];
    if (!apiOffline && blocks.isEmpty) {
      tiles.add(
        const CupertinoListTile.notched(
          title: Text('Please wait...'),
          leading: Icon(CupertinoIcons.clock),
          trailing: CupertinoActivityIndicator(),
          // todo: number format
        ),
      );
      return [
        CupertinoListSection.insetGrouped(
          children: tiles,
        ),
      ];
    }

    if (apiOffline) {
      tiles.add(
        CupertinoListTile.notched(
          title: const Text('Status'),
          leading: const Icon(
            CupertinoIcons.circle_fill,
            color: CupertinoColors.systemRed,
            size: 18,
          ),
          trailing: Text('Offline',
              style: CupertinoTheme.of(context).textTheme.textStyle),
        ),
      );
      return [
        CupertinoListSection.insetGrouped(
          children: tiles,
        ),
      ];
    }

    for (Block b in blocks) {
      tiles.add(_getBlockWidget(context, b));
    }

    return [
      CupertinoListSection.insetGrouped(
        children: tiles,
      ),
    ];
  }

  CupertinoListTile _getBlockWidget(BuildContext context, Block b) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(b.time.toInt());

    String fees = KarmaCoinAmountFormatter.format(b.fees);

    int txCount = b.transactionsHashes.length;
    String txs = txCount == 1 ? '1 transaction' : '$txCount transactions';

    return CupertinoListTile(
      padding: const EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 12),
      title: Text('Block ${b.height}',
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

  @override
  build(BuildContext context) {
    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Karmachain - Blocks',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Karmachain Blocks'),
              ),
            ];
          },
          body: MediaQuery.removePadding(
            context: context,
            removeTop: false,
            child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                primary: true,
                children: _getSections(context)),
          ),
        ),
      ),
    );
  }
}
