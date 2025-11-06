# 启动页 Lottie 动画使用指南

## 概述

启动页现在支持两种书本翻页效果：
1. **自定义 3D 翻页动画**（默认，已实现）
2. **Lottie 动画**（可选，需要额外配置）

## 当前实现

### 默认动画效果

已经实现了一个精致的书本翻页动画，特点：
- ✅ 3D 透视效果，模拟真实书页翻动
- ✅ 动态高光和阴影效果
- ✅ 平滑的贝塞尔曲线过渡
- ✅ 无需额外资源文件
- ✅ 性能优化，流畅运行

动画实现位置：`lib/pages/splash_page.dart` 的 `_buildPageFlipEffect()` 方法

## 添加 Lottie 动画（可选）

如果你想使用更复杂的 Lottie 动画，请按以下步骤操作：

### 1. 准备 Lottie 动画文件

#### 选项 A：下载现成动画
从 [LottieFiles](https://lottiefiles.com) 下载书本相关动画：

推荐动画：
- [Book Flip Animation](https://lottiefiles.com/animations/book-flip)
- [Reading Book](https://lottiefiles.com/animations/reading-book)
- [Open Book](https://lottiefiles.com/animations/open-book)
- [Comic Book](https://lottiefiles.com/animations/comic-book)

#### 选项 B：自制动画
使用 Adobe After Effects + Bodymovin 插件创建自定义动画

### 2. 添加动画文件到项目

1. 创建动画目录：
   ```bash
   mkdir -p assets/animations
   ```

2. 将下载的 `.json` 文件重命名为 `book_flip.json`，放入 `assets/animations/` 目录

3. 在 `pubspec.yaml` 中注册资源：
   ```yaml
   flutter:
     assets:
       - assets/animations/book_flip.json
   ```

### 3. 启用 Lottie 动画

在 `lib/pages/splash_page.dart` 中，找到 Stack 的 children 部分，添加 Lottie 动画层：

```dart
child: Stack(
  children: [
    // 装饰性漫画网格背景
    _buildComicGridBackground(),

    // 【可选】添加 Lottie 动画背景
    _buildLottieAnimation(),

    // 翻页效果
    _buildPageFlipEffect(size),
    
    // ... 其他组件
  ],
),
```

### 4. 自定义动画参数

你可以在 `_buildLottieAnimation()` 方法中调整：

```dart
Widget _buildLottieAnimation() {
  return Positioned.fill(
    child: AnimatedBuilder(
      animation: _pageFlipAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 * _pageFlipAnimation.value, // 调整透明度
          child: Center(
            child: SizedBox(
              width: 300,  // 调整动画大小
              height: 300,
              child: Lottie.asset(
                'assets/animations/book_flip.json',
                controller: _pageFlipController,
                repeat: false,  // 设为 true 可循环播放
              ),
            ),
          ),
        );
      },
    ),
  );
}
```

## 性能建议

1. **文件大小**：Lottie 动画文件建议小于 100KB
2. **复杂度**：避免过于复杂的动画，保持流畅性
3. **缓存**：Lottie 会自动缓存动画，无需手动处理
4. **降级方案**：如果动画文件不存在，会自动回退到默认翻页效果

## 动画时序

启动页动画序列：
```
0ms     - 背景渐变动画开始
300ms   - 翻页动画开始 (Lottie 或自定义)
400ms   - 图标缩放动画
900ms   - 文字淡入滑动
2500ms  - 淡出动画
3000ms  - 跳转到主页面
```

## 故障排查

### Lottie 动画不显示
- 检查文件路径是否正确
- 确认 `pubspec.yaml` 中已注册资源
- 运行 `flutter pub get` 更新依赖
- 运行 `flutter clean && flutter pub get` 清理缓存

### 动画卡顿
- 降低动画复杂度
- 减小动画尺寸
- 检查是否有大量图层

### 动画不同步
- 确保使用 `controller: _pageFlipController` 绑定控制器
- 调整 `_pageFlipController` 的 duration

## 示例：使用在线 Lottie 动画

如果不想下载文件，可以使用网络资源（需要网络连接）：

```dart
Lottie.network(
  'https://assets10.lottiefiles.com/packages/lf20_book_flip.json',
  controller: _pageFlipController,
  repeat: false,
)
```

## 相关文件

- 启动页实现：`lib/pages/splash_page.dart`
- 配置文件：`pubspec.yaml`
- 动画资源：`assets/animations/` (需要手动创建)

## 更多资源

- [Lottie 官方文档](https://airbnb.io/lottie/)
- [Flutter Lottie Package](https://pub.dev/packages/lottie)
- [LottieFiles 社区](https://lottiefiles.com)
- [After Effects 教程](https://www.adobe.com/products/aftereffects.html)


