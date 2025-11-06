import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:venera/utils/translations.dart';

/// 空状态页面组件 - 具有设计感的无数据展示
class EmptyState extends StatefulWidget {
  /// 图标
  final IconData? icon;

  /// 主标题
  final String title;

  /// 副标题/描述
  final String? description;

  /// 操作按钮文字
  final String? actionText;

  /// 操作按钮回调
  final VoidCallback? onAction;

  /// 使用 Sliver 布局
  final bool isSliver;

  /// 自定义图标颜色
  final Color? iconColor;

  /// 是否显示动画
  final bool animated;

  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
    this.isSliver = false,
    this.iconColor,
    this.animated = true,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.animated) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ),
      );

      _scaleAnimation = Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutBack,
        ),
      );

      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ),
      );

      _controller.forward();
    }
  }

  @override
  void dispose() {
    if (widget.animated) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    if (widget.isSliver) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: content,
      );
    }

    return content;
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget child = Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 装饰性背景圆圈
            _buildDecorativeBackground(context),

            const SizedBox(height: 32),

            // 主标题
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                height: 1.3,
              ),
            ),

            if (widget.description != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
            ],

            if (widget.actionText != null && widget.onAction != null) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: widget.onAction,
                icon: const Icon(Icons.add, size: 20),
                label: Text(widget.actionText!),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.animated) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: child,
          ),
        ),
      );
    }

    return child;
  }

  Widget _buildDecorativeBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = widget.iconColor ??
        colorScheme.primary.withValues(alpha: 0.15);
    final accentColor = colorScheme.primary.withValues(alpha: 0.08);

    return Stack(
      alignment: Alignment.center,
      children: [
        // 外层大圆
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor,
          ),
        ),

        // 中层圆
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor,
          ),
        ),

        // 装饰性小圆点
        ...List.generate(6, (index) {
          final angle = (index * math.pi * 2 / 6) - math.pi / 2;
          final radius = 90.0;
          final x = math.cos(angle) * radius;
          final y = math.sin(angle) * radius;

          return Positioned(
            left: 100 + x - 4,
            top: 100 + y - 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
          );
        }),

        // 中心图标
        Icon(
          widget.icon ?? Icons.inbox_outlined,
          size: 64,
          color: colorScheme.primary.withValues(alpha: 0.6),
        ),
      ],
    );
  }
}

/// 漫画收藏空状态 - 专门为收藏页面设计
class EmptyFavoritesState extends StatelessWidget {
  final VoidCallback? onAddFavorite;
  final bool isSliver;

  const EmptyFavoritesState({
    super.key,
    this.onAddFavorite,
    this.isSliver = false,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.favorite_border,
      title: 'No Favorites'.tl,
      description: 'You haven\'t favorited any comics yet\nDiscover your favorite works!'.tl,
      actionText: null,
      onAction: onAddFavorite,
      isSliver: isSliver,
    );
  }
}

/// 漫画历史空状态
class EmptyHistoryState extends StatelessWidget {
  final VoidCallback? onBrowse;
  final bool isSliver;

  const EmptyHistoryState({
    super.key,
    this.onBrowse,
    this.isSliver = false,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.history,
      title: 'No Reading History'.tl,
      description: 'Your reading history will appear here\nafter you start reading comics'.tl,
      actionText: onBrowse != null ? 'Start Reading'.tl : null,
      onAction: onBrowse,
      isSliver: isSliver,
    );
  }
}

/// 搜索结果空状态
class EmptySearchState extends StatelessWidget {
  final String? keyword;
  final bool isSliver;

  const EmptySearchState({
    super.key,
    this.keyword,
    this.isSliver = false,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No Results Found'.tl,
      description: keyword != null
          ? 'No results found for "@keyword"\nTry different keywords'.tlParams({'keyword': keyword!})
          : 'No results found\nTry different keywords'.tl,
      isSliver: isSliver,
      animated: false,
    );
  }
}

/// 下载列表空状态
class EmptyDownloadsState extends StatelessWidget {
  final VoidCallback? onDownload;
  final bool isSliver;

  const EmptyDownloadsState({
    super.key,
    this.onDownload,
    this.isSliver = false,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.download_outlined,
      title: 'No Download Tasks'.tl,
      description: 'Favorited comics can be downloaded for offline reading'.tl,
      actionText: onDownload != null ? 'Download'.tl : null,
      onAction: onDownload,
      isSliver: isSliver,
    );
  }
}

/// 通用列表空状态
class EmptyListState extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final bool isSliver;

  const EmptyListState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.isSliver = false,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon ?? Icons.inbox_outlined,
      title: title,
      description: description,
      isSliver: isSliver,
    );
  }
}

