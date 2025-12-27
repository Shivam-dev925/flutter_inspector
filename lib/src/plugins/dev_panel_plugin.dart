import 'package:flutter/material.dart';

/// Base class for all DevPanel plugins
abstract class DevPanelPlugin {
  /// Plugin name displayed in the tab bar
  String get name;

  /// Icon for the plugin tab
  IconData get icon;

  /// Build the plugin UI
  Widget build(BuildContext context);

  /// Called when the plugin is first loaded
  void onInit() {}

  /// Called when the plugin is disposed
  void onDispose() {}

  /// Whether the plugin should be enabled
  bool get isEnabled => true;
}
