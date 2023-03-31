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
import 'package:karmachain_dash/ui/widgets/pill.dart';
import 'package:status_alert/status_alert.dart';
import 'package:quiver/collection.dart';

// Display list of transactions for provided account id or for a block
class AccountScreen extends StatefulWidget {
  final String? accountId;

  const AccountScreen({super.key, this.accountId});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  _AccountScreenState();

  // we assume api is available until we know otherwise
  bool apiOffline = false;

  // we assume tx is null until we know otherwise
  List<SignedTransactionWithStatus>? txs;

  List<int>? accountId;
  User? user;

  @override
  void initState() {
    super.initState();
    apiOffline = false;

    Future.delayed(Duration.zero, () async {
      try {
        List<int> id = widget.accountId!.toHex();
        GetUserInfoByAccountResponse resp = await api.apiServiceClient
            .getUserInfoByAccount(
                GetUserInfoByAccountRequest(accountId: AccountId(data: id)));

        if (!resp.hasUser()) {
          throw 'User not found';
        }

        GetTransactionsResponse txsResp = await api.apiServiceClient
            .getTransactions(
                GetTransactionsRequest(accountId: AccountId(data: id)));

        setState(() {
          accountId = id;
          user = resp.user;
          txs = txsResp.transactions;
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

    if (user == null) {
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

    List<CupertinoListSection> screenSections = [];

    if (user != null) {
      screenSections.add(_getUserSection(context));
      screenSections.add(_getKarmaSection(context));
    }

    for (SignedTransactionWithStatus tx in txs!) {
      SignedTransactionWithStatusEx txEx =
          SignedTransactionWithStatusEx(tx, null);

      screenSections.add(_getTxSection(txEx));
    }

    return screenSections;
  }

  CupertinoListSection _getKarmaSection(BuildContext context) {
    List<CupertinoListTile> tiles = [];

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Karma Score'),
        trailing: Text(
          user!.karmaScore.toString(),
          style: CupertinoTheme.of(context).textTheme.textStyle,
        ),
        leading: const Icon(
          CupertinoIcons.circle,
          size: 18,
        ),
      ),
    );

    // display non-commnity traits
    for (TraitScore ts in user!.traitScores) {
      if (ts.communityId != 0) {
        continue;
      }

      PersonalityTrait trait = GenesisConfig.personalityTraits[ts.traitId];

      String title = trait.name.toLowerCase();
      String emoji = trait.emoji;

      tiles.add(
        CupertinoListTile.notched(
          title: Text(
            title,
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),
          trailing: Text(ts.score.toString(),
              style: CupertinoTheme.of(context).textTheme.textStyle),
          leading: Text(
            emoji,
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                TextStyle(
                    fontSize: 20,
                    color:
                        CupertinoTheme.of(context).textTheme.textStyle.color)),
          ),
        ),
      );

      // todo: add block for each community user has a score in!
    }

    return CupertinoListSection.insetGrouped(
        header: const Text('Karma'), children: tiles);
  }

  CupertinoListSection _getUserSection(BuildContext context) {
    List<CupertinoListTile> tiles = [];

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('User Name'),
        trailing: Text(
          user!.userName,
          style: CupertinoTheme.of(context).textTheme.textStyle,
        ),
        leading: const Icon(
          CupertinoIcons.person,
          size: 24,
        ),
      ),
    );

    // todo: add time of signup based on signup transaction time stamp

    final phoneNumber = user!.mobileNumber.number.formatPhoneNumber();

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Phone Number'),
        trailing: Text(
          '+$phoneNumber',
          style: CupertinoTheme.of(context).textTheme.textStyle,
        ),
        leading: const Icon(
          CupertinoIcons.phone,
          size: 24,
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Account Id'),
        trailing: Expanded(
          child: Text(
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 4,
            user!.accountId.data.toHexString(),
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),
        ),
        leading: const Icon(
          CupertinoIcons.creditcard,
          size: 24,
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Balance'),
        trailing: Text(
          KarmaCoinAmountFormatter.format(
            user!.balance,
          ),
          style: CupertinoTheme.of(context).textTheme.textStyle,
        ),
        leading: const Icon(
          CupertinoIcons.money_dollar,
          size: 24,
        ),
      ),
    );

    return CupertinoListSection.insetGrouped(
        header: const Text('Account'), children: tiles);
  }

  // todo: use tx widget to return this as this is duplicated in block
  CupertinoListSection _getTxSection(SignedTransactionWithStatusEx txEx) {
    List<CupertinoListTile> tiles = [];

    PaymentTransactionV1? paymentData = txEx.getPaymentData();

    final User fromUser = txEx.getFromUser();
    final fromUserPhoneNumber =
        fromUser.mobileNumber.number.formatPhoneNumber();

    bool incoming = true;
    if (listsEqual(fromUser.accountId.data, user!.accountId.data)) {
      incoming = false;
    }

    tiles.add(
      CupertinoListTile.notched(
        title: Text(
          txEx.getTransactionTypeDisplayNameWithDirection(incoming),
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(TextStyle(
              color: CupertinoTheme.of(context).textTheme.textStyle.color)),
        ),
        leading: incoming
            ? const Icon(
                CupertinoIcons.arrow_left,
                size: 30,
              )
            : const Icon(
                CupertinoIcons.arrow_right,
                size: 30,
              ),
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

    // from
    tiles.add(
      CupertinoListTile.notched(
          title: Text('From',
              style: CupertinoTheme.of(context).textTheme.textStyle),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fromUser.userName),
              Text(fromUser.accountId.data.toShortHexString()),
              const SizedBox(height: 6),
            ],
          ),
          trailing: Text('+$fromUserPhoneNumber',
              style: CupertinoTheme.of(context).textTheme.textStyle),
          leading: const Icon(CupertinoIcons.arrow_right, size: 28),
          onTap: () {
            if (incoming) {
              context.pushNamed(ScreenNames.user,
                  params: {'accountId': fromUser.accountId.data.toHexString()});
            }
          }),
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
          trailing: Text('+$toUserPhoneNumber',
              style: CupertinoTheme.of(context).textTheme.textStyle),
          leading: const Icon(CupertinoIcons.arrow_left, size: 28),
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
      title: 'Karmachain - User Profile',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              const CupertinoSliverNavigationBar(
                largeTitle: Text('User Profile'),
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
