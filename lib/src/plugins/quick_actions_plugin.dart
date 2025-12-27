import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/src/plugins/dev_panel_plugin.dart';
import 'package:flutter_dev_panel/src/models/quick_action.dart';

/// Plugin to execute quick actions
class QuickActionsPlugin extends DevPanelPlugin {
  final List<QuickAction> actions;

  QuickActionsPlugin({required this.actions});

  @override
  String get name => 'Actions';

  @override
  IconData get icon => Icons.flash_on_outlined;

  @override
  Widget build(BuildContext context) {
    return _QuickActionsWidget(actions: actions);
  }
}

class _QuickActionsWidget extends StatefulWidget {
  final List<QuickAction> actions;

  const _QuickActionsWidget({required this.actions});

  @override
  State<_QuickActionsWidget> createState() => _QuickActionsWidgetState();
}

class _QuickActionsWidgetState extends State<_QuickActionsWidget> {
  final Set<int> _executingActions = {};

  @override
  Widget build(BuildContext context) {
    if (widget.actions.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.actions.length,
      itemBuilder: (context, index) {
        final action = widget.actions[index];
        return _buildActionCard(action, index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flash_on_outlined, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            'No quick actions configured',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Add actions to QuickActionsPlugin',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(QuickAction action, int index) {
    final isExecuting = _executingActions.contains(index);

    return Card(
      color: const Color(0xFF1E293B),
      child: InkWell(
        onTap: isExecuting ? null : () => _executeAction(action, index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 100,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isExecuting)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                    )
                  else
                    Icon(action.icon, size: 24, color: const Color(0xFF6366F1)),
                  const SizedBox(height: 6),
                  Text(
                    action.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (action.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      action.description!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _executeAction(QuickAction action, int index) async {
    setState(() {
      _executingActions.add(index);
    });

    try {
      await action.onTap();
      debugPrint('[DevPanel] Quick Action completed: ${action.name}');
    } catch (e) {
      debugPrint('[DevPanel] Quick Action error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _executingActions.remove(index);
        });
      }
    }
  }
}
