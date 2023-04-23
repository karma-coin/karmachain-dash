import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karmachain_dash/common_libs.dart';
import 'package:karmachain_dash/data/genesis_config.dart';
import 'package:karmachain_dash/data/kc_amounts_formatter.dart';
import 'package:karmachain_dash/data/personality_traits.dart';
import 'package:karmachain_dash/data/phone_number_formatter.dart';
import 'package:karmachain_dash/data/signed_transaction.dart';
import 'package:karmachain_dash/services/api/api.pb.dart';
import 'package:karmachain_dash/services/api/types.pb.dart';
import 'package:karmachain_dash/ui/helpers/widget_utils.dart';
import 'package:karmachain_dash/ui/router.dart';
import 'package:karmachain_dash/ui/widgets/block_widget.dart';
import 'package:karmachain_dash/ui/widgets/pill.dart';
import 'package:status_alert/status_alert.dart';
import 'package:karmachain_dash/services/api/api.pbgrpc.dart' as api_types;

// Display list of transactions for provided account id or for a block
class BlockScreen extends StatefulWidget {
  final Int64 blockHeight;
  final String? title;

  const BlockScreen(
      {super.key, this.blockHeight = Int64.ONE, this.title = 'Transactions'});

  @override
  State<BlockScreen> createState() => _BlockScreenState();
}

class _BlockScreenState extends State<BlockScreen> {
  _BlockScreenState();

  // we assume api is available until we know otherwise
  bool apiOffline = false;

  // we assume tx is null until we know otherwise
  List<SignedTransactionWithStatus>? txs;

  Block? block;

