part of 'settings_page.dart';

class ExploreSettings extends StatefulWidget {
  const ExploreSettings({super.key});

  @override
  State<ExploreSettings> createState() => _ExploreSettingsState();
}

class _ExploreSettingsState extends State<ExploreSettings> {
  @override
  Widget build(BuildContext context) {
    return SmoothCustomScrollView(
      slivers: [
        SliverAppbar(title: Text("Explore".tl)),

        // 显示设置分组
        ModernSectionTitle(
          title: "Display Settings".tl,
          icon: Icons.visibility,
          subtitle: "Customize how comics are displayed".tl,
        ).toSliver(),

        SettingCard(
          children: [
            ModernSelectSetting(
              title: "Display mode of comic tile".tl,
              settingKey: "comicDisplayMode",
              optionTranslation: {
                "detailed": "Detailed".tl,
                "brief": "Brief".tl,
              },
              icon: Icons.view_module,
            ),
            ModernSelectSetting(
              title: "Layout mode of comic grid".tl,
              settingKey: "comicLayoutMode",
              optionTranslation: {
                "grid": "Grid Layout".tl,
                "staggered": "Staggered Layout".tl,
              },
              icon: Icons.grid_view,
            ),
            ModernSliderSetting(
              title: "Size of comic tile".tl,
              settingsIndex: "comicTileScale",
              interval: 0.05,
              min: 0.5,
              max: 1.5,
              icon: Icons.photo_size_select_large,
              unit: "x",
            ),
            ModernSelectSetting(
              title: "Display mode of comic list".tl,
              settingKey: "comicListDisplayMode",
              optionTranslation: {
                "paging": "Paging".tl,
                "Continuous": "Continuous".tl,
              },
              icon: Icons.list,
            ),
          ],
        ).toSliver(),

        // 页面管理分组
        ModernSectionTitle(
          title: "Page Management".tl,
          icon: Icons.pages,
          subtitle: "Configure explore and category pages".tl,
        ).toSliver(),

        SettingCard(
          children: [
            ModernActionSetting(
              title: "Explore Pages".tl,
              callback: () =>
                  showPopUpWidget(App.rootContext, setExplorePagesWidget()),
              actionTitle: "Manage".tl,
              icon: Icons.explore,
              actionIcon: Icons.settings,
            ),
            ModernActionSetting(
              title: "Category Pages".tl,
              callback: () =>
                  showPopUpWidget(App.rootContext, setCategoryPagesWidget()),
              actionTitle: "Manage".tl,
              icon: Icons.category,
              actionIcon: Icons.settings,
            ),
            ModernActionSetting(
              title: "Network Favorite Pages".tl,
              callback: () =>
                  showPopUpWidget(App.rootContext, setFavoritesPagesWidget()),
              actionTitle: "Manage".tl,
              icon: Icons.favorite,
              actionIcon: Icons.settings,
            ),
          ],
        ).toSliver(),

        // 搜索设置分组
        ModernSectionTitle(
          title: "Search Settings".tl,
          icon: Icons.search,
          subtitle: "Configure search behavior and filters".tl,
        ).toSliver(),

        SettingCard(
          children: [
            ModernActionSetting(
              title: "Search Sources".tl,
              callback: () =>
                  showPopUpWidget(App.rootContext, setSearchSourcesWidget()),
              actionTitle: "Manage".tl,
              icon: Icons.source,
              actionIcon: Icons.settings,
            ),
            ModernSelectSetting(
              title: "Default Search Target".tl,
              settingKey: "defaultSearchTarget",
              optionTranslation: {
                '_aggregated_': "Aggregated".tl,
                ...(() {
                  var map = <String, String>{};
                  for (var c in ComicSource.all()) {
                    map[c.key] = c.name;
                  }
                  return map;
                }()),
              },
              icon: Icons.gps_fixed,
            ),
            ModernSelectSetting(
              title: "Auto Language Filters".tl,
              settingKey: "autoAddLanguageFilter",
              optionTranslation: {
                'none': "None".tl,
                'chinese': "Chinese",
                'english': "English",
                'japanese': "Japanese",
              },
              icon: Icons.language,
            ),
            ModernActionSetting(
              title: "Keyword blocking".tl,
              callback: () => showPopUpWidget(
                App.rootContext,
                const _ManageBlockingWordView(),
              ),
              actionTitle: "Manage".tl,
              icon: Icons.block,
              actionIcon: Icons.settings,
            ),
          ],
        ).toSliver(),

        // 界面行为分组
        ModernSectionTitle(
          title: "Interface Behavior".tl,
          icon: Icons.tune,
          subtitle: "Customize interface behavior and preferences".tl,
        ).toSliver(),

        SettingCard(
          children: [
            ModernSelectSetting(
              title: "Initial Page".tl,
              settingKey: "initialPage",
              optionTranslation: {
                '0': "Home Page".tl,
                '1': "Favorites Page".tl,
                '2': "Explore Page".tl,
                '3': "Categories Page".tl,
              },
              icon: Icons.home,
            ),
            ModernSwitchSetting(
              title: "Show favorite status on comic tile".tl,
              settingKey: "showFavoriteStatusOnTile",
              icon: Icons.favorite_border,
              subtitle: "Display favorite indicator on comic tiles".tl,
            ),
            ModernSwitchSetting(
              title: "Show history on comic tile".tl,
              settingKey: "showHistoryStatusOnTile",
              icon: Icons.history,
              subtitle: "Display reading progress on comic tiles".tl,
            ),
            ModernSwitchSetting(
              title: "Reverse default chapter order".tl,
              settingKey: "reverseChapterOrder",
              icon: Icons.swap_vert,
              subtitle: "Show newest chapters first".tl,
            ),
          ],
        ).toSliver(),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _ManageBlockingWordView extends StatefulWidget {
  const _ManageBlockingWordView();

  @override
  State<_ManageBlockingWordView> createState() =>
      _ManageBlockingWordViewState();
}

class _ManageBlockingWordViewState extends State<_ManageBlockingWordView> {
  @override
  Widget build(BuildContext context) {
    assert(appdata.settings["blockedWords"] is List);
    return PopUpWidgetScaffold(
      title: "Keyword blocking".tl,
      tailing: [
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text("Add".tl),
          onPressed: add,
        ),
      ],
      body: ListView.builder(
        itemCount: appdata.settings["blockedWords"].length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(appdata.settings["blockedWords"][index]),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                appdata.settings["blockedWords"].removeAt(index);
                appdata.saveData();
                setState(() {});
              },
            ),
          );
        },
      ),
    );
  }

  void add() {
    showDialog(
      context: App.rootContext,
      builder: (context) {
        var controller = TextEditingController();
        String? error;
        return StatefulBuilder(
          builder: (context, setState) {
            return ContentDialog(
              title: "Add keyword".tl,
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: Text("Keyword".tl),
                  errorText: error,
                ),
                onChanged: (s) {
                  if (error != null) {
                    setState(() {
                      error = null;
                    });
                  }
                },
              ).paddingHorizontal(12),
              actions: [
                Button.filled(
                  onPressed: () {
                    if (appdata.settings["blockedWords"].contains(
                      controller.text,
                    )) {
                      setState(() {
                        error = "Keyword already exists".tl;
                      });
                      return;
                    }
                    appdata.settings["blockedWords"].add(controller.text);
                    appdata.saveData();
                    this.setState(() {});
                    context.pop();
                  },
                  child: Text("Add".tl),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

Widget setExplorePagesWidget() {
  var pages = <String, String>{};
  for (var c in ComicSource.all()) {
    for (var page in c.explorePages) {
      pages[page.title] = page.title.ts(c.key);
    }
  }
  return _MultiPagesFilter(
    title: "Explore Pages".tl,
    settingsIndex: "explore_pages",
    pages: pages,
  );
}

Widget setCategoryPagesWidget() {
  var pages = <String, String>{};
  for (var c in ComicSource.all()) {
    if (c.categoryData != null) {
      pages[c.categoryData!.key] = c.categoryData!.title;
    }
  }
  return _MultiPagesFilter(
    title: "Category Pages".tl,
    settingsIndex: "categories",
    pages: pages,
  );
}

Widget setFavoritesPagesWidget() {
  var pages = <String, String>{};
  for (var c in ComicSource.all()) {
    if (c.favoriteData != null) {
      pages[c.favoriteData!.key] = c.favoriteData!.title;
    }
  }
  return _MultiPagesFilter(
    title: "Network Favorite Pages".tl,
    settingsIndex: "favorites",
    pages: pages,
  );
}

Widget setSearchSourcesWidget() {
  var pages = <String, String>{};
  for (var c in ComicSource.all()) {
    if (c.searchPageData != null) {
      pages[c.key] = c.name;
    }
  }
  return _MultiPagesFilter(
    title: "Search Sources".tl,
    settingsIndex: "searchSources",
    pages: pages,
  );
}
