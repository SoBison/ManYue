import 'dart:async';
import 'dart:collection';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:venera/components/components.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/foundation/appdata.dart';
import 'package:venera/foundation/comic_source/comic_source.dart';
import 'package:venera/foundation/comic_type.dart';
import 'package:venera/foundation/consts.dart';
import 'package:venera/foundation/favorites.dart';
import 'package:venera/foundation/history.dart';
import 'package:venera/foundation/image_provider/cached_image.dart';
import 'package:venera/foundation/local.dart';
import 'package:venera/foundation/res.dart';
import 'package:venera/network/download.dart';
import 'package:venera/network/cache.dart';
import 'package:venera/pages/favorites/favorites_page.dart';
import 'package:venera/pages/reader/reader.dart';
import 'package:venera/utils/app_links.dart';
import 'package:venera/utils/ext.dart';
import 'package:venera/utils/file_type.dart';
import 'package:venera/utils/io.dart';
import 'package:venera/utils/tags_translation.dart';
import 'package:venera/utils/translations.dart';
import 'dart:math' as math;

part 'comments_page.dart';

part 'chapters.dart';

part 'thumbnails.dart';

part 'favorite.dart';

part 'comments_preview.dart';

part 'actions.dart';

part 'cover_viewer.dart';

class ComicPage extends StatefulWidget {
  const ComicPage({
    super.key,
    required this.id,
    required this.sourceKey,
    this.cover,
    this.title,
    this.heroID,
  });

  final String id;

  final String sourceKey;

  final String? cover;

  final String? title;

  final int? heroID;

  @override
  State<ComicPage> createState() => _ComicPageState();
}

