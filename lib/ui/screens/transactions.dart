import 'package:karmachain_dash/common_libs.dart';
import 'package:karmachain_dash/data/genesis_config.dart';
import 'package:karmachain_dash/data/kc_amounts_formatter.dart';
import 'package:karmachain_dash/data/personality_traits.dart';
import 'package:karmachain_dash/data/phone_number_formatter.dart';
import 'package:karmachain_dash/data/signed_transaction.dart';
import 'package:karmachain_dash/services/api/types.pb.dart';
import 'package:karmachain_dash/ui/helpers/widget_utils.dart';
import 'package:status_alert/status_alert.dart';
import 'package:karmachain_dash/services/api/api.pbgrpc.dart' as api_types;
import 'package:quiver/collection.dart';

// Display list of transactions for provided account id or for a block
class Transactions extends StatefulWidget {
  final List<List<int>>? txHashes;
  final List<int>? accountId;

  final String? title;

  const Transactions(
      {super.key, this.txHashes, this.accountId, this.title = 'Transactions'});

  @override
  State<Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  _TransactionsState();

  // we assume api is available until we know otherwise
  bool apiOffline = false;

  // we assume tx is null until we know otherwise
  List<SignedTransactionWithStatus>? txs;

  @override
  void initState() {
    super.initState();
    apiOffline = false;

    Future.delayed(Duration.zero, () async {
      try {
        if (widget.accountId != null) {
          // get txs for account
          api_types.GetTransactionsResponse resp = await api.apiServiceClient
              .getTransactions(api_types.GetTransactionsRequest(
                  accountId: AccountId(data: widget.accountId!)));

          setState(() {
            txs = resp.transactions;
          });
        } else if (widget.txHashes != null) {
          // get txs for hashes
          List<SignedTransactionWithStatus> newTxs = [];
          for (List<int> txHash in widget.txHashes!) {
            api_types.GetTransactionResponse resp = await api.apiServiceClient
                .getTransaction(
                    api_types.GetTransactionRequest(txHash: txHash));

            if (resp.hasTransaction()) {
              newTxs.add(resp.transaction);
            }
          }
          setState(() {
            txs = newTxs;
            debugPrint(txs.toString());
          });
        } else {
          // badly configured - no tx hashes
          txs = [];
        }
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

    if (apiOffline) {
      tiles.add(
        CupertinoListTile.notched(
          title: const Text('Api offline - try later'),
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

    if (txs == null) {
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

    if (txs != null && txs!.isEmpty) {
      tiles.add(
        const CupertinoListTile.notched(
          title: Text('No transactions found'),
          leading: Icon(
            CupertinoIcons.circle_fill,
            color: CupertinoColors.systemRed,
            size: 18,
          ),
        ),
      );
      return [
        CupertinoListSection.insetGrouped(
          children: tiles,
        ),
      ];
    }

    List<CupertinoListSection> txSections = [];
    for (SignedTransactionWithStatus tx in txs!) {
      bool? incoming;

      if (widget.accountId != null) {
        if (listsEqual(widget.accountId, tx.from.accountId.data)) {
          incoming = false;
        } else if (listsEqual(widget.accountId, tx.to.accountId.data)) {
          incoming = true;
        }
      }

      SignedTransactionWithStatusEx txEx =
          SignedTransactionWithStatusEx(tx, incoming);

      txSections.add(_getTxSection(txEx));
    }

    return txSections;
  }

  CupertinoListSection _getTxSection(SignedTransactionWithStatusEx txEx) {
    List<CupertinoListTile> tiles = [];

    CupertinoListSection section =
        CupertinoListSection.insetGrouped(children: tiles);

    tiles.add(
      CupertinoListTile.notched(
        title: Text(txEx.getTransactionTypeDisplayName()),
        trailing: Text(txEx.getTimesAgo()),
        leading: const Icon(CupertinoIcons.clock, size: 28),
      ),
    );

    PaymentTransactionV1? paymentData = txEx.getPaymentData();

    if (paymentData != null) {
      if (paymentData.charTraitId != 0 &&
          paymentData.charTraitId < GenesisConfig.personalityTraits.length) {
        PersonalityTrait trait =
            GenesisConfig.personalityTraits[paymentData.charTraitId];
        String title = 'You are ${trait.name.toLowerCase()}';
        String emoji = trait.emoji;

        tiles.add(
          CupertinoListTile.notched(
            title: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
            ),
            leading: Text(
              emoji,
              style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  TextStyle(
                      fontSize: 24,
                      color: CupertinoTheme.of(context)
                          .textTheme
                          .textStyle
                          .color)),
            ),
          ),
        );

        String amount =
            KarmaCoinAmountFormatter.formatMinimal(paymentData.amount);
        String usdEstimate =
            KarmaCoinAmountFormatter.formatUSDEstimate(paymentData.amount);

        tiles.add(
          CupertinoListTile.notched(
            title: Text(amount,
                style: CupertinoTheme.of(context).textTheme.textStyle),
            subtitle: Text(usdEstimate),
            leading: const Icon(CupertinoIcons.money_dollar, size: 28),
          ),
        );
      }
    }

    final User fromUser = txEx.getFromUser();
    final fromUserPhoneNumber =
        fromUser.mobileNumber.number.formatPhoneNumber();

    // from
    tiles.add(
      CupertinoListTile.notched(
        title: Text(
            'From ${fromUser.userName} - $fromUserPhoneNumber - ${fromUser.accountId.data.toShortHexString()}'),
      ),
    );

    final User toUser = txEx.getFromUser();
    final toUserPhoneNumber = toUser.mobileNumber.number.formatPhoneNumber();

    tiles.add(
      CupertinoListTile.notched(
        title: Text(
            'To ${toUser.userName} - $toUserPhoneNumber - ${toUser.accountId.data.toShortHexString()}'),
      ),
    );

    // status
    tiles.add(
      CupertinoListTile.notched(
        title: Text(txEx.getStatusDisplayString()),
        leading: Icon(
          CupertinoIcons.circle_fill,
          color: txEx.getStatusDisplayColor(),
          size: 18,
        ),
      ),
    );

    String feeAmount = KarmaCoinAmountFormatter.formatMinimal(txEx.txBody.fee);
    String feeUsdEstimate =
        KarmaCoinAmountFormatter.formatUSDEstimate(txEx.txBody.fee);

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Fee, $feeAmount',
            style: CupertinoTheme.of(context).textTheme.textStyle),
        subtitle: Text(feeUsdEstimate),
        leading: const Icon(CupertinoIcons.money_dollar, size: 28),
      ),
    );

    return section;
  }

  @override
  build(BuildContext context) {
    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Karmachain - ${widget.title!}',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              CupertinoSliverNavigationBar(
                largeTitle: Text(widget.title!),
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
