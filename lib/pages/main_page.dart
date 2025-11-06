import 'package:flutter/material.dart';
import 'package:venera/foundation/appdata.dart';
import 'package:venera/pages/categories_page.dart';
import 'package:venera/pages/search_page.dart';
import 'package:venera/pages/settings/settings_page.dart';
import 'package:venera/utils/translations.dart';

import '../components/components.dart';
import '../foundation/app.dart';
import 'explore_page.dart';
import 'favorites/favorites_page.dart';
import 'home_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final NaviObserver _observer;

  GlobalKey<NavigatorState>? _navigatorKey;

  void to(Widget Function() widget, {bool preventDuplicate = false}) async {
    if (preventDuplicate) {
      var page = widget();
      if ("/${page.runtimeType}" == _observer.routes.last.toString()) return;
    }
    _navigatorKey!.currentContext!.to(widget);
  }

  void back() {
    _navigatorKey!.currentContext!.pop();
  }

  @override
  void initState() {
    _observer = NaviObserver();
    _navigatorKey = GlobalKey();
    App.mainNavigatorKey = _navigatorKey;
    index = int.tryParse(appdata.settings['initialPage'].toString()) ?? 0;
    // 监听设置变化，以便在布局模式改变时更新按钮
    appdata.settings.addListener(_onSettingsChanged);
    super.initState();
  }

  @override
  void dispose() {
    appdata.settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    // 当设置改变时，重新构建paneActions
    if (mounted) {
      setState(() {});
    }
  }

  final _pages = [
    const HomePage(),
    const FavoritesPage(key: PageStorageKey('favorites')),
    const ExplorePage(key: PageStorageKey('explore')),
    const CategoriesPage(key: PageStorageKey('categories')),
  ];

  var index = 0;

  List<PaneActionEntry> _buildPaneActions() {
    final actions = <PaneActionEntry>[];

    // 搜索按钮 - 所有页面都显示
    actions.add(
      PaneActionEntry(
        icon: Icons.search,
        label: "Search".tl,
        onTap: () {
          to(() => const SearchPage(), preventDuplicate: true);
        },
      ),
    );

    // 布局切换按钮 - 仅在发现页显示
    if (index == 2) {
      final layoutMode = appdata.settings['comicLayoutMode'] ?? 'staggered';
      actions.add(
        PaneActionEntry(
          icon: layoutMode == 'staggered' ? Icons.grid_view : Icons.view_module,
          label: layoutMode == 'staggered' ? "Grid".tl : "Flow".tl,
          onTap: () {
            final newMode = layoutMode == 'grid' ? 'staggered' : 'grid';
            appdata.settings['comicLayoutMode'] = newMode;
            appdata.saveData();

            // 显示切换提示
            final message = newMode == 'staggered'
                ? "Switched to Staggered Layout".tl
                : "Switched to Grid Layout".tl;
            App.rootContext.showMessage(message: message);

            // 强制刷新界面
            setState(() {});
          },
        ),
      );
    }

    // 设置按钮 - 始终显示
    actions.add(
      PaneActionEntry(
        icon: Icons.settings,
        label: "Settings".tl,
        onTap: () {
          to(() => const SettingsPage(), preventDuplicate: true);
        },
      ),
    );

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    return NaviPane(
      initialPage: index,
      observer: _observer,
      navigatorKey: _navigatorKey!,
      paneItems: [
        PaneItemEntry(
          label: 'Home'.tl,
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
        ),
        PaneItemEntry(
          label: 'Favorites'.tl,
          icon: Icons.local_activity_outlined,
          activeIcon: Icons.local_activity,
        ),
        PaneItemEntry(
          label: 'Explore'.tl,
          icon: Icons.explore_outlined,
          activeIcon: Icons.explore,
        ),
        PaneItemEntry(
          label: 'Categories'.tl,
          icon: Icons.category_outlined,
          activeIcon: Icons.category,
        ),
      ],
      onPageChanged: (i) {
        setState(() {
          index = i;
        });
      },
      paneActions: _buildPaneActions(),
      pageBuilder: (index) {
        return _pages[index];
      },
    );
  }
}
