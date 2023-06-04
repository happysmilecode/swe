import 'dart:math' as math;

import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:tuple/tuple.dart';

const double _tileVerticalPadding = 8.0;
const double kPersistentQueueTileHorizontalPadding = 16.0;
const double _gridArtSize = 220.0;
const double _gridArtAssetScale = 1.2;
const double _gridCurrentIndicatorScale = 1.7;

TextStyle? _titleTheme(ThemeData theme) => theme.textTheme.titleLarge;
TextStyle? _subtitleTheme(ContentType contentType, ThemeData theme) => contentType == ContentType.album
    ? ArtistWidget.defaultTextStyle(theme)?.merge(const TextStyle(fontSize: 14.0, height: 1.0))
    : theme.textTheme.titleSmall?.merge(const TextStyle(fontSize: 14.0, height: 1.0));

/// Needed for scrollbar computations.
double kPersistentQueueTileHeight(ContentType contentType, BuildContext context) {
  switch (contentType) {
    case ContentType.song:
    case ContentType.artist:
      throw ArgumentError();
    case ContentType.album:
    case ContentType.playlist:
      return _calculatePersistentQueueTileHeight(contentType, context);
  }
}

double kPersistentQueueGridTileHeight(
  ContentType contentType,
  BuildContext context, [
  double gridArtSize = _gridArtSize,
]) =>
    _calculatePersistentQueueGridTileHeight(
      contentType,
      context,
      gridArtSize,
    );

double _calculatePersistentQueueTileHeight(ContentType contentType, BuildContext context) {
  final textScaleFactor = MediaQuery.of(context).textScaleFactor;
  final theme = Theme.of(context);
  return _calculatePersistentQueueTileHeightMemo(
    textScaleFactor,
    _titleTheme(theme)?.fontSize,
    _subtitleTheme(contentType, theme)?.fontSize,
    Tuple2(contentType, context),
  );
}

final _calculatePersistentQueueTileHeightMemo = imemo3plus1(
  (
    double a1,
    double? a2,
    double? a3,
    Tuple2<ContentType, BuildContext> a4,
  ) =>
      math.max(
        kPersistentQueueTileArtSize,
        _kPresisentQueueTileTextHeight(a4.item1, a4.item2),
      ) +
      _tileVerticalPadding * 2,
);

double _calculatePersistentQueueGridTileHeight(
  ContentType contentType,
  BuildContext context,
  double gridArtSize,
) {
  final textScaleFactor = MediaQuery.of(context).textScaleFactor;
  final theme = Theme.of(context);
  return _calculatePersistentQueueGridTileHeightMemo(
    textScaleFactor,
    gridArtSize,
    _titleTheme(theme)?.fontSize,
    _subtitleTheme(contentType, theme)?.fontSize,
    Tuple2(contentType, context),
  );
}

final _calculatePersistentQueueGridTileHeightMemo = imemo4plus1(
  (
    double a1,
    double gridArtSize,
    double? a3,
    double? a4,
    Tuple2<ContentType, BuildContext> a5,
  ) =>
      gridArtSize + _kPresisentQueueTileTextHeight(a5.item1, a5.item2) + _tileVerticalPadding * 2,
);

/// The height of the title and subtitle part of the [PersistentQueueTile].
double _kPresisentQueueTileTextHeight(ContentType contentType, BuildContext context) {
  final textScaleFactor = MediaQuery.of(context).textScaleFactor;
  final theme = Theme.of(context);
  return calculateLineHeight(_titleTheme(theme), textScaleFactor) +
      calculateLineHeight(_subtitleTheme(contentType, theme), textScaleFactor);
}

class PersistentQueueTile<T extends PersistentQueue> extends SelectableWidget<SelectionEntry> {
  const PersistentQueueTile({
    Key? key,
    required this.queue,
    this.trailing,
    this.current,
    this.onTap,
    this.enableDefaultOnTap = true,
    this.small = false,
    this.grid = false,
    this.gridArtSize = _gridArtSize,
    this.gridArtAssetScale = _gridArtAssetScale,
    this.gridCurrentIndicatorScale = _gridCurrentIndicatorScale,
    double? horizontalPadding,
    this.backgroundColor = Colors.transparent,
  })  : assert(!grid || !small),
        horizontalPadding =
            horizontalPadding ?? (small ? kSongTileHorizontalPadding : kPersistentQueueTileHorizontalPadding),
        super(key: key);

