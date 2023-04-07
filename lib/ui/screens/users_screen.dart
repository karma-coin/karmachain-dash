import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karmachain_dash/common_libs.dart';
import 'package:karmachain_dash/services/api/types.pb.dart';
import 'package:karmachain_dash/ui/helpers/widget_utils.dart';
import 'package:karmachain_dash/ui/router.dart';
import 'package:status_alert/status_alert.dart';
import 'package:karmachain_dash/services/api/api.pbgrpc.dart';

/// Display user details for provided user or for local user
class Users extends StatefulWidget {
  /// Set user to display] details for or null for local user
  const Users({super.key});

  @override
  State<Users> createState() => _UsersState();
}

class _UsersState extends State<Users> {
  _UsersState();

  List<User> users = [];

  bool apiOffline = false;

  @override
  void initState() {
    super.initState();
    apiOffline = false;

    Future.delayed(Duration.zero, () async {
      try {
        GetAllUsersResponse resp =
            await api.apiServiceClient.getAllUsers(GetAllUsersRequest());
        setState(() {
          users = resp.users;
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
        debugPrint('error getting users: $e');
      }
    });
  }

  /// Return the list secionts
  List<CupertinoListSection> _getSections(BuildContext context) {
    List<CupertinoListTile> tiles = [];
    if (!apiOffline && users.isEmpty) {
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

    for (User user in users) {
      tiles.add(_getUserTile(context, user, true));
    }

    return [
      CupertinoListSection.insetGrouped(
        children: tiles,
      ),
    ];
  }

  CupertinoListTile _getUserTile(
      BuildContext context, User user, bool tapable) {
    return CupertinoListTile.notched(
        onTap: () {
          if (!tapable) return;
          context.pushNamed(ScreenNames.user,
              params: {'accountId': user.accountId.data.toHexString()});
        },
        leading: const Icon(CupertinoIcons.person, size: 24),
        padding:
            const EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 12),
        trailing: const CupertinoListTileChevron(),
        title: Text(user.userName,
            style: CupertinoTheme.of(context).textTheme.textStyle));
  }

  @override
  build(BuildContext context) {
    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Karmachain Users',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              CupertinoSliverNavigationBar(
                  largeTitle: Text(
                    'Karmachain Users',
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
