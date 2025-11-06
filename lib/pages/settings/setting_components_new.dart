part of 'settings_page.dart';

/// 现代化的设置卡片组件
class SettingCard extends StatelessWidget {
  const SettingCard({
    super.key,
    required this.children,
    this.title,
    this.subtitle,
    this.icon,
    this.margin,
    this.padding,
  });

  final List<Widget> children;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: context.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: ts.s16.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: ts.s12.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 0.5,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ],
          Padding(
            padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

/// 现代化的开关设置组件
class ModernSwitchSetting extends StatefulWidget {
  const ModernSwitchSetting({
    super.key,
    required this.title,
    required this.settingKey,
    this.onChanged,
    this.subtitle,
    this.comicId,
    this.comicSource,
    this.icon,
  });

  final String title;
  final String settingKey;
  final VoidCallback? onChanged;
  final String? subtitle;
  final String? comicId;
  final String? comicSource;
  final IconData? icon;

  @override
  State<ModernSwitchSetting> createState() => _ModernSwitchSettingState();
}

class _ModernSwitchSettingState extends State<ModernSwitchSetting> {
  @override
  Widget build(BuildContext context) {
    var value = widget.comicId == null
        ? appdata.settings[widget.settingKey]
        : appdata.settings.getReaderSetting(
            widget.comicId!,
            widget.comicSource!,
            widget.settingKey,
          );

    assert(value is bool);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: widget.icon != null
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: context.colorScheme.primary,
                ),
              )
            : null,
        title: Text(
          widget.title,
          style: ts.s14.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colorScheme.onSurface,
          ),
        ),
        subtitle: widget.subtitle != null
            ? Text(
                widget.subtitle!,
                style: ts.s12.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: Transform.scale(
          scale: 0.9,
          child: Switch(
            value: value,
            onChanged: (value) {
              setState(() {
                if (widget.comicId == null) {
                  appdata.settings[widget.settingKey] = value;
                } else {
                  appdata.settings.setReaderSetting(
                    widget.comicId!,
                    widget.comicSource!,
                    widget.settingKey,
                    value,
                  );
                }
              });
              appdata.saveData().then((_) {
                widget.onChanged?.call();
              });
            },
          ),
        ),
      ),
    );
  }
}

/// 现代化的选择设置组件
class ModernSelectSetting extends StatefulWidget {
  const ModernSelectSetting({
    super.key,
    required this.title,
    required this.settingKey,
    required this.optionTranslation,
    this.onChanged,
    this.help,
    this.comicId,
    this.comicSource,
    this.icon,
  });

  final String title;
  final String settingKey;
  final Map<String, String> optionTranslation;
  final VoidCallback? onChanged;
  final String? help;
  final String? comicId;
  final String? comicSource;
  final IconData? icon;

  @override
  State<ModernSelectSetting> createState() => _ModernSelectSettingState();
}

