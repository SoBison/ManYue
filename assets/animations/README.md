# Lottie 动画资源目录

这个目录用于存放启动页的 Lottie 动画文件。

## 📁 推荐的动画文件

在这个目录中放置以下文件：

```
assets/animations/
└── book_flip.json    # 书本翻页动画
```

## 🎯 获取 Lottie 动画

### 方法一：从 LottieFiles 下载

1. 访问 [LottieFiles](https://lottiefiles.com)
2. 搜索关键词：
   - `book flip`
   - `reading`
   - `open book`
   - `comic book`
3. 下载 JSON 格式
4. 重命名为 `book_flip.json`
5. 放入此目录

### 方法二：使用推荐动画

以下是一些优质的书本翻页动画（需要从 LottieFiles 下载）：

| 动画名称 | 特点 | 推荐指数 |
|---------|------|---------|
| Book Page Turn | 简洁流畅 | ⭐⭐⭐⭐⭐ |
| Reading Book | 细节丰富 | ⭐⭐⭐⭐ |
| Open Book | 创意独特 | ⭐⭐⭐⭐ |
| Comic Book Animation | 符合主题 | ⭐⭐⭐⭐⭐ |

### 方法三：使用在线资源（测试用）

如果只是想快速测试效果，可以使用网络资源（需要网络连接）。

在代码中使用：
```dart
Lottie.network('https://assets.lottiefiles.com/...')
```

## ⚙️ 动画文件要求

### 文件规格
- **格式**：JSON
- **大小**：< 100KB
- **时长**：1-2 秒
- **帧率**：30fps

### 性能建议
- 避免过于复杂的动画
- 图层数量 < 50
- 避免大量模糊效果
- 尽量不包含图片资源

## 🔗 如何注册动画

1. 将 JSON 文件放入此目录
2. 编辑 `pubspec.yaml`：
   ```yaml
   flutter:
     assets:
       - assets/animations/book_flip.json
   ```
3. 运行 `flutter pub get`

## 📝 当前状态

- ✅ Lottie 依赖已添加
- ⚠️ 动画文件待添加
- ℹ️ 已有备用的 3D 翻页动画（无需文件）

## 🚀 快速开始

如果这个目录是空的也没关系！启动页已经实现了精美的 3D 翻页动画，无需额外文件。

Lottie 动画是**可选的**，用于需要更复杂视觉效果的场景。

---

**相关文档**：
- 详细使用指南：`/doc/splash_page_lottie.md`
- 快速指南：`/SPLASH_ANIMATION_GUIDE.md`


