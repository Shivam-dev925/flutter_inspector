import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/src/plugins/dev_panel_plugin.dart';
import 'package:flutter_dev_panel/src/models/feature_flag.dart';

/// Plugin to manage feature flags
class FeatureFlagsPlugin extends DevPanelPlugin {
  final List<FeatureFlag> _flags;
  final _controller = FeatureFlagsController();

  FeatureFlagsPlugin({List<FeatureFlag>? flags}) : _flags = flags ?? [];

  @override
  String get name => 'Flags';

  @override
  IconData get icon => Icons.flag_outlined;

  /// Register a new feature flag
  void registerFlag(FeatureFlag flag) {
    _flags.add(flag);
    _controller._notifyListeners();
  }

  /// Check if a feature flag is enabled
  bool isFlagEnabled(String key) {
    final flag = _flags.firstWhere(
      (f) => f.key == key,
      orElse: () => FeatureFlag(key: key, name: key, isEnabled: false),
    );
    return flag.isEnabled;
  }

  /// Toggle a feature flag
  void toggle(String key) {
    final flag = _flags.firstWhere((f) => f.key == key);
    flag.isEnabled = !flag.isEnabled;
    _controller._notifyListeners();
  }

  /// Add a listener to be notified when flags change
  void addListener(VoidCallback listener) {
    _controller.addListener(listener);
  }

  /// Remove a listener
  void removeListener(VoidCallback listener) {
    _controller.removeListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    return _FeatureFlagsWidget(
      flags: _flags,
      onToggle: (flag) {
        flag.isEnabled = !flag.isEnabled;
        _controller._notifyListeners();
      },
      controller: _controller,
    );
  }
}

class FeatureFlagsController extends ChangeNotifier {
  void _notifyListeners() {
    notifyListeners();
  }
}

class _FeatureFlagsWidget extends StatefulWidget {
  final List<FeatureFlag> flags;
  final void Function(FeatureFlag) onToggle;
  final FeatureFlagsController controller;

  const _FeatureFlagsWidget({
    required this.flags,
    required this.onToggle,
    required this.controller,
  });

  @override
  State<_FeatureFlagsWidget> createState() => _FeatureFlagsWidgetState();
}

class _FeatureFlagsWidgetState extends State<_FeatureFlagsWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onFlagsChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onFlagsChanged);
    super.dispose();
  }

  void _onFlagsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flags.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Toggle feature flags to test different app behaviors',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.flags.map((flag) => _buildFlagItem(flag)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag_outlined, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            'No feature flags configured',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Register flags using FeatureFlagsPlugin.registerFlag()',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagItem(FeatureFlag flag) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flag.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  if (flag.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      flag.description!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    flag.key,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: flag.isEnabled,
              onChanged: (value) => widget.onToggle(flag),
              activeColor: const Color(0xFF6366F1),
            ),
          ],
        ),
      ),
    );
  }
}
