import 'package:karmachain_dash/common_libs.dart';
import 'package:karmachain_dash/services/api/types.pb.dart';
import 'package:karmachain_dash/ui/helpers/widget_utils.dart';
import 'package:status_alert/status_alert.dart';
import 'package:karmachain_dash/services/api/api.pbgrpc.dart';

class Transaction extends StatefulWidget {
  final List<int>? txHash;
  final SignedTransactionWithStatus? tx;

  // Transation for transaction hash or for provided tx
  const Transaction({super.key, this.txHash, this.tx});

  @override
  State<Transaction> createState() => _TransactionState();
}

class _TransactionState extends State<Transaction> {
  _TransactionState();

  // we assume api is available until we know otherwise
  bool apiOffline = false;

  // we assume found until we know otherwise
  bool txFound = true;

  // we assume tx is null until we know otherwise
  SignedTransactionWithStatus? tx;

  @override
  void initState() {
    super.initState();
    apiOffline = false;

    if (widget.tx != null) {
      Future.delayed(Duration.zero, () async {
        setState(() {
          tx = widget.tx;
        });
      });
      return;
    }

    Future.delayed(Duration.zero, () async {
      try {
        GetTransactionResponse resp = await api.apiServiceClient
            .getTransaction(GetTransactionRequest(txHash: widget.txHash!));

        if (!resp.hasTransaction()) {
          setState(() {
            txFound = false;
          });
          return;
        }

        setState(() {
          tx = resp.transaction;
          txFound = true;
          debugPrint(tx.toString());
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

    if (widget.txHash == null) {
      // badly configured - no tx hash set

      tiles.add(
        const CupertinoListTile.notched(
          title: Text('Transaction not found'),
          leading: Icon(
            CupertinoIcons.circle_fill,
            color: CupertinoColors.systemRed,
            size: 18,
          ),
        ),
      );
    }

    if (!apiOffline && txFound && tx == null) {
      tiles.add(
        const CupertinoListTile.notched(
          title: Text('Please wait...'),
          leading: Icon(CupertinoIcons.clock),
          trailing: CupertinoActivityIndicator(),
          // todo: number format
        ),
      );
    }

    if (!apiOffline && !txFound) {
      tiles.add(
        const CupertinoListTile.notched(
          title: Text('Transaction not found'),
          leading: Icon(
            CupertinoIcons.circle_fill,
            color: CupertinoColors.systemRed,
            size: 18,
          ),
        ),
      );
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
    }

    if (tx != null) {
      // todo: add tx tiles here
      tiles.add(
        const CupertinoListTile.notched(
          title: Text('Transaction details here'),
          leading: Icon(
            CupertinoIcons.circle_fill,
            color: CupertinoColors.systemGreen,
            size: 18,
          ),
        ),
      );
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
