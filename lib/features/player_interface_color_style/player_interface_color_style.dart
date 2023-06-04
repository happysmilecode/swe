import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as constants;

export 'player_interface_color_style_builders.dart';

enum PlayerInterfaceColorStyle {
  artColor,
  themeBackgroundColor,
}

Color _shadeForSecondaryColor(Color color) {
  return shadeColor(
    0.3,
    color,
    minBit: 15,
  );
}

class PlayerInterfaceColorStyleControl extends Control {
  static PlayerInterfaceColorStyleControl instance = PlayerInterfaceColorStyleControl();

  late ValueNotifier<PaletteGenerator?> _currentPalette;
  late ValueNotifier<Color> _currentBackgroundColor;
  ValueListenable<Color> get currentBackgroundColor => _currentBackgroundColor;

  @override
  void init() {
    super.init();
    _currentPalette = ValueNotifier(null);
    _currentBackgroundColor = ValueNotifier(Colors.black);
    _updatePalette(staticTheme, null);
    Settings.playerInterfaceColorStyle.addListener(_handlePlayerInterfaceStyle);
  }

  @override
  void dispose() {
    if (disposed.value) {
      return;
    }
    _currentPalette.dispose();
    _currentBackgroundColor.dispose();
    Settings.playerInterfaceColorStyle.removeListener(_handlePlayerInterfaceStyle);
    super.dispose();
  }

  SystemUiOverlayStyle get systemUiOverlayStyle {
    final systemNavigationBarColorTween = ColorTween(
      begin: staticTheme.systemUiThemeExtension.grey.systemNavigationBarColor,
      end: staticTheme.systemUiThemeExtension.black
          .copyWith(
            systemNavigationBarColor: PlayerInterfaceColorStyleControl.instance.currentBackgroundColor.value,
          )
          .systemNavigationBarColor,
    );
    return SystemUiStyleController.instance.lastUi.copyWith(
      systemNavigationBarColor: systemNavigationBarColorTween.evaluate(playerRouteController),
    );
  }

  SystemUiOverlayStyle get systemUiOverlayStyleForSelection {
    return SystemUiStyleController.instance.lastUi.copyWith(
      systemNavigationBarColor: _shadeForSecondaryColor(
        PlayerInterfaceColorStyleControl.instance.currentBackgroundColor.value,
      ),
    );
  }

  void updatePalette(ThemeData theme, PaletteGenerator? value) {
    _updatePalette(theme, value);
    _handleCurrentBackgroundColor();
  }

  void _updatePalette(ThemeData theme, PaletteGenerator? value) {
    _currentPalette.value = value;
    _currentBackgroundColor.value = shadeColor(
      -0.5,
      value?.vibrantColor?.color ?? value?.dominantColor?.color ?? theme.colorScheme.background,
    );
  }

  void _handlePlayerInterfaceStyle() {
    switch (Settings.playerInterfaceColorStyle.value) {
      case PlayerInterfaceColorStyle.artColor:
        break;
      case PlayerInterfaceColorStyle.themeBackgroundColor:
        updatePalette(staticTheme, null);
        break;
    }
  }

  void _handleCurrentBackgroundColor() {
    if (!playerRouteControllerInitialized) {
      return;
    }
    if (AppRouter.instance.currentRoute.hasSameLocation(AppRoutes.initial) ||
        AppRouter.instance.currentRoute.hasSameLocation(AppRoutes.selection)) {
      SystemUiStyleController.instance.animateSystemUiOverlay(
        to: PlayerInterfaceColorStyleControl.instance.systemUiOverlayStyle,
        duration: _ArtColorWidget.duration,
        curve: _ArtColorWidget.curve,
      );
    }
  }
}

/// Allows to choose the [PlayerInterfaceColorStyle].
class PlayerInterfaceColorStyleSettingWidget extends StatelessWidget {
  const PlayerInterfaceColorStyleSettingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return PlayerInterfaceColorStyleSettingBuilder(
      builder: (context, value, child) => ListTile(
        title: Text(l10n.playerInterfaceColorStyle),
        subtitle: Text(l10n.getPlayerInterfaceColorStyleValue(value)),
        onTap: () {
          ShowFunctions.instance.showRadio<PlayerInterfaceColorStyle>(
            context: context,
            title: l10n.playerInterfaceColorStyle,
            items: PlayerInterfaceColorStyle.values,
            itemTitleBuilder: (item) => l10n.getPlayerInterfaceColorStyleValue(item),
            onItemSelected: (item) => Settings.playerInterfaceColorStyle.set(item),
            groupValueGetter: () => Settings.playerInterfaceColorStyle.value,
          );
        },
      ),
    );
  }
}