  @override
  void initState() {
    super.initState();
    apiOffline = false;

    Future.delayed(Duration.zero, () async {
      List<SignedTransactionWithStatus> newTxs = [];
      Block? newBlock;
      try {
        GetBlocksResponse blockResp = await api.apiServiceClient.getBlocks(
            GetBlocksRequest(
                fromBlockHeight: widget.blockHeight,
                toBlockHeight: widget.blockHeight));

        if (blockResp.blocks.isEmpty) {
          throw 'Block not found';
        }

        newBlock = blockResp.blocks.first;

        for (List<int> txHash in newBlock.transactionsHashes) {
          GetBlocksResponse blockResp = await api.apiServiceClient.getBlocks(
              GetBlocksRequest(
                  fromBlockHeight: widget.blockHeight,
                  toBlockHeight: widget.blockHeight));

          if (blockResp.blocks.isEmpty) {
            throw 'Block not found';
          }

          newBlock = blockResp.blocks.first;

          api_types.GetTransactionResponse resp = await api.apiServiceClient
              .getTransaction(api_types.GetTransactionRequest(txHash: txHash));

          if (resp.hasTransaction()) {
            newTxs.add(resp.transaction);
          }
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

      setState(() {
        block = newBlock;
        txs = newTxs;
        //debugPrint(txs.toString());
      });
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

    List<CupertinoListSection> screenSections = [];

    if (block != null) {
      screenSections.add(
        CupertinoListSection.insetGrouped(
          children: [getBlockWidget(context, block!, widget.title!, false)],
        ),
      );
    }

    for (SignedTransactionWithStatus tx in txs!) {
      SignedTransactionWithStatusEx txEx =
          SignedTransactionWithStatusEx(tx, null);

      screenSections.add(_getTxSection(txEx));
    }

    return screenSections;
  }

  CupertinoListSection _getTxSection(SignedTransactionWithStatusEx txEx) {
    List<CupertinoListTile> tiles = [];

    PaymentTransactionV1? paymentData = txEx.getPaymentData();

    tiles.add(
      CupertinoListTile.notched(
        title: Text(
          txEx.getTransactionTypeDisplayName(),
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(TextStyle(
              color: CupertinoTheme.of(context).textTheme.textStyle.color)),
        ),
        leading: Container(),
        trailing: Text(txEx.getTimesAgo(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
      ),
    );

    if (paymentData != null) {
      if (paymentData.charTraitId != 0 &&
          paymentData.charTraitId < GenesisConfig.personalityTraits.length) {
        PersonalityTrait trait =
            GenesisConfig.personalityTraits[paymentData.charTraitId];
        String title = 'You are ${trait.name.toLowerCase()}';
        String emoji = trait.emoji;

        if (paymentData.communityId != 0) {
          Community? community =
              GenesisConfig.communities[paymentData.communityId];
          if (community != null) {
            tiles.add(
              CupertinoListTile.notched(
                title: Text(
                  'Community - ${community.name}',
                  style: CupertinoTheme.of(context).textTheme.textStyle,
                ),
                leading: Text(
                  community.emoji,
                  style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                      TextStyle(
                          fontSize: 20,
                          color: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .color)),
                ),
              ),
            );
          }
        }

        tiles.add(
          CupertinoListTile.notched(
            title: Text(
              title,
              style: CupertinoTheme.of(context).textTheme.textStyle,
            ),
            leading: Text(
              emoji,
              style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  TextStyle(
                      fontSize: 20,
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
            title: Text('Payment',
                style: CupertinoTheme.of(context).textTheme.textStyle),
            trailing: Text(amount,
                style: CupertinoTheme.of(context).textTheme.textStyle),
            subtitle: Text(usdEstimate),
            leading: const Icon(CupertinoIcons.money_dollar, size: 28),
          ),
        );
      }
    }

    final User? fromUser = txEx.getFromUser();
    final fromUserPhoneNumber = fromUser != null
        ? fromUser.mobileNumber.number.formatPhoneNumber()
        : "n/a";

    final String fromUserName = fromUser?.userName ?? "n/a";
    final String fromUserAccountId =
        txEx.getFromUserAccountId().toShortHexString();

    // from
    tiles.add(
      CupertinoListTile.notched(
        title:
            Text('From', style: CupertinoTheme.of(context).textTheme.textStyle),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fromUserName),
            Text(fromUserAccountId),
            const SizedBox(height: 6),
          ],
        ),
        trailing: Text(fromUserPhoneNumber,
            style: CupertinoTheme.of(context).textTheme.textStyle),
        leading: const Icon(CupertinoIcons.arrow_right, size: 28),
        onTap: fromUser != null
            ? () {
                context.pushNamed(ScreenNames.user, params: {
                  'accountId': txEx.getFromUserAccountId().toHexString()
                });
              }
            : null,
      ),
    );

    if (paymentData != null) {
      final User toUser = txEx.getToUser()!;
      final toUserPhoneNumber = toUser.mobileNumber.number.formatPhoneNumber();

      tiles.add(
        CupertinoListTile.notched(
          title:
              Text('To', style: CupertinoTheme.of(context).textTheme.textStyle),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(toUser.userName),
              Text(toUser.accountId.data.toShortHexString()),
              const SizedBox(height: 6),
            ],
          ),
          trailing: Text(toUserPhoneNumber,
              style: CupertinoTheme.of(context).textTheme.textStyle),
          leading: const Icon(CupertinoIcons.arrow_left, size: 28),
          onTap: () {
            context.pushNamed(ScreenNames.user,
                params: {'accountId': toUser.accountId.data.toHexString()});
          },
        ),
      );
    }

    // status
    tiles.add(
      CupertinoListTile.notched(
        trailing: Pill(
          null,
          txEx.getStatusDisplayString(),
          count: 0,
          backgroundColor: txEx.getStatusDisplayColor(),
        ),
        title: const Text('Status'),
        leading: const Icon(
          CupertinoIcons.circle,
          //color: txEx.getStatusDisplayColor(),
          size: 28,
        ),
      ),
    );

    String feeAmount = KarmaCoinAmountFormatter.formatMinimal(txEx.txBody.fee);
    String feeUsdEstimate =
        KarmaCoinAmountFormatter.formatUSDEstimate(txEx.txBody.fee);

    tiles.add(
      CupertinoListTile.notched(
        title:
            Text('Fee', style: CupertinoTheme.of(context).textTheme.textStyle),
        trailing: Text(feeAmount,
            style: CupertinoTheme.of(context).textTheme.textStyle),
        subtitle: Text(feeUsdEstimate),
        leading: const Icon(CupertinoIcons.money_dollar, size: 28),
      ),
    );

    return CupertinoListSection.insetGrouped(children: tiles);
  }

  @override
  build(BuildContext context) {
    return Title(
      color: CupertinoColors.black,
      title: 'Karmachain - ${widget.title!}',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              CupertinoSliverNavigationBar(
                  largeTitle: Text(
                    widget.title!,
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .navLargeTitleTextStyle
                        .merge(
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                  ),
                  backgroundColor: kcPurple,
                  border: kcNavBarBorder),
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
