import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karmachain_dash/services/api/api.pb.dart';
import 'package:karmachain_dash/services/api/types.pb.dart';
import 'package:karmachain_dash/ui/helpers/widget_utils.dart';
import 'package:karmachain_dash/common_libs.dart';
import 'package:karmachain_dash/ui/router.dart';
import 'package:status_alert/status_alert.dart';

class LeaderboardScreen extends StatefulWidget {
  final int communityId;

  const LeaderboardScreen({super.key, this.communityId = 0});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

const _karmaRewardsInfoUrl = 'https://karmaco.in/karmarewards/';

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  // we assume api is available until we know otherwise
  bool apiOffline = false;

  List<LeaderboardEntry>? entries;

  BlockchainStats? blockchainStats;

  @override
  initState() {
    super.initState();
    apiOffline = false;

    Future.delayed(Duration.zero, () async {
      try {
        debugPrint('getting leaderboard data...');
        GetLeaderBoardResponse resp =
            await api.apiServiceClient.getLeaderBoard(GetLeaderBoardRequest());

        GetBlockchainDataResponse statsResponse = await api.apiServiceClient
            .getBlockchainData(GetBlockchainDataRequest());

        // debugPrint('got entries: ${resp.leaderboardEntries}');

        List<LeaderboardEntry> newEntries = resp.leaderboardEntries;

        setState(() {
          debugPrint('setting entries: $newEntries');
          blockchainStats = statsResponse.stats;
          entries = newEntries;
        });
      } catch (e) {
        setState(() {
          apiOffline = true;
        });
        if (!mounted) return;
        StatusAlert.show(context,
            duration: const Duration(seconds: 2),
            title: 'Server Error',
            subtitle: 'Please try later',
            configuration: const IconConfiguration(
                icon: CupertinoIcons.exclamationmark_triangle),
            dismissOnBackgroundTap: true,
            maxWidth: statusAlertWidth);
        debugPrint('error getting leaderboard data: $e');
      }
    });
  }

  Widget _getBodyContent(BuildContext context) {
    if (apiOffline) {
      return Padding(
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: Center(
          child: Text(
              'The Karma Coin Server is down.\n\nPlease try again later.',
              textAlign: TextAlign.center,
              style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
        ),
      );
    }

    if (entries == null) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    List<Widget> widgets = [];

    widgets.add(Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
        child: Text(
            'People eligable for the next round of karma rewards minting.',
            textAlign: TextAlign.center,
            style: CupertinoTheme.of(context).textTheme.pickerTextStyle)));

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 8),
        child: CupertinoButton(
            child: const Text('Learn more...'),
            onPressed: () {
              openUrl(_karmaRewardsInfoUrl);
            }),
      ),
    );

    if (entries != null) {
      if (entries!.isNotEmpty) {
        widgets.add(_getLeadersWidget(context));
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 64, bottom: 36),
            child: Center(
              child: Text('😞 No one is eligable yet.',
                  textAlign: TextAlign.center,
                  style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 24),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets),
    );
  }

  Widget _getLeadersWidget(BuildContext context) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 24),
        separatorBuilder: (context, index) {
          return const Divider(
            thickness: 1,
            indent: 0,
          );
        },
        itemCount: entries!.length,
        itemBuilder: (context, index) {
          return _getUserWidget(context, entries![index], index);
        },
      ),
    );
  }

  Widget _getUserWidget(
      BuildContext context, LeaderboardEntry entry, int index) {
// todo: add personality trait emojis from appre

    return CupertinoListTile(
      key: Key(index.toString()),
      padding: const EdgeInsets.only(top: 0, bottom: 6, left: 14, right: 14),
      title: Text(
        entry.userName,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w300,
        ),
      ),
      leading: const Icon(CupertinoIcons.person, size: 28),
      trailing: const CupertinoListTileChevron(),
      onTap: () {
        context.pushNamed(ScreenNames.user,
            params: {'accountId': entry.accountId.data.toHexString()});
      },
    );
  }

  @override
  build(BuildContext context) {
    return Title(
      color: CupertinoColors.black, // This is required
      title: 'KARMA REWARDS',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              CupertinoSliverNavigationBar(
                largeTitle: Text(
                  'Karma Rewards',
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
                border: kcNavBarBorder,
              ),
            ];
          },
          body: MediaQuery.removePadding(
            context: context,
            removeTop: false,
            child: _getBodyContent(context),
          ),
        ),
      ),
    );
  }
}
