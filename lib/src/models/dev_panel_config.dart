import 'package:flutter_dev_panel/src/plugins/dev_panel_plugin.dart';

/// Configuration for the DevPanel
class DevPanelConfig {
  /// Enable the dev panel in release builds (default: false for safety)
  final bool enableInRelease;

  /// Enable shake gesture to open panel (default: true)
  final bool shakeToOpen;

  /// Shake sensitivity (1-10, default: 5)
  final int shakeSensitivity;

  /// List of plugins to enable
  final List<DevPanelPlugin> plugins;

  /// Custom theme data for the panel
  final DevPanelTheme? theme;

  const DevPanelConfig({
    this.enableInRelease = false,
    this.shakeToOpen = true,
    this.shakeSensitivity = 5,
    this.plugins = const [],
    this.theme,
  });

  DevPanelConfig copyWith({
    bool? enableInRelease,
    bool? shakeToOpen,
    int? shakeSensitivity,
    List<DevPanelPlugin>? plugins,
    DevPanelTheme? theme,
  }) {
    return DevPanelConfig(
      enableInRelease: enableInRelease ?? this.enableInRelease,
      shakeToOpen: shakeToOpen ?? this.shakeToOpen,
      shakeSensitivity: shakeSensitivity ?? this.shakeSensitivity,
      plugins: plugins ?? this.plugins,
      theme: theme ?? this.theme,
    );
  }
}

/// Theme configuration for the DevPanel UI
class DevPanelTheme {
  final String? fontFamily;
  final double? fontSize;

  const DevPanelTheme({
    this.fontFamily,
    this.fontSize,
  });
}
