import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_dev_panel/src/plugins/dev_panel_plugin.dart';

/// Plugin to display app and device information
class AppInfoPlugin extends DevPanelPlugin {
  final String? appName;
  final String? version;
  final String? buildNumber;

  AppInfoPlugin({
    this.appName,
    this.version,
    this.buildNumber,
  });

  @override
  String get name => 'Info';

  @override
  IconData get icon => Icons.info_outline;

  String get _platformName {
    if (kIsWeb) return 'Web';
    try {
      return Platform.operatingSystem;
    } catch (e) {
      return 'Unknown';
    }
  }

  String get _platformVersion {
    if (kIsWeb) {
      // Try to get browser info from user agent
      return 'Browser';
    }
    try {
      return Platform.operatingSystemVersion;
    } catch (e) {
      return 'Unknown';
    }
  }

  String get _localeName {
    if (kIsWeb) {
      return 'Browser default';
    }
    try {
      return Platform.localeName;
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection('App Information', [
          _buildInfoRow('Name', appName ?? 'N/A'),
          _buildInfoRow('Version', version ?? 'N/A'),
          _buildInfoRow('Build Number', buildNumber ?? 'N/A'),
        ]),
        const SizedBox(height: 24),
        _buildSection('Device Information', [
          _buildInfoRow('Platform', _platformName),
          _buildInfoRow('OS Version', _platformVersion),
          _buildInfoRow('Locale', _localeName),
        ]),
        const SizedBox(height: 24),
        _buildSection('Screen Information', [
          _buildInfoRow(
            'Size',
            '${MediaQuery.of(context).size.width.toInt()} x ${MediaQuery.of(context).size.height.toInt()}',
          ),
          _buildInfoRow(
            'Device Pixel Ratio',
            MediaQuery.of(context).devicePixelRatio.toStringAsFixed(2),
          ),
          _buildInfoRow(
            'Text Scale Factor',
            MediaQuery.of(context).textScaler.scale(1.0).toStringAsFixed(2),
          ),
        ]),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
