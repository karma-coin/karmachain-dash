import 'package:fixnum/fixnum.dart';
import 'package:karmachain_dash/common_libs.dart';
import 'package:karmachain_dash/services/api/types.pb.dart';
import 'package:karmachain_dash/ui/helpers/widget_utils.dart';
import 'package:karmachain_dash/ui/widgets/block_widget.dart';
import 'package:status_alert/status_alert.dart';
import 'package:karmachain_dash/services/api/api.pbgrpc.dart';

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
          debugPrint(blocks.toString());
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
          title: Text('One sec...'),
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
      tiles.add(getBlockWidget(context, b, 'Block ${b.height}', true));
    }

    return [
      CupertinoListSection.insetGrouped(
        children: tiles,
      ),
    ];
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
            child: SafeArea(
              child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  primary: true,
                  children: _getSections(context)),
            ),
          ),
        ),
      ),
    );
  }
}
