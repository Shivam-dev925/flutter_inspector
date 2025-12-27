import 'package:flutter/material.dart';

/// A quick action that can be executed from the dev panel
class QuickAction {
  final String name;
  final String? description;
  final IconData icon;
  final Future<void> Function() onTap;

  QuickAction({
    required this.name,
    this.description,
    this.icon = Icons.touch_app,
    required this.onTap,
  });
}