  const PersistentQueueTile.selectable({
    Key? key,
    required this.queue,
    required int selectionIndex,
    required SelectionController<SelectionEntry>? selectionController,
    bool selected = false,
    bool longPressSelectionGestureEnabled = true,
    bool handleTapInSelection = true,
    this.trailing,
    this.current,
    this.onTap,
    this.enableDefaultOnTap = true,
    this.small = false,
    this.grid = false,
    this.gridArtSize = _gridArtSize,
    this.gridArtAssetScale = _gridArtAssetScale,
    this.gridCurrentIndicatorScale = _gridCurrentIndicatorScale,
    double? horizontalPadding,
    this.backgroundColor = Colors.transparent,
  })  : assert(selectionController is SelectionController<SelectionEntry<Content>> ||
            selectionController is SelectionController<SelectionEntry<T>>),
        assert(!grid || !small),
        horizontalPadding =
            horizontalPadding ?? (small ? kSongTileHorizontalPadding : kPersistentQueueTileHorizontalPadding),
        super.selectable(
          key: key,
          selectionIndex: selectionIndex,
          selected: selected,
          longPressSelectionGestureEnabled: longPressSelectionGestureEnabled,
          handleTapInSelection: handleTapInSelection,
          selectionController: selectionController,
        );

  final T queue;

  /// Widget to be rendered at the end of the tile.
  final Widget? trailing;

  /// Whether this queue is currently playing, if yes, enables animated
  /// [CurrentIndicator] over the album art.
  ///
  /// If not specified, by default uses [ContentUtils.originIsCurrent].
  final bool? current;
  final VoidCallback? onTap;

  /// Whether to handle taps by default.
  /// By default opens the [PersistentQueueRoute].
  final bool enableDefaultOnTap;

  /// Creates a small variant of the tile with the sizes of [SelectableTile].
  final bool small;

  /// When `true`, will create a tile suitable to be shown in grid.
  /// The [small] must be `false` when this is `true`.
  final bool grid;

  /// The size of the art when [grid] is `true`.
  final double gridArtSize;

  /// Value passed to [ContentArt.assetScale] when [grid] is `true`.
  final double gridArtAssetScale;

  /// Value passed to [ContentArt.currentIndicatorScale] when [grid] is `true`.
  final double gridCurrentIndicatorScale;

  /// Tile horizontal padding. Ignored when [grid] is `true`.
  final double horizontalPadding;

  /// Background tile color.
  /// By default tile background is transparent.
  final Color? backgroundColor;

  @override
  _PersistentQueueTileState<T> createState() => _PersistentQueueTileState();
}