class _ModernSelectSettingState extends State<ModernSelectSetting> {
  @override
  Widget build(BuildContext context) {
    var value = widget.comicId == null
        ? appdata.settings[widget.settingKey]
        : appdata.settings.getReaderSetting(
            widget.comicId!,
            widget.comicSource!,
            widget.settingKey,
          );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: widget.icon != null
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: context.colorScheme.primary,
                ),
              )
            : null,
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: ts.s14.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
            if (widget.help != null) ...[
              const SizedBox(width: 8),
              Button.icon(
                size: 18,
                icon: const Icon(Icons.help_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return ContentDialog(
                        title: "Help".tl,
                        content: Text(
                          widget.help!,
                        ).paddingHorizontal(16).fixWidth(double.infinity),
                        actions: [
                          Button.filled(
                            onPressed: context.pop,
                            child: Text("OK".tl),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.optionTranslation[value] ?? "None",
                  style: ts.s14.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        onTap: () {
          _showSelectionDialog();
        },
      ),
    );
  }

  void _showSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.title),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.optionTranslation.entries.map((entry) {
              var isSelected =
                  (widget.comicId == null
                      ? appdata.settings[widget.settingKey]
                      : appdata.settings.getReaderSetting(
                          widget.comicId!,
                          widget.comicSource!,
                          widget.settingKey,
                        )) ==
                  entry.key;

              return ListTile(
                title: Text(entry.value),
                trailing: isSelected
                    ? Icon(Icons.check, color: context.colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() {
                    if (widget.comicId == null) {
                      appdata.settings[widget.settingKey] = entry.key;
                    } else {
                      appdata.settings.setReaderSetting(
                        widget.comicId!,
                        widget.comicSource!,
                        widget.settingKey,
                        entry.key,
                      );
                    }
                  });
                  appdata.saveData();
                  widget.onChanged?.call();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// 现代化的滑块设置组件
class ModernSliderSetting extends StatefulWidget {
  const ModernSliderSetting({
    super.key,
    required this.title,
    required this.settingsIndex,
    required this.interval,
    required this.min,
    required this.max,
    this.onChanged,
    this.comicId,
    this.comicSource,
    this.icon,
    this.unit,
  });

  final String title;
  final String settingsIndex;
  final double interval;
  final double min;
  final double max;
  final VoidCallback? onChanged;
  final String? comicId;
  final String? comicSource;
  final IconData? icon;
  final String? unit;

  @override
  State<ModernSliderSetting> createState() => _ModernSliderSettingState();
}

class _ModernSliderSettingState extends State<ModernSliderSetting> {
  @override
  Widget build(BuildContext context) {
    var value =
        (widget.comicId == null
                ? appdata.settings[widget.settingsIndex]
                : appdata.settings.getReaderSetting(
                    widget.comicId!,
                    widget.comicSource!,
                    widget.settingsIndex,
                  ))
            .toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: context.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  widget.title,
                  style: ts.s14.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "${value.toString()}${widget.unit ?? ''}",
                  style: ts.s12.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: context.colorScheme.primary,
              inactiveTrackColor: context.colorScheme.primary.withValues(
                alpha: 0.2,
              ),
              thumbColor: context.colorScheme.primary,
              overlayColor: context.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value,
              onChanged: (newValue) {
                setState(() {
                  if (newValue.toInt() == newValue) {
                    if (widget.comicId == null) {
                      appdata.settings[widget.settingsIndex] = newValue.toInt();
                    } else {
                      appdata.settings.setReaderSetting(
                        widget.comicId!,
                        widget.comicSource!,
                        widget.settingsIndex,
                        newValue.toInt(),
                      );
                    }
                  } else {
                    if (widget.comicId == null) {
                      appdata.settings[widget.settingsIndex] = newValue;
                    } else {
                      appdata.settings.setReaderSetting(
                        widget.comicId!,
                        widget.comicSource!,
                        widget.settingsIndex,
                        newValue,
                      );
                    }
                  }
                  appdata.saveData();
                });
                widget.onChanged?.call();
              },
              divisions: ((widget.max - widget.min) / widget.interval).toInt(),
              min: widget.min,
              max: widget.max,
            ),
          ),
        ],
      ),
    );
  }
}

/// 现代化的操作设置组件
class ModernActionSetting extends StatelessWidget {
  const ModernActionSetting({
    super.key,
    required this.title,
    required this.callback,
    required this.actionTitle,
    this.subtitle,
    this.icon,
    this.actionIcon,
  });

  final String title;
  final String? subtitle;
  final VoidCallback callback;
  final String actionTitle;
  final IconData? icon;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: icon != null
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: context.colorScheme.primary),
              )
            : null,
        title: Text(
          title,
          style: ts.s14.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: ts.s12.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.colorScheme.primary.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (actionIcon != null) ...[
                Icon(actionIcon, size: 16, color: context.colorScheme.primary),
                const SizedBox(width: 6),
              ],
              Text(
                actionTitle,
                style: ts.s12.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        onTap: callback,
      ),
    );
  }
}

/// 现代化的分组标题
class ModernSectionTitle extends StatelessWidget {
  const ModernSectionTitle({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colorScheme.primary,
                  context.colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: context.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 24, color: context.colorScheme.onPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ts.s20.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: ts.s14.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