/// A shorthand builder for [Settings.playerInterfaceColorStyle].
class PlayerInterfaceColorStyleSettingBuilder extends StatelessWidget {
  const PlayerInterfaceColorStyleSettingBuilder({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  final ValueWidgetBuilder<PlayerInterfaceColorStyle> builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayerInterfaceColorStyle>(
      valueListenable: Settings.playerInterfaceColorStyle,
      builder: builder,
      child: child,
    );
  }
}

class PlayerInterfaceThemeOverride extends StatelessWidget {
  const PlayerInterfaceThemeOverride({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  static ThemeData _getTheme(BuildContext context, Color backgroundColor) {
    final theme = Theme.of(context);
    switch (Settings.playerInterfaceColorStyle.value) {
      case PlayerInterfaceColorStyle.artColor:
        return theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: Colors.white,
            onSurface: Colors.white,
            secondary: _shadeForSecondaryColor(backgroundColor),
            onBackground: Colors.white,
            background: backgroundColor,
          ),
          appBarTheme: theme.appBarTheme.copyWith(
            color: _shadeForSecondaryColor(backgroundColor),
          ),
          tooltipTheme: theme.tooltipTheme.copyWith(
            textStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(
                Radius.circular(100.0),
              ),
            ),
          ),
          textTheme: constants.Theme.app.dark.textTheme,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          splashColor: constants.Theme.lightThemeSplashColor,
          disabledColor: Colors.grey.shade400,
          unselectedWidgetColor: Colors.grey.shade400,
          extensions: [
            theme.appThemeExtension.copyWith(
              currentIndicatorBackgroundColorWithDefaultArt: Colors.transparent,
            ),
            theme.systemUiThemeExtension,
          ],
        );
      case PlayerInterfaceColorStyle.themeBackgroundColor:
        return theme;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlayerInterfaceColorStyleSettingBuilder(
      child: child,
      builder: (context, value, child) => ValueListenableBuilder<Color>(
        child: child,
        valueListenable: PlayerInterfaceColorStyleControl.instance.currentBackgroundColor,
        builder: (context, backgroundColor, child) {
          final theme = _getTheme(context, backgroundColor);
          return Theme(
            data: theme,
            child: child!,
          );
        },
      ),
    );
  }
}

/// A background to be used by [PlayerRoute].
class PlayerInterfaceColorWidget extends StatelessWidget {
  const PlayerInterfaceColorWidget({
    Key? key,
    this.child,
    this.color,
  }) : super(key: key);

  final Widget? child;
  final ValueGetter<Color?>? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PlayerInterfaceColorStyleSettingBuilder(
      child: child,
      builder: (context, value, child) {
        switch (value) {
          case PlayerInterfaceColorStyle.artColor:
            return _ArtColorWidget(
              child: child,
              color: color,
            );
          case PlayerInterfaceColorStyle.themeBackgroundColor:
            return Container(
              color: color?.call() ?? theme.colorScheme.background,
              child: child,
            );
        }
      },
    );
  }
}

class _ArtColorWidget extends StatelessWidget {
  const _ArtColorWidget({
    Key? key,
    required this.child,
    required this.color,
  }) : super(key: key);

  final Widget? child;
  final ValueGetter<Color?>? color;

  static const duration = Duration(milliseconds: 240);
  static const curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      child: child,
      valueListenable: PlayerInterfaceColorStyleControl.instance.currentBackgroundColor,
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: duration,
          curve: curve,
          color: color?.call() ?? value,
          child: child,
        );
      },
    );
  }
}

/// Provides a [ContentArt.onLoad] function.
class ContentArtLoadBuilder extends StatelessWidget {
  const ContentArtLoadBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  final Widget Function(ContentArtOnLoadCallback? onLoad) builder;

  @override
  Widget build(BuildContext context) {
    return PlayerInterfaceColorStyleSettingBuilder(
      builder: (context, value, child) {
        switch (value) {
          case PlayerInterfaceColorStyle.artColor:
            return Consumer(
              builder: (context, ref, child) {
                final playerInterfaceColorStyleArtColorBuilder =
                    ref.watch(playerInterfaceColorStyleArtColorBuilderProvider);
                return builder(playerInterfaceColorStyleArtColorBuilder.buildOnLoad(context));
              },
            );
          case PlayerInterfaceColorStyle.themeBackgroundColor:
            return builder(null);
        }
      },
    );
  }
}
