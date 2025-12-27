import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel/src/models/dev_panel_config.dart';
import 'package:flutter_dev_panel/src/plugins/dev_panel_plugin.dart';

/// Controller for managing DevPanel state
class DevPanelController extends ChangeNotifier {
  DevPanelConfig _config;
  bool _isVisible = false;
  int _currentTabIndex = 0;

  DevPanelController(this._config);

  /// Current configuration
  DevPanelConfig get config => _config;

  /// Whether the panel is currently visible
  bool get isVisible => _isVisible;

  /// Current selected tab index
  int get currentTabIndex => _currentTabIndex;

  /// List of enabled plugins
  List<DevPanelPlugin> get plugins => _config.plugins;

  /// Update configuration
  void updateConfig(DevPanelConfig config) {
    _config = config;
    notifyListeners();
  }

  /// Show the dev panel
  void show() {
    if (_shouldEnable()) {
      _isVisible = true;
      notifyListeners();
    }
  }

  /// Hide the dev panel
  void hide() {
    _isVisible = false;
    notifyListeners();
  }

  /// Toggle panel visibility
  void toggle() {
    if (_isVisible) {
      hide();
    } else {
      show();
    }
  }

  /// Change the current tab
  void setTab(int index) {
    if (index >= 0 && index < plugins.length) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  /// Check if the panel should be enabled based on configuration
  bool _shouldEnable() {
    // Always enable in debug mode
    if (kDebugMode) return true;

    // In release mode, only enable if explicitly configured
    return _config.enableInRelease;
  }

  /// Check if the panel is allowed to run in current mode
  bool get isEnabled => _shouldEnable();
}
