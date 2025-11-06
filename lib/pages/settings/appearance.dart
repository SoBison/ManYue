part of 'settings_page.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  @override
  Widget build(BuildContext context) {
    return SmoothCustomScrollView(
      slivers: [
        SliverAppbar(title: Text("Appearance".tl)),

        // 主题设置分组
        ModernSectionTitle(
          title: "Theme Settings".tl,
          icon: Icons.palette,
          subtitle: "Customize the app's visual appearance".tl,
        ).toSliver(),

        SettingCard(
          children: [
            ModernSelectSetting(
              title: "Theme Mode".tl,
              settingKey: "theme_mode",
              optionTranslation: {
                "system": "System".tl,
                "light": "Light".tl,
                "dark": "Dark".tl,
              },
              icon: Icons.brightness_6,
              onChanged: () async {
                App.forceRebuild();
              },
            ),
            ModernSelectSetting(
              title: "Theme Color".tl,
              settingKey: "color",
              optionTranslation: {
                "system": "System".tl,
                "red": "Red".tl,
                "pink": "Pink".tl,
                "purple": "Purple".tl,
                "green": "Green".tl,
                "orange": "Orange".tl,
                "blue": "Blue".tl,
              },
              icon: Icons.color_lens,
              onChanged: () async {
                await App.init();
                App.forceRebuild();
              },
            ),
          ],
        ).toSliver(),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