class _ComicPageState extends LoadingState<ComicPage, ComicDetails>
    with _ComicPageActions {
  @override
  History? history;

  bool showAppbarTitle = false;

  var scrollController = ScrollController();

  bool isDownloaded = false;

  bool showFAB = false;

  @override
  void onReadEnd() {
    history ??= HistoryManager().find(
      widget.id,
      ComicType(widget.sourceKey.hashCode),
    );
    update();
  }

  @override
  Widget buildLoading() {
    return _ComicPageLoadingPlaceHolder(
      cover: widget.cover,
      title: widget.title,
      sourceKey: widget.sourceKey,
      cid: widget.id,
      heroID: widget.heroID,
    );
  }

  @override
  Widget buildError() {
    final isDownloaded = LocalManager().isDownloaded(
      widget.id,
      ComicType.fromKey(widget.sourceKey),
    );
    Widget? action;
    if (isDownloaded) {
      action = FilledButton.tonal(
        child: Text("Read".tl),
        onPressed: () {
          final localComic = LocalManager().find(
            widget.id,
            ComicType.fromKey(widget.sourceKey),
          );
          if (localComic == null) {
            context.showMessage(message: "Local comic not found".tl);
            return;
          }
          localComic.read();
        },
      );
    }
    return NetworkError(message: error!, retry: retry, action: action);
  }

  @override
  void initState() {
    scrollController.addListener(onScroll);
    super.initState();
  }

  @override
  void dispose() {
    scrollController.removeListener(onScroll);
    super.dispose();
  }

  @override
  void update() {
    setState(() {});
  }

  @override
  ComicDetails get comic => data!;

  void onScroll() {
    var offset =
        scrollController.position.pixels -
        scrollController.position.minScrollExtent;
    var showFAB = offset > 0;
    if (showFAB != this.showFAB) {
      setState(() {
        this.showFAB = showFAB;
      });
    }
    if (offset > 100) {
      if (!showAppbarTitle) {
        setState(() {
          showAppbarTitle = true;
        });
      }
    } else {
      if (showAppbarTitle) {
        setState(() {
          showAppbarTitle = false;
        });
      }
    }
  }

  var isFirst = true;

  @override
  Widget buildContent(BuildContext context, ComicDetails data) {
    return Scaffold(
      floatingActionButton: showFAB
          ? FloatingActionButton(
              onPressed: () {
                scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease,
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
      body: SmoothCustomScrollView(
        controller: scrollController,
        slivers: [
          ...buildTitle(),
          buildActions(),
          buildDescription(),
          buildInfo(),
          buildChapters(),
          buildComments(),
          buildThumbnails(),
          buildRecommend(),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: context.padding.bottom + 80,
            ), // Add additional padding for FAB
          ),
        ],
      ),
    );
  }

  @override
  Future<Res<ComicDetails>> loadData() async {
    if (widget.sourceKey == 'local') {
      var localComic = LocalManager().find(widget.id, ComicType.local);
      if (localComic == null) {
        return const Res.error('Local comic not found');
      }
      var history = HistoryManager().find(widget.id, ComicType.local);
      if (isFirst) {
        Future.microtask(() {
          App.rootContext.to(() {
            return Reader(
              type: ComicType.local,
              cid: widget.id,
              name: localComic.title,
              chapters: localComic.chapters,
              initialPage: history?.page,
              initialChapter: history?.ep,
              initialChapterGroup: history?.group,
              history:
                  history ??
                  History.fromModel(model: localComic, ep: 0, page: 0),
              author: localComic.subTitle ?? '',
              tags: localComic.tags,
            );
          });
          App.mainNavigatorKey!.currentContext!.pop();
        });
        isFirst = false;
      }
      await Future.delayed(const Duration(milliseconds: 200));
      return const Res.error('Local comic');
    }
    var comicSource = ComicSource.find(widget.sourceKey);
    if (comicSource == null) {
      return const Res.error('Comic source not found');
    }
    isAddToLocalFav = LocalFavoritesManager().isExist(
      widget.id,
      ComicType(widget.sourceKey.hashCode),
    );
    history = HistoryManager().find(
      widget.id,
      ComicType(widget.sourceKey.hashCode),
    );
    return comicSource.loadComicInfo!(widget.id);
  }

  @override
  Future<void> onDataLoaded() async {
    isLiked = comic.isLiked ?? false;
    isFavorite = comic.isFavorite ?? false;
    // For sources with multi-folder favorites, prefer querying folders to get accurate favorite status
    // Some sources may not set isFavorite reliably when multi-folder is enabled
    if (comicSource.favoriteData?.loadFolders != null && comicSource.isLogged) {
      var res = await comicSource.favoriteData!.loadFolders!(comic.id);
      if (!res.error) {
        if (res.subData is List) {
          var list = List<String>.from(res.subData);
          isFavorite = list.isNotEmpty;
          update();
        }
      }
    }
    if (comic.chapters == null) {
      isDownloaded = LocalManager().isDownloaded(comic.id, comic.comicType, 0);
    }
  }

  Iterable<Widget> buildTitle() sync* {
    // 现代化的导航栏，带毛玻璃效果
    yield SliverAppbar(
      style: AppbarStyle.blur,
      title: AnimatedOpacity(
        opacity: showAppbarTitle ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(comic.title),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.8,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: showMoreActions,
            icon: Icon(
              Icons.more_horiz_rounded,
              size: 20,
              color: context.colorScheme.onSurface,
            ),
            tooltip: "More".tl,
          ),
        ),
      ],
    );

    // 现代化的头部区域
    yield SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colorScheme.surfaceContainer.withValues(alpha: 0.8),
              context.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.6,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: context.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // 封面和基本信息
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 现代化的封面设计
                      GestureDetector(
                        onTap: () => _viewCover(context),
                        onLongPress: () => _saveCover(context),
                        child: Hero(
                          tag: "cover${widget.heroID}",
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 160,
                                width: 160 * 0.72,
                                decoration: BoxDecoration(
                                  color: context.colorScheme.primaryContainer,
                                ),
                                child: AnimatedImage(
                                  image: CachedImageProvider(
                                    widget.cover ?? comic.cover,
                                    sourceKey: comic.sourceKey,
                                    cid: comic.id,
                                  ),
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // 标题和信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 标题
                            SelectableText(
                              comic.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: context.colorScheme.onSurface,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 副标题
                            if (comic.subTitle != null) ...[
                              SelectableText(
                                comic.subTitle!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.colorScheme.onSurfaceVariant,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            // 来源标签
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: context.colorScheme.primaryContainer
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: context.colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                (ComicSource.find(comic.sourceKey)?.name) ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // 快速统计信息
                            if (comic.likesCount != null ||
                                comic.maxPage != null) ...[
                              Row(
                                children: [
                                  if (comic.likesCount != null) ...[
                                    Icon(
                                      Icons.favorite_rounded,
                                      size: 16,
                                      color: context.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      comic.likesCount.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: context
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  if (comic.maxPage != null) ...[
                                    Icon(
                                      Icons.auto_stories_rounded,
                                      size: 16,
                                      color: context.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '@count Pages'.tlParams({'count': comic.maxPage ?? 0}),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: context
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildActions() {
    bool isMobile = context.width < changePoint;
    bool hasHistory = history != null && (history!.ep > 1 || history!.page > 1);

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // 主要操作按钮 - 现代化设计
            if (isMobile) ...[
              // 移动端主要按钮
              Row(
                children: [
                  // 下载按钮
                  if (!isDownloaded)
                    Expanded(
                      child: _ModernActionButton(
                        icon: Icons.download_rounded,
                        label: "Download".tl,
                        onPressed: download,
                        style: _ModernActionButtonStyle.secondary,
                      ),
                    ),
                  if (!isDownloaded) const SizedBox(width: 12),
                  // 阅读按钮
                  Expanded(
                    flex: 2,
                    child: _ModernActionButton(
                      icon: hasHistory
                          ? Icons.menu_book_rounded
                          : Icons.play_arrow_rounded,
                      label: hasHistory ? "Continue".tl : "Start Reading".tl,
                      onPressed: hasHistory ? continueRead : read,
                      style: _ModernActionButtonStyle.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 次要操作按钮
              Row(
                children: [
                  // 收藏按钮
                  Expanded(
                    child: _ModernActionButton(
                      icon: (isFavorite || isAddToLocalFav)
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      label: "Favorite".tl,
                      onPressed: openFavPanel,
                      onLongPressed: quickFavorite,
                      style: (isFavorite || isAddToLocalFav)
                          ? _ModernActionButtonStyle.active
                          : _ModernActionButtonStyle.outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 点赞按钮
                  if (data!.isLiked != null)
                    Expanded(
                      child: _ModernActionButton(
                        icon: isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label:
                            ((data!.likesCount != null)
                                    ? (data!.likesCount! + (isLiked ? 1 : 0))
                                    : (isLiked ? 'Liked'.tl : 'Like'.tl))
                                .toString(),
                        onPressed: likeOrUnlike,
                        isLoading: isLiking,
                        style: isLiked
                            ? _ModernActionButtonStyle.active
                            : _ModernActionButtonStyle.outline,
                      ),
                    ),
                  if (data!.isLiked != null) const SizedBox(width: 12),
                  // 分享按钮
                  Expanded(
                    child: _ModernActionButton(
                      icon: Icons.share_rounded,
                      label: "Share".tl,
                      onPressed: share,
                      style: _ModernActionButtonStyle.outline,
                    ),
                  ),
                ],
              ),
              // 评论按钮（如果支持）
              if (comicSource.commentsLoader != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _ModernActionButton(
                    icon: Icons.comment_rounded,
                    label: (comic.commentCount ?? 'Comments'.tl).toString(),
                    onPressed: showComments,
                    style: _ModernActionButtonStyle.outline,
                  ),
                ),
              ],
            ] else ...[
              // 桌面端水平滚动按钮
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    if (hasHistory)
                      _ActionButton(
                        icon: const Icon(Icons.menu_book_rounded),
                        text: 'Continue'.tl,
                        onPressed: continueRead,
                        iconColor: context.useTextColor(Colors.yellow),
                      ),
                    _ActionButton(
                      icon: const Icon(Icons.play_arrow_rounded),
                      text: 'Start'.tl,
                      onPressed: read,
                      iconColor: context.useTextColor(Colors.orange),
                    ),
                    if (!isDownloaded)
                      _ActionButton(
                        icon: const Icon(Icons.download_rounded),
                        text: 'Download'.tl,
                        onPressed: download,
                        iconColor: context.useTextColor(Colors.cyan),
                      ),
                    if (data!.isLiked != null)
                      _ActionButton(
                        icon: const Icon(Icons.favorite_border_rounded),
                        activeIcon: const Icon(Icons.favorite_rounded),
                        isActive: isLiked,
                        text:
                            ((data!.likesCount != null)
                                    ? (data!.likesCount! + (isLiked ? 1 : 0))
                                    : (isLiked ? 'Liked'.tl : 'Like'.tl))
                                .toString(),
                        isLoading: isLiking,
                        onPressed: likeOrUnlike,
                        iconColor: context.useTextColor(Colors.red),
                      ),
                    _ActionButton(
                      icon: const Icon(Icons.bookmark_border_rounded),
                      activeIcon: const Icon(Icons.bookmark_rounded),
                      isActive: (isFavorite || isAddToLocalFav),
                      text: 'Favorite'.tl,
                      onPressed: openFavPanel,
                      onLongPressed: quickFavorite,
                      iconColor: context.useTextColor(Colors.purple),
                    ),
                    if (comicSource.commentsLoader != null)
                      _ActionButton(
                        icon: const Icon(Icons.comment_rounded),
                        text: (comic.commentCount ?? 'Comments'.tl).toString(),
                        onPressed: showComments,
                        iconColor: context.useTextColor(Colors.green),
                      ),
                    _ActionButton(
                      icon: const Icon(Icons.share_rounded),
                      text: 'Share'.tl,
                      onPressed: share,
                      iconColor: context.useTextColor(Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
            // 阅读历史信息
            if (history != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerLow.withValues(
                    alpha: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colorScheme.primaryContainer.withValues(
                          alpha: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: context.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          bool haveChapter = comic.chapters != null;
                          var page = history!.page;
                          var ep = history!.ep;
                          var group = history!.group;
                          String text;
                          if (haveChapter) {
                            var epName = "E$ep";
                            String? groupName;
                            try {
                              if (group == null) {
                                epName = comic.chapters!.titles.elementAt(
                                  math.min(ep - 1, comic.chapters!.length - 1),
                                );
                              } else {
                                groupName = comic.chapters!.groups.elementAt(
                                  group - 1,
                                );
                                epName = comic.chapters!
                                    .getGroupByIndex(group - 1)
                                    .values
                                    .elementAt(ep - 1);
                              }
                            } catch (e) {
                              // ignore
                            }
                            text = groupName == null
                                ? "Last Reading: @ep P@page".tlParams({'ep': epName, 'page': page})
                                : "Last Reading: @group @ep P@page".tlParams({'group': groupName, 'ep': epName, 'page': page});
                          } else {
                            text = "Last Reading: P@page".tlParams({'page': page});
                          }
                          return Text(
                            text,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildDescription() {
    if (comic.description == null || comic.description!.trim().isEmpty) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }
    return SliverLazyToBoxAdapter(
      child: Column(
        children: [
          ListTile(title: Text("Description".tl)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SelectableText(comic.description!).fixWidth(double.infinity),
          ),
          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
    );
  }

  Widget buildInfo() {
    if (comic.tags.isEmpty &&
        comic.uploader == null &&
        comic.uploadTime == null &&
        comic.uploadTime == null &&
        comic.maxPage == null) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    int i = 0;

    Widget buildTag({
      required String text,
      VoidCallback? onTap,
      bool isTitle = false,
    }) {
      Color color;
      if (isTitle) {
        const colors = [
          Colors.blue,
          Colors.cyan,
          Colors.red,
          Colors.pink,
          Colors.purple,
          Colors.indigo,
          Colors.teal,
          Colors.green,
          Colors.lime,
          Colors.yellow,
        ];
        color = context.useBackgroundColor(colors[(i++) % (colors.length)]);
      } else {
        color = context.colorScheme.surfaceContainerLow;
      }

      final borderRadius = BorderRadius.circular(12);

      const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 6);

      if (onTap != null) {
        return Material(
          color: color,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: text));
              context.showMessage(message: "Copied".tl);
            },
            onSecondaryTapDown: (details) {
              showMenuX(context, details.globalPosition, [
                MenuEntry(
                  icon: Icons.remove_red_eye,
                  text: "View".tl,
                  onClick: onTap,
                ),
                MenuEntry(
                  icon: Icons.copy,
                  text: "Copy".tl,
                  onClick: () {
                    Clipboard.setData(ClipboardData(text: text));
                    context.showMessage(message: "Copied".tl);
                  },
                ),
              ]);
            },
            child: Text(text).padding(padding),
          ),
        );
      } else {
        return Container(
          decoration: BoxDecoration(color: color, borderRadius: borderRadius),
          child: Text(text).padding(padding),
        );
      }
    }

    String formatTime(String time) {
      if (int.tryParse(time) != null) {
        var t = int.tryParse(time);
        if (t! > 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(
            t,
          ).toString().substring(0, 19);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(
            t * 1000,
          ).toString().substring(0, 19);
        }
      }
      if (time.contains('T') || time.contains('Z')) {
        var t = DateTime.parse(time);
        return t.toString().substring(0, 19);
      }
      return time;
    }

    Widget buildWrap({required List<Widget> children}) {
      return Wrap(
        runSpacing: 8,
        spacing: 8,
        children: children,
      ).paddingHorizontal(16).paddingBottom(8);
    }

    bool enableTranslation =
        App.locale.languageCode == 'zh' && comicSource.enableTagsTranslate;

    return SliverLazyToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(title: Text("Information".tl)),
          if (comic.stars != null)
            Row(
              children: [
                StarRating(value: comic.stars!, size: 24, onTap: starRating),
                const SizedBox(width: 8),
                Text(comic.stars!.toStringAsFixed(2)),
              ],
            ).paddingLeft(16).paddingVertical(8),
          for (var e in comic.tags.entries)
            buildWrap(
              children: [
                if (e.value.isNotEmpty)
                  buildTag(text: e.key.ts(comicSource.key), isTitle: true),
                for (var tag in e.value)
                  buildTag(
                    text: enableTranslation
                        ? TagsTranslation.translationTagWithNamespace(
                            tag,
                            e.key.toLowerCase(),
                          )
                        : tag,
                    onTap: () => onTapTag(tag, e.key),
                  ),
              ],
            ),
          if (comic.uploader != null)
            buildWrap(
              children: [
                buildTag(text: 'Uploader'.tl, isTitle: true),
                buildTag(text: comic.uploader!),
              ],
            ),
          if (comic.uploadTime != null)
            buildWrap(
              children: [
                buildTag(text: 'Upload Time'.tl, isTitle: true),
                buildTag(text: formatTime(comic.uploadTime!)),
              ],
            ),
          if (comic.updateTime != null)
            buildWrap(
              children: [
                buildTag(text: 'Update Time'.tl, isTitle: true),
                buildTag(text: formatTime(comic.updateTime!)),
              ],
            ),
          if (comic.maxPage != null)
            buildWrap(
              children: [
                buildTag(text: 'Pages'.tl, isTitle: true),
                buildTag(text: comic.maxPage.toString()),
              ],
            ),
          const SizedBox(height: 12),
          const Divider(),
        ],
      ),
    );
  }

  Widget buildChapters() {
    if (comic.chapters == null) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }
    return _ComicChapters(
      history: history,
      groupedMode: comic.chapters!.isGrouped,
    );
  }

  Widget buildThumbnails() {
    if (comic.thumbnails == null && comicSource.loadComicThumbnail == null) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }
    return const _ComicThumbnails();
  }

  Widget buildRecommend() {
    if (comic.recommend == null || comic.recommend!.isEmpty) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: ListTile(title: Text("Related".tl))),
        SliverGridComics(comics: comic.recommend!),
      ],
    );
  }

  Widget buildComments() {
    if (comic.comments == null || comic.comments!.isEmpty) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }
    return _CommentsPart(comments: comic.comments!, showMore: showComments);
  }

  void _viewCover(BuildContext context) {
    final imageProvider = CachedImageProvider(
      widget.cover ?? comic.cover,
      sourceKey: comic.sourceKey,
      cid: comic.id,
    );

    context.to(
      () => _CoverViewer(
        imageProvider: imageProvider,
        title: comic.title,
        heroTag: "cover${widget.heroID}",
      ),
    );
  }

  void _saveCover(BuildContext context) async {
    try {
      final imageProvider = CachedImageProvider(
        widget.cover ?? comic.cover,
        sourceKey: comic.sourceKey,
        cid: comic.id,
      );

      final imageStream = imageProvider.resolve(const ImageConfiguration());
      final completer = Completer<Uint8List>();

      imageStream.addListener(
        ImageStreamListener((ImageInfo info, bool _) async {
          final byteData = await info.image.toByteData(
            format: ImageByteFormat.png,
          );
          if (byteData != null) {
            completer.complete(byteData.buffer.asUint8List());
          }
        }),
      );

      final data = await completer.future;
      final fileType = detectFileType(data);
      await saveFile(filename: "cover${fileType.ext}", data: data);
    } catch (e) {
      if (context.mounted) {
        context.showMessage(message: "Error".tl);
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.text,
    required this.onPressed,
    this.onLongPressed,
    this.activeIcon,
    this.isActive,
    this.isLoading,
    this.iconColor,
  });

  final Widget icon;

  final Widget? activeIcon;

  final bool? isActive;

  final String text;

  final void Function() onPressed;

  final bool? isLoading;

  final Color? iconColor;

  final void Function()? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.colorScheme.outlineVariant,
          width: 0.6,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!(isLoading ?? false)) {
            onPressed();
          }
        },
        onLongPress: onLongPressed,
        borderRadius: BorderRadius.circular(18),
        child: IconTheme.merge(
          data: IconThemeData(size: 20, color: iconColor),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading ?? false)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 1.8),
                )
              else
                (isActive ?? false) ? (activeIcon ?? icon) : icon,
              const SizedBox(width: 8),
              Text(text),
            ],
          ).paddingHorizontal(16),
        ),
      ),
    );
  }
}

class _SelectDownloadChapter extends StatefulWidget {
  const _SelectDownloadChapter(this.eps, this.finishSelect, this.downloadedEps);

  final List<String> eps;
  final void Function(List<int>) finishSelect;
  final List<int> downloadedEps;

  @override
  State<_SelectDownloadChapter> createState() => _SelectDownloadChapterState();
}

class _SelectDownloadChapterState extends State<_SelectDownloadChapter> {
  List<int> selected = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar(
        title: Text("Download".tl),
        backgroundColor: context.colorScheme.surfaceContainerLow,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: widget.eps.length,
              itemBuilder: (context, i) {
                return CheckboxListTile(
                  title: Text(widget.eps[i]),
                  value:
                      selected.contains(i) || widget.downloadedEps.contains(i),
                  onChanged: widget.downloadedEps.contains(i)
                      ? null
                      : (v) {
                          setState(() {
                            if (selected.contains(i)) {
                              selected.remove(i);
                            } else {
                              selected.add(i);
                            }
                          });
                        },
                );
              },
            ),
          ),
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      var res = <int>[];
                      for (int i = 0; i < widget.eps.length; i++) {
                        if (!widget.downloadedEps.contains(i)) {
                          res.add(i);
                        }
                      }
                      widget.finishSelect(res);
                      context.pop();
                    },
                    child: Text("Download All".tl),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () {
                            widget.finishSelect(selected);
                            context.pop();
                          },
                    child: Text("Download Selected".tl),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _ComicPageLoadingPlaceHolder extends StatelessWidget {
  const _ComicPageLoadingPlaceHolder({
    this.cover,
    this.title,
    required this.sourceKey,
    required this.cid,
    this.heroID,
  });

  final String? cover;

  final String? title;

  final String sourceKey;

  final String cid;

  final int? heroID;

  @override
  Widget build(BuildContext context) {
    Widget buildContainer(
      double? width,
      double? height, {
      Color? color,
      double? radius,
    }) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: color ?? context.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(radius ?? 4),
        ),
      );
    }

    return Shimmer(
      color: context.isDarkMode ? Colors.grey.shade700 : Colors.white,
      child: Column(
        children: [
          Appbar(title: Text(""), backgroundColor: context.colorScheme.surface),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 16),
              buildImage(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(title ?? "", style: ts.s18)
                    else
                      buildContainer(200, 25),
                    const SizedBox(height: 8),
                    buildContainer(80, 20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (context.width < changePoint)
            Row(
              children: [
                Expanded(child: buildContainer(null, 36, radius: 18)),
                const SizedBox(width: 16),
                Expanded(child: buildContainer(null, 36, radius: 18)),
              ],
            ).paddingHorizontal(16),
          const Divider(),
          const SizedBox(height: 8),
          Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
            ).fixHeight(24).fixWidth(24),
          ),
        ],
      ),
    );
  }

  Widget buildImage(BuildContext context) {
    Widget child;
    if (cover != null) {
      child = AnimatedImage(
        image: CachedImageProvider(cover!, sourceKey: sourceKey, cid: cid),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      child = const SizedBox();
    }

    return Hero(
      tag: "cover$heroID",
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.outlineVariant,
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        height: 144,
        width: 144 * 0.72,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

// 现代化操作按钮样式枚举
enum _ModernActionButtonStyle { primary, secondary, outline, active }

// 现代化操作按钮组件
class _ModernActionButton extends StatelessWidget {
  const _ModernActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.onLongPressed,
    this.style = _ModernActionButtonStyle.outline,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final _ModernActionButtonStyle style;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    switch (style) {
      case _ModernActionButtonStyle.primary:
        backgroundColor = context.colorScheme.primary;
        foregroundColor = context.colorScheme.onPrimary;
        borderColor = context.colorScheme.primary;
        break;
      case _ModernActionButtonStyle.secondary:
        backgroundColor = context.colorScheme.secondaryContainer;
        foregroundColor = context.colorScheme.onSecondaryContainer;
        borderColor = context.colorScheme.secondaryContainer;
        break;
      case _ModernActionButtonStyle.active:
        backgroundColor = context.colorScheme.primaryContainer;
        foregroundColor = context.colorScheme.onPrimaryContainer;
        borderColor = context.colorScheme.primary.withValues(alpha: 0.5);
        break;
      case _ModernActionButtonStyle.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = context.colorScheme.onSurface;
        borderColor = context.colorScheme.outline.withValues(alpha: 0.5);
        break;
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: style == _ModernActionButtonStyle.primary
            ? [
                BoxShadow(
                  color: context.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : onPressed,
          onLongPress: onLongPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        foregroundColor,
                      ),
                    ),
                  )
                else
                  Icon(icon, size: 18, color: foregroundColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
