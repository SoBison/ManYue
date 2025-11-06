import 'package:flutter/material.dart';
import 'package:venera/components/components.dart';
import 'package:venera/foundation/app.dart';
import 'package:venera/utils/translations.dart';

class ComicSourceHelpPage extends StatelessWidget {
  const ComicSourceHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = App.locale;
    final isChinese = locale.languageCode == 'zh';
    
    return Scaffold(
      appBar: Appbar(
        title: Text('Comic Source Help'.tl),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          isChinese ? _getChineseContent() : _getEnglishContent(),
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      ),
    );
  }

  String _getEnglishContent() {
    return '''
# Comic Source


You should provide a repository url to let the app load the comic source list. The url should point to a JSON file that contains the list of comic sources.

The JSON file should have the following format:

```json
[
  {
    "name": "Source Name",
    "url": "https://example.com/source.js",
    "filename": "Relative path to the source file",
    "version": "1.0.0",
    "description": "A brief description of the source"
  }
]
```

Only one of `url` and `filename` should be provided. The description field is optional.


''';
  }

  String _getChineseContent() {
    return '''
# 漫画源

## 介绍

您应该提供一个仓库 URL 以便应用加载漫画源列表。该 URL 应指向包含漫画源列表的 JSON 文件。

JSON 文件应具有以下格式:

```json
[
  {
    "name": "源名称",
    "url": "https://example.com/source.js",
    "filename": "源文件的相对路径",
    "version": "1.0.0",
    "description": "源的简要描述"
  }
]
```

`url` 和 `filename` 只应提供其中一个。description 字段是可选的。

''';
  }
}


