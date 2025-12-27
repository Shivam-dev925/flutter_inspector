import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dev_panel/src/core/dev_panel_controller.dart';
import 'package:flutter_dev_panel/src/models/dev_panel_config.dart';
import 'package:flutter_dev_panel/src/models/log_entry.dart';
import 'package:flutter_dev_panel/src/plugins/dev_panel_plugin.dart';
import 'package:flutter_dev_panel/src/plugins/log_viewer_plugin.dart';
import 'package:flutter_dev_panel/src/ui/dev_panel_overlay.dart';
import 'package:flutter_dev_panel/src/utils/shake_detector.dart';

/// Main DevPanel class for initializing and managing the dev panel
class DevPanel {
  static DevPanelController? _controller;
  static ShakeDetector? _shakeDetector;
  static DebugPrintCallback? _originalDebugPrint;

  /// Initialize the DevPanel with configuration
  static void init({
    bool enableInRelease = false,
    bool shakeToOpen = true,
    int shakeSensitivity = 5,
    List<DevPanelPlugin> plugins = const [],
    DevPanelTheme? theme,
    bool capturePrint = true, // New parameter to enable/disable print capture
  }) {
    final config = DevPanelConfig(
      enableInRelease: enableInRelease,
      shakeToOpen: shakeToOpen,
      shakeSensitivity: shakeSensitivity,
      plugins: plugins,
      theme: theme,
    );

    _controller = DevPanelController(config);

    // Initialize shake detector if enabled
    if (shakeToOpen && _controller!.isEnabled) {
      _shakeDetector = ShakeDetector(
        onShake: () => _controller?.show(),
        sensitivity: shakeSensitivity,
      );
      _shakeDetector?.startListening();
    }

    // Initialize all plugins
    for (final plugin in plugins) {
      plugin.onInit();
    }

    // Set up print/debugPrint interception if enabled
    if (capturePrint && _controller!.isEnabled) {
      _setupPrintCapture(plugins);
    }
  }

  /// Set up print and debugPrint capture
  static void _setupPrintCapture(List<DevPanelPlugin> plugins) {
    // Find LogViewerPlugin if it exists
    LogViewerPlugin? logViewer;
    for (final plugin in plugins) {
      if (plugin is LogViewerPlugin) {
        logViewer = plugin;
        break;
      }
    }

    if (logViewer == null) return;

    // Store original debugPrint
    _originalDebugPrint = debugPrint;

    // Override debugPrint to capture debugPrint() calls
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null && message.isNotEmpty) {
        // Log to DevPanel
        logViewer?.log(
          message,
          level: LogLevel.debug,
          data: {'source': 'debugPrint'},
        );
      }

      // Also call original debugPrint to maintain console output
      _originalDebugPrint?.call(message, wrapWidth: wrapWidth);
    };

    // IMPORTANT: Flutter automatically redirects print() to debugPrint() in debug mode
    // To ensure print() is captured, we need to make sure debugPrintOverride is set
    // The override above should catch both print() and debugPrint() in debug mode
  }

  /// Deprecated: Use DevPanel.init() and MaterialApp.builder with DevPanel.attach() instead
  @Deprecated('Use DevPanel.attach(child) in your MaterialApp builder')
  static Widget wrap({required Widget child}) {
    if (_controller == null) {
      throw StateError(
        'DevPanel not initialized. Call DevPanel.init() before wrapping your app.',
      );
    }

    return ChangeNotifierProvider<DevPanelController>.value(
      value: _controller!,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          child,
          Consumer<DevPanelController>(
            builder: (context, controller, _) {
              if (!controller.isEnabled) return const SizedBox.shrink();
              return const DevPanelOverlay();
            },
          ),
        ],
      ),
    );
  }

  /// Attach the DevPanel to your app (use in MaterialApp.builder)
  static Widget attach(Widget child) {
    if (_controller == null) {
      // Auto-init with defaults if not initialized (fallback)
      init();
    }

    return ChangeNotifierProvider<DevPanelController>.value(
      value: _controller!,
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => child,
          ),
          OverlayEntry(
            builder: (context) => Consumer<DevPanelController>(
              builder: (context, controller, _) {
                if (!controller.isEnabled) return const SizedBox.shrink();
                return const DevPanelOverlay();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Show the dev panel programmatically
  static void show() {
    _controller?.show();
  }

  /// Hide the dev panel
  static void hide() {
    _controller?.hide();
  }

  /// Toggle the dev panel visibility
  static void toggle() {
    _controller?.toggle();
  }

  /// Get the current controller instance
  static DevPanelController? get controller => _controller;

  /// Dispose resources (call this when app is closing)
  static void dispose() {
    _shakeDetector?.dispose();
    _shakeDetector = null;

    // Restore original debugPrint
    if (_originalDebugPrint != null) {
      debugPrint = _originalDebugPrint!;
      _originalDebugPrint = null;
    }

    // Dispose all plugins
    _controller?.plugins.forEach((plugin) => plugin.onDispose());
    _controller = null;
  }
}
