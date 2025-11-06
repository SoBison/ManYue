import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:venera/foundation/comic_source/comic_source.dart';
import '../foundation/app.dart';

extension AppTranslation on String {
  String _translate() {
    var locale = App.locale;
    // 构建翻译键，优先使用 languageCode_countryCode 格式
    String key;
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      key = "${locale.languageCode}_${locale.countryCode}";
    } else {
      key = locale.languageCode;
    }
    
    // 特殊处理英语，确保使用 en_US
    if (locale.languageCode == "en") {
      key = "en_US";
    }
    
    // 尝试查找翻译，如果没有找到，尝试只用语言代码
    var result = translations[key]?[this];
    if (result == null && locale.countryCode != null) {
      // 如果带国家代码的键找不到，尝试只用语言代码
      result = translations[locale.languageCode]?[this];
    }
    return result ?? this;
  }

  String get tl => _translate();

  String get tlEN => translations["en_US"]![this] ?? this;

  String tlParams(Map<String, Object> values) {
    var res = _translate();
    for (var entry in values.entries) {
      res = res.replaceFirst("@${entry.key}", entry.value.toString());
    }
    return res;
  }

  static late final Map<String, Map<String, String>> translations;

  static Future<void> init() async {
    var data = await rootBundle.load("assets/translation.json");
    var json = jsonDecode(utf8.decode(data.buffer.asUint8List()));
    translations = {
      for (var e in json.entries) e.key: Map<String, String>.from(e.value)
    };
  }

  /// Translate a string using specified comic source
  String ts(String sourceKey) {
    var comicSource = ComicSource.find(sourceKey);
    if (comicSource == null || comicSource.translations == null) {
      return this;
    }
    var locale = App.locale;
    var lc = locale.languageCode;
    var cc = locale.countryCode;
    var key = "$lc${cc == null ? "" : "_$cc"}";
    return (comicSource.translations![key] ??
            comicSource.translations![lc])?[this] ??
        this;
  }
}

extension ListTranslation on List<String> {
  List<String> _translate() {
    return List.generate(length, (index) => this[index].tl);
  }

  List<String> get tl => _translate();
}