class _PersistentQueueTileState<T extends PersistentQueue>
    extends SelectableState<SelectionEntry<T>, PersistentQueueTile<T>> with ContentTileComponentsMixin {
  @override
  SelectionEntry<T> toSelectionEntry() => SelectionEntry<T>.fromContent(
        content: widget.queue,
        index: widget.selectionIndex!,
        context: context,
      );

  void _handleTap() {
    super.handleTap(() {
      widget.onTap?.call();
      HomeRouter.of(context).goto(HomeRoutes.factory.persistentQueue<T>(widget.queue));
    });
  }

  bool get current {
    if (widget.current != null) {
      return widget.current!;
    }
    return ContentUtils.originIsCurrent(widget.queue);
  }

  Widget _buildInfo() {
    final theme = Theme.of(context);
    final List<Widget> children = [
      Text(
        widget.queue.title,
        overflow: TextOverflow.ellipsis,
        style: _titleTheme(theme),
      ),
    ];
    final queue = widget.queue;
    if (queue is Album) {
      children.add(ArtistWidget(
        artist: queue.artist,
        trailingText: queue.year.toString(),
        textStyle: _subtitleTheme(widget.queue.type, theme),
      ));
    } else if (queue is Playlist) {
      final l10n = getl10n(context);
      children.add(Text(
        l10n.contentsPlural(ContentType.song, queue.length),
        style: _subtitleTheme(widget.queue.type, theme),
      ));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildTile() {
    final theme = Theme.of(context);
    final source = ContentArtSource.persistentQueue(widget.queue);

    final Widget child;
    if (widget.grid) {
      child = SizedBox(
        width: widget.gridArtSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ContentArt(
              size: widget.gridArtSize,
              defaultArtIconScale: (widget.gridArtSize / kPersistentQueueTileArtSize) / 1.5,
              defaultArtIcon: ContentUtils.defaultIconForPlaylistArt(widget.queue),
              assetHighRes: true,
              currentIndicatorScale: widget.gridCurrentIndicatorScale,
              assetScale: widget.gridArtAssetScale,
              source: source,
              current: current,
            ),
            _buildInfo(),
          ],
        ),
      );
    } else {
      child = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.horizontalPadding,
          vertical: _tileVerticalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: widget.small
                  ? ContentArt.songTile(
                      source: source,
                      defaultArtIcon: ContentUtils.defaultIconForPlaylistArt(widget.queue),
                      current: current,
                    )
                  : ContentArt.persistentQueueTile(
                      source: source,
                      defaultArtIcon: ContentUtils.defaultIconForPlaylistArt(widget.queue),
                      current: current,
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: _buildInfo(),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FavoriteIndicator(shown: widget.queue.isFavorite),
                if (widget.trailing != null) widget.trailing!,
                if (selectionRoute) buildAddToSelection(),
              ],
            ),
          ],
        ),
      );
    }

    final onTap =
        widget.enableDefaultOnTap || selectable && widget.selectionController!.inSelection ? _handleTap : widget.onTap;

    if (widget.grid) {
      return Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: CustomBoxy(
              delegate: _BoxyDelegate(
                () => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    splashColor: theme.appThemeExtension.glowSplashColor,
                    onLongPress: handleLongPress,
                    splashFactory: _InkRippleFactory(artSize: widget.gridArtSize),
                  ),
                ),
              ),
              children: [
                LayoutId(id: #tile, child: child),
              ],
            ),
          ),
        ],
      );
    }
    return InkWell(
      onTap: onTap,
      onLongPress: handleLongPress,
      splashFactory: NFListTileInkRipple.splashFactory,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!selectable) {
      return _buildTile();
    }

    const checkmarkGridMargin = 10.0;
    const favoriteIndicatorMargin = 17.0;
    const favoriteIndicatorLargeSize = 28.0;
    final theme = Theme.of(context);
    final artSize = widget.grid ? widget.gridArtSize : kPersistentQueueTileArtSize;
    return Stack(
      children: [
        _buildTile(),
        if (!selectionRoute)
          if (animation.status == AnimationStatus.dismissed)
            const SizedBox.shrink()
          else
            Positioned(
              left: artSize + (widget.grid ? -checkmarkLargeSize - checkmarkGridMargin : 2.0),
              top: artSize + (widget.grid ? -checkmarkLargeSize - checkmarkGridMargin : -7.0),
              child: buildSelectionCheckmark(forceLarge: widget.grid),
            )
        else if (widget.grid)
          Positioned(
            top: (widget.gridArtSize - AddToSelectionButton.size - checkmarkGridMargin).clamp(0.0, double.infinity),
            // 8 padding is already in `buildAddToSelection`, so add 10 more to reach `checkmarkMargin`
            right: 2.0,
            child: Theme(
              data: theme.copyWith(
                // TODO: probably add some dimming so it's better seen no matter the picture?
                iconTheme: theme.iconTheme.copyWith(color: Colors.white),
              ),
              child: buildAddToSelection(),
            ),
          ),
        if (widget.grid)
          Positioned(
            left: selectionRoute ? 14.0 : 2.0,
            top: selectionRoute
                ? widget.gridArtSize - favoriteIndicatorLargeSize - favoriteIndicatorMargin * 1.5
                : widget.gridArtSize - favoriteIndicatorLargeSize - favoriteIndicatorMargin,
            child: FavoriteIndicator(
              shown: widget.queue.isFavorite,
              size: favoriteIndicatorLargeSize,
            ),
          ),
      ],
    );
  }
}

class _BoxyDelegate extends BoxyDelegate {
  _BoxyDelegate(this.builder);
  final ValueGetter<Widget> builder;

  @override
  Size layout() {
    final tile = getChild(#tile);
    final tileSize = tile.layout(constraints);

    final ink = inflate(builder(), id: #ink);
    ink.layout(constraints.tighten(
      width: tileSize.width,
      height: tileSize.height,
    ));

    return Size(
      tileSize.width,
      tileSize.height,
    );
  }
}

class _InkRippleFactory extends InteractiveInkFeatureFactory {
  const _InkRippleFactory({required this.artSize});

  final double artSize;

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    return NFListTileInkRipple(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      containedInkWell: containedInkWell,
      rectCallback: () => Offset.zero & Size(artSize, artSize),
      borderRadius: const BorderRadius.all(Radius.circular(kArtBorderRadius)),
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
      textDirection: textDirection,
    );
  }
}
