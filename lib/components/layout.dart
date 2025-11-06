part of 'components.dart';

class SliverGridViewWithFixedItemHeight extends StatelessWidget {
  const SliverGridViewWithFixedItemHeight({
    required this.delegate,
    required this.maxCrossAxisExtent,
    required this.itemHeight,
    super.key,
  });

  final SliverChildDelegate delegate;

  final double maxCrossAxisExtent;

  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverGrid(
        delegate: delegate,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
          childAspectRatio: calcChildAspectRatio(constraints.crossAxisExtent),
        ),
      ),
    );
  }

  double calcChildAspectRatio(double width) {
    var crossItems = width ~/ maxCrossAxisExtent;
    if (width % maxCrossAxisExtent != 0) {
      crossItems += 1;
    }
    final itemWidth = width / crossItems;
    return itemWidth / itemHeight;
  }
}

class SliverGridDelegateWithFixedHeight extends SliverGridDelegate {
  const SliverGridDelegateWithFixedHeight({
    required this.maxCrossAxisExtent,
    required this.itemHeight,
  });

  final double maxCrossAxisExtent;

  final double itemHeight;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final width = constraints.crossAxisExtent;
    var crossItems = width ~/ maxCrossAxisExtent;
    if (width % maxCrossAxisExtent != 0) {
      crossItems += 1;
    }
    return SliverGridRegularTileLayout(
      crossAxisCount: crossItems,
      mainAxisStride: itemHeight,
      crossAxisStride: width / crossItems,
      childMainAxisExtent: itemHeight,
      childCrossAxisExtent: width / crossItems,
      reverseCrossAxis: false,
    );
  }

  @override
  bool shouldRelayout(covariant SliverGridDelegate oldDelegate) {
    if (oldDelegate is! SliverGridDelegateWithFixedHeight) return true;
    if (oldDelegate.maxCrossAxisExtent != maxCrossAxisExtent ||
        oldDelegate.itemHeight != itemHeight) {
      return true;
    }
    return false;
  }
}

class SliverGridDelegateWithComics extends SliverGridDelegate {
  SliverGridDelegateWithComics();

  final bool useBriefMode = appdata.settings['comicDisplayMode'] == 'brief';

  final double scale = (appdata.settings['comicTileScale'] as num).toDouble();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    if (useBriefMode) {
      return getBriefModeLayout(constraints, scale);
    } else {
      return getDetailedModeLayout(constraints, scale);
    }
  }

  SliverGridLayout getDetailedModeLayout(
    SliverConstraints constraints,
    double scale,
  ) {
    const minCrossAxisExtent = 360;
    final itemHeight = 152 * scale;
    final width = constraints.crossAxisExtent;
    var crossItems = width ~/ minCrossAxisExtent;
    crossItems = math.max(1, crossItems);
    return SliverGridRegularTileLayout(
      crossAxisCount: crossItems,
      mainAxisStride: itemHeight,
      crossAxisStride: width / crossItems,
      childMainAxisExtent: itemHeight,
      childCrossAxisExtent: width / crossItems,
      reverseCrossAxis: false,
    );
  }

  SliverGridLayout getBriefModeLayout(
    SliverConstraints constraints,
    double scale,
  ) {
    final maxCrossAxisExtent = 192.0 * scale;
    const childAspectRatio = 0.64;
    const crossAxisSpacing = 0.0;
    int crossAxisCount =
        (constraints.crossAxisExtent / (maxCrossAxisExtent + crossAxisSpacing))
            .ceil();
    // Ensure a minimum count of 1, can be zero and result in an infinite extent
    // below when the window size is 0.
    crossAxisCount = math.max(1, crossAxisCount);
    final double usableCrossAxisExtent = math.max(
      0.0,
      constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1),
    );
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final double childMainAxisExtent = childCrossAxisExtent / childAspectRatio;
    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: childMainAxisExtent,
      crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
      childMainAxisExtent: childMainAxisExtent,
      childCrossAxisExtent: childCrossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(covariant SliverGridDelegate oldDelegate) {
    if (oldDelegate is! SliverGridDelegateWithComics) return true;
    if (oldDelegate.scale != scale ||
        oldDelegate.useBriefMode != useBriefMode) {
      return true;
    }
    return false;
  }
}

/// 响应式流式布局委托类，针对不同设备优化
class SliverStaggeredGridDelegateWithComics extends SliverGridDelegate {
  SliverStaggeredGridDelegateWithComics();

  final bool useBriefMode = appdata.settings['comicDisplayMode'] == 'brief';
  final double scale = (appdata.settings['comicTileScale'] as num).toDouble();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    if (useBriefMode) {
      return getStaggeredBriefModeLayout(constraints, scale);
    } else {
      return getStaggeredDetailedModeLayout(constraints, scale);
    }
  }

  /// 获取设备类型和推荐的列数
  int _getRecommendedColumns(double screenWidth) {
    // 移动端：宽度 < 600dp，根据宽度动态调整
    if (screenWidth < 600) {
      // 小屏手机：2列，中等屏幕：3列，大屏手机：3-4列
      if (screenWidth < 360) {
        return 2;
      } else if (screenWidth < 480) {
        return 3;
      } else {
        return 3;
      }
    }
    // 平板端：宽度 600-900dp，4-5列
    else if (screenWidth < 900) {
      return (screenWidth / 180).floor().clamp(4, 5);
    }
    // 桌面端：宽度 > 900dp，动态计算
    else {
      return (screenWidth / 160).floor().clamp(5, 8);
    }
  }

  SliverGridLayout getStaggeredDetailedModeLayout(
    SliverConstraints constraints,
    double scale,
  ) {
    final screenWidth = constraints.crossAxisExtent;
    final columns = _getRecommendedColumns(screenWidth);

    // 详细模式的宽高比调整 - 为标题和作者信息预留更多空间
    final childAspectRatio = 0.65 * scale; // 降低宽高比，增加高度空间

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: 12.0, // 增加横向间距
      mainAxisSpacing: 16.0, // 增加纵向间距，提升立体感
    ).getLayout(constraints);
  }

  SliverGridLayout getStaggeredBriefModeLayout(
    SliverConstraints constraints,
    double scale,
  ) {
    final screenWidth = constraints.crossAxisExtent;
    final columns = _getRecommendedColumns(screenWidth);

    // 简洁模式的宽高比 - 调整以容纳标题和作者信息
    final childAspectRatio = 0.52 * scale; // 进一步降低宽高比，为文本预留更多空间

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: 10.0, // 增加横向间距
      mainAxisSpacing: 14.0, // 增加纵向间距，提升立体感
    ).getLayout(constraints);
  }

  @override
  bool shouldRelayout(covariant SliverGridDelegate oldDelegate) {
    if (oldDelegate is! SliverStaggeredGridDelegateWithComics) return true;
    if (oldDelegate.scale != scale ||
        oldDelegate.useBriefMode != useBriefMode) {
      return true;
    }
    return false;
  }
}

class SliverLazyToBoxAdapter extends StatelessWidget {
  /// Creates a sliver that contains a single box widget which can be lazy loaded.
  const SliverLazyToBoxAdapter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverList.list(children: [SizedBox(), child]);
  }
}

class SliverAnimatedVisibility extends StatelessWidget {
  const SliverAnimatedVisibility({
    super.key,
    required this.visible,
    required this.child,
  });

  final bool visible;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    var child = visible ? this.child : const SizedBox.shrink();

    return SliverToBoxAdapter(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }
}
