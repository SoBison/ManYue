import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:venera/foundation/history.dart';

import 'appdata.dart';
import 'favorites.dart';
import 'local.dart';

export "widget_utils.dart";
export "context.dart";

class _App {
  final version = "1.5.2";

  bool get isAndroid => Platform.isAndroid;

  bool get isIOS => Platform.isIOS;

  bool get isWindows => Platform.isWindows;

  bool get isLinux => Platform.isLinux;

  bool get isMacOS => Platform.isMacOS;

  bool get isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  bool get isMobile => Platform.isAndroid || Platform.isIOS;

  // Whether the app has been initialized.
  // If current Isolate is main Isolate, this value is always true.
  bool isInitialized = false;

  Locale get locale {
    // 如果设置了具体的语言，直接使用设置的语言
    var languageSetting = appdata.settings['language'];
    if (languageSetting != 'system') {
      var parts = languageSetting.split('-');
      if (parts.length >= 3) {
        return Locale.fromSubtags(
          languageCode: parts[0],
          scriptCode: parts[1],
          countryCode: parts[2],
        );
      }
      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      }
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return Locale(parts[0]);
      }
    }

    // 获取系统语言
    Locale deviceLocale = PlatformDispatcher.instance.locale;

    // 处理中文语言变体
    if (deviceLocale.languageCode == "zh") {
      if (deviceLocale.scriptCode == "Hant") {
        return const Locale("zh", "TW");
      }
      // 简体中文：不管是 zh-Hans、zh-CN 还是纯 zh，都返回 zh-CN
      return const Locale("zh", "CN");
    }

    // 处理英文语言变体，统一使用 en-US
    if (deviceLocale.languageCode == "en") {
      return const Locale("en", "US");
    }

    // 如果是不支持的语言，默认使用英语
    return const Locale("en", "US");
  }

  late String dataPath;
  late String cachePath;
  String? externalStoragePath;

  final rootNavigatorKey = GlobalKey<NavigatorState>();

  GlobalKey<NavigatorState>? mainNavigatorKey;

  BuildContext get rootContext => rootNavigatorKey.currentContext!;

  final Appdata data = appdata;

  final HistoryManager history = HistoryManager();

  final LocalFavoritesManager favorites = LocalFavoritesManager();

  final LocalManager local = LocalManager();

  void rootPop() {
    rootNavigatorKey.currentState?.maybePop();
  }

  void pop() {
    if (rootNavigatorKey.currentState?.canPop() ?? false) {
      rootNavigatorKey.currentState?.pop();
    } else if (mainNavigatorKey?.currentState?.canPop() ?? false) {
      mainNavigatorKey?.currentState?.pop();
    }
  }

  Future<void> init() async {
    cachePath = (await getApplicationCacheDirectory()).path;
    dataPath = (await getApplicationSupportDirectory()).path;
    if (isAndroid) {
      externalStoragePath = (await getExternalStorageDirectory())!.path;
    }
    isInitialized = true;
  }

  Future<void> initComponents() async {
    await Future.wait([
      data.init(),
      history.init(),
      favorites.init(),
      local.init(),
    ]);
  }

  Function? _forceRebuildHandler;

  void registerForceRebuild(Function handler) {
    _forceRebuildHandler = handler;
  }

  void forceRebuild() {
    _forceRebuildHandler?.call();
  }
}

// ignore: non_constant_identifier_names
final App = _App();
