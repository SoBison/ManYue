import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:venera/init.dart';

/// 启动页面 - 具有动画效果和设计感的漫画App启动页
class SplashPage extends StatefulWidget {
  /// 初始化完成后的回调
  final VoidCallback onInitComplete;

  const SplashPage({super.key, required this.onInitComplete});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // 动画控制器
  late AnimationController _backgroundController;
  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _pageFlipController;
  late AnimationController _progressController;
  late AnimationController _fadeOutController;

  // 动画
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _pageFlipAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<double> _fadeOutAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  /// 初始化所有动画
  void _initAnimations() {
    // 背景渐变动画
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 图标动画
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _iconScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_iconController);

    _iconOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // 文字动画
    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    // 翻页动画
    _pageFlipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pageFlipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageFlipController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // 进度条动画
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // 背景颜色动画
    _backgroundColorAnimation = ColorTween(
      begin: const Color(0xFF1a1a2e),
      end: const Color(0xFF16213e),
    ).animate(_backgroundController);

    // 淡出动画
    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeInOut),
    );
  }

  /// 开始动画序列
  void _startAnimationSequence() async {
    // 开始背景动画
    _backgroundController.repeat(reverse: true);

    // 延迟一点开始翻页效果
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _pageFlipController.forward();

    // 图标动画
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _iconController.forward();

    // 文字动画
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _textController.forward();

    // 进度条动画
    if (!mounted) return;
    _progressController.repeat();

    // 等待最小显示时间,确保用户能看到启动页动画
    await Future.delayed(const Duration(milliseconds: 500));

    // 开始淡出动画
    if (!mounted) return;
    await _fadeOutController.forward();

    // 标记初始化完成
    if (!mounted) return;
    widget.onInitComplete();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _iconController.dispose();
    _textController.dispose();
    _pageFlipController.dispose();
    _progressController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _backgroundController,
          _fadeOutController,
        ]),
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOutAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          _backgroundColorAnimation.value ??
                              const Color(0xFF1a1a2e),
                          const Color(0xFF0f3460),
                          const Color(0xFF16213e),
                        ]
                      : [
                          const Color(0xFFe3f2fd),
                          const Color(0xFFbbdefb),
                          const Color(0xFF90caf9),
                        ],
                ),
              ),
              child: Stack(
                children: [
                  // 装饰性漫画网格背景
                  _buildComicGridBackground(),

                  // 翻页效果
                  _buildPageFlipEffect(size),

                  // 主要内容
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App图标
                        _buildAnimatedIcon(),

                        const SizedBox(height: 40),

                        // App名称
                        _buildAnimatedText(),

                        const SizedBox(height: 60),

                        // 加载指示器
                        _buildLoadingIndicator(),
                      ],
                    ),
                  ),

                  // 装饰性漫画元素
                  // _buildComicElements(size),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建漫画网格背景
  Widget _buildComicGridBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ComicGridPainter(color: Colors.white.withValues(alpha: 0.05)),
      ),
    );
  }

  /// 构建翻页效果 - 书本翻页动画
  Widget _buildPageFlipEffect(Size size) {
    return AnimatedBuilder(
      animation: _pageFlipAnimation,
      builder: (context, child) {
        final progress = _pageFlipAnimation.value;

        // 使用三次贝塞尔曲线让动画更自然
        final curvedProgress = Curves.easeInOutCubic.transform(progress);

        // 计算翻页角度 (0 到 π)
        final angle = curvedProgress * math.pi;

        // 计算页面位置偏移
        final xOffset = size.width * 0.5 * (1 - math.cos(angle));

        return Stack(
          children: [
            // 背后的页面（轻微阴影）
            if (progress > 0.1)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.black.withValues(
                          alpha: 0.05 * (1 - curvedProgress),
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5],
                    ),
                  ),
                ),
              ),

            // 翻页的页面
            Positioned(
              right: -size.width * 0.5 + xOffset,
              top: 0,
              bottom: 0,
              child: Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // 透视效果
                  ..rotateY(angle),
                child: Container(
                  width: size.width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        // 翻页时的高光效果
                        Colors.white.withValues(
                          alpha: 0.2 * math.sin(angle).clamp(0.0, 1.0),
                        ),
                        Colors.white.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 1.0],
                    ),
                    // 添加轻微的边缘阴影
                    boxShadow: angle > math.pi / 2
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.1 * (1 - curvedProgress),
                              ),
                              blurRadius: 20,
                              spreadRadius: -10,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建动画图标
  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        return Opacity(
          opacity: _iconOpacityAnimation.value,
          child: Transform.scale(
            scale: _iconScaleAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset('assets/app_icon.png', fit: BoxFit.cover),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建动画文字
  Widget _buildAnimatedText() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return SlideTransition(
          position: _textSlideAnimation,
          child: Opacity(
            opacity: _textOpacityAnimation.value,
            child: Column(
              children: [
                Text(
                  'ManYue',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Comics World, At Your Fingertips',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return SizedBox(
          width: 200,
          child: Column(
            children: [
              // 旋转的漫画对话框图标
              _buildLottieAnimation(),
              const SizedBox(height: 16),
              // 进度条
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: null,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  color: Theme.of(context).colorScheme.primary,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建装饰性漫画元素
  Widget _buildComicElements(Size size) {
    return Stack(
      children: [
        // 左上角装饰图标
        Positioned(
          top: size.height * 0.15,
          left: 30,
          child: _buildComicIcon(
            Icons.collections_bookmark_rounded,
            isLeft: true,
          ),
        ),
        // 右下角装饰图标
        Positioned(
          bottom: size.height * 0.15,
          right: 30,
          child: _buildComicIcon(Icons.star_rounded, isLeft: false),
        ),
      ],
    );
  }

  /// 构建装饰性图标
  Widget _buildComicIcon(IconData icon, {required bool isLeft}) {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Opacity(
          opacity: _textOpacityAnimation.value * 0.5,
          child: Transform.scale(
            scale: 0.5 + (_textOpacityAnimation.value * 0.5),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 可选：使用 Lottie 动画作为背景装饰
  /// 如果要使用，需要添加 Lottie 动画文件到 assets 目录
  ///
  /// 使用方法：在 Stack children 中添加 _buildLottieAnimation()
  /// 推荐的 Lottie 动画资源：
  /// - https://lottiefiles.com/animations/book-flip (书本翻页)
  /// - https://lottiefiles.com/animations/reading (阅读动画)
  /// - https://lottiefiles.com/animations/comic (漫画主题)
  Widget _buildLottieAnimation() {
    return AnimatedBuilder(
      animation: _pageFlipAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 * _pageFlipAnimation.value,
          child: SizedBox(
            width: 100,
            height: 100,
            child: Lottie.asset(
              'assets/animations/book_flip.json',
              controller: _pageFlipController,
              repeat: false,
              errorBuilder: (context, error, stackTrace) {
                // 如果动画文件不存在，返回空容器
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );
  }
}

/// 漫画网格背景绘制器
class ComicGridPainter extends CustomPainter {
  final Color color;

  ComicGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 绘制网格
    const gridSize = 40.0;

    // 垂直线
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 水平线
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 绘制一些随机的漫画风格点
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // 使用固定种子保持一致性
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2 + 1;
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
