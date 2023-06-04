import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:sweyer/sweyer.dart';

import 'package:sweyer/constants.dart' as constants;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsRoute extends StatefulWidget {
  const SettingsRoute({Key? key}) : super(key: key);
  @override
  _SettingsRouteState createState() => _SettingsRouteState();
}

class _SettingsRouteState extends State<SettingsRoute> {
  void _handleClickGeneralSettings() {
    AppRouter.instance.goto(AppRoutes.generalSettings);
  }

  void _handleClickThemeSettings() {
    AppRouter.instance.goto(AppRoutes.themeSettings);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitleMarquee(text: l10n.settings),
        leading: const NFBackButton(),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 10.0),
              children: <Widget>[
                DrawerMenuItem(
                  l10n.general,
                  icon: Icons.build_rounded,
                  iconSize: 25.0,
                  fontSize: 16.0,
                  onTap: _handleClickGeneralSettings,
                ),
                DrawerMenuItem(
                  l10n.theme,
                  icon: Icons.palette_rounded,
                  iconSize: 25.0,
                  fontSize: 16.0,
                  onTap: _handleClickThemeSettings,
                ),
              ],
            ),
          ),
          const _Footer(),
        ],
      ),
    );
  }
}

class _Footer extends StatefulWidget {
  const _Footer({Key? key}) : super(key: key);

  @override
  _FooterState createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  /// The amount of clicks to enter the dev mode
  static const int clicksForDevMode = 10;

  int _clickCount = 0;
  String appVersion = '';

  String get appName {
    return '${constants.Config.applicationTitle}@$appVersion';
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        appVersion = '${info.version}+${info.buildNumber}';
      });
    }
  }

  void _handleGithubTap() {
    final url = Uri.parse(constants.Config.githubRepoUrl);
    launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  void _handleLicenseTap() {
    AppRouter.instance.goto(AppRoutes.licenses);
  }

  void _handleSecretLogoClick() {
    if (Prefs.devMode.get()) {
      return;
    }
    final int remainingClicks = clicksForDevMode - 1 - _clickCount;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final theme = Theme.of(context);
    final textStyle = TextStyle(
      fontSize: 15.0,
      color: theme.colorScheme.onError,
    );
    final l10n = getl10n(context);
    if (remainingClicks < 0) {
      return;
    } else if (remainingClicks == 0) {
      Prefs.devMode.set(true);
      NFSnackbarController.showSnackbar(
        NFSnackbarEntry(
          important: true,
          duration: const Duration(seconds: 7),
          child: NFSnackbar(
            leading: Icon(
              Icons.adb_rounded,
              color: Colors.white,
              size: NFConstants.iconSize * textScaleFactor,
            ),
            title: Text(l10n.devModeGreet, style: textStyle),
            color: constants.AppColors.androidGreen,
          ),
        ),
      );
    } else if (_clickCount == 4) {
      NFSnackbarController.showSnackbar(
        NFSnackbarEntry(
          important: true,
          child: NFSnackbar(
            title: Text(l10n.onThePathToDevMode, style: textStyle),
            color: constants.AppColors.androidGreen,
          ),
        ),
      );
    } else if (remainingClicks < 5) {
      NFSnackbarController.showSnackbar(
        NFSnackbarEntry(
          important: true,
          child: NFSnackbar(
            title: Text(
              l10n.onThePathToDevModeClicksRemaining(remainingClicks),
              style: textStyle,
            ),
            color: constants.AppColors.androidGreen,
          ),
        ),
      );
    }

    _clickCount++;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 40.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 2.5, right: 2.5),
                child: NFIconButton(
                  icon: const SweyerLogo(),
                  splashColor: theme.colorScheme.primary,
                  size: 60.0,
                  iconSize: 42.0,
                  onPressed: _handleSecretLogoClick,
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: theme.textTheme.titleLarge!.color,
                      ),
                    ),
                    Text(
                      'Copyright (c) 2019, nt4f04uNd',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(height: 1.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _handleGithubTap,
            child: Text(
              getl10n(context).gitHubRepo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          GestureDetector(
            onTap: _handleLicenseTap,
            child: Text(
              MaterialLocalizations.of(context).licensesPageTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
