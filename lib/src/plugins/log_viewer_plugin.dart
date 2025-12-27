import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dev_panel/src/plugins/dev_panel_plugin.dart';
import 'package:flutter_dev_panel/src/models/log_entry.dart';

/// Plugin to view in-app logs
class LogViewerPlugin extends DevPanelPlugin {
  final List<LogEntry> _logs = [];
  final int maxLogs;
  final _controller = LogViewerController();

  LogViewerPlugin({this.maxLogs = 500});

  @override
  String get name => 'Logs';

  @override
  IconData get icon => Icons.description_outlined;

  /// Add a log entry
  void log(String message, {LogLevel level = LogLevel.info, Map<String, dynamic>? data}) {
    final entry = LogEntry(
      message: message,
      level: level,
      data: data,
    );

    _logs.insert(0, entry); // Add to beginning for newest first

    // Trim logs if exceeding max
    if (_logs.length > maxLogs) {
      _logs.removeRange(maxLogs, _logs.length);
    }

    _controller._notifyListeners();
  }

  /// Clear all logs
  void clear() {
    _logs.clear();
    _controller._notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return _LogViewerWidget(
      logs: _logs,
      onClear: clear,
      controller: _controller,
    );
  }
}

/// Controller for log viewer updates
class LogViewerController extends ChangeNotifier {
  void _notifyListeners() {
    notifyListeners();
  }
}

class _LogViewerWidget extends StatefulWidget {
  final List<LogEntry> logs;
  final VoidCallback onClear;
  final LogViewerController controller;

  const _LogViewerWidget({
    required this.logs,
    required this.onClear,
    required this.controller,
  });

  @override
  State<_LogViewerWidget> createState() => _LogViewerWidgetState();
}

class _LogViewerWidgetState extends State<_LogViewerWidget> {
  final Set<LogLevel> _selectedLevels = LogLevel.values.toSet();
  final _dateFormat = DateFormat('HH:mm:ss.SSS');

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onLogsChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onLogsChanged);
    super.dispose();
  }

  void _onLogsChanged() {
    setState(() {});
  }

  List<LogEntry> get _filteredLogs {
    return widget.logs.where((log) => _selectedLevels.contains(log.level)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: _filteredLogs.isEmpty ? _buildEmptyState() : _buildLogList(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Text(
            '${_filteredLogs.length}',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: LogLevel.values.map((level) => _buildLevelFilter(level)).toList(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: widget.onClear,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelFilter(LogLevel level) {
    final isSelected = _selectedLevels.contains(level);
    final entry = LogEntry(message: '', level: level);

    // Shortened labels
    final shortName = {
      'Debug': 'D',
      'Info': 'I',
      'Warning': 'W',
      'Error': 'E',
    }[entry.levelName] ?? entry.levelName;

    return Padding(
      padding: const EdgeInsets.only(right: 3),
      child: FilterChip(
        label: Text(
          shortName,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : entry.color,
          ),
        ),
        selected: isSelected,
        selectedColor: entry.color,
        backgroundColor: Colors.white.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        labelPadding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: isSelected ? entry.color : Colors.white.withOpacity(0.2)),
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _selectedLevels.add(level);
            } else {
              _selectedLevels.remove(level);
            }
          });
        },
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            'No logs yet',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Logs will appear here when you use DevPanel.log()',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        return _buildLogItem(log);
      },
    );
  }

  Widget _buildLogItem(LogEntry log) {
    return InkWell(
      onTap: () => _showLogDetails(log),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(log.icon, size: 18, color: log.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.message,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateFormat.format(log.timestamp),
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (log.data != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DATA',
                  style: TextStyle(fontSize: 10, color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLogDetails(LogEntry log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: Row(
                  children: [
                    Icon(log.icon, color: log.color),
                    const SizedBox(width: 8),
                    Text(
                      log.levelName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: log.color,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _dateFormat.format(log.timestamp),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: Colors.white70),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: log.message));
                        debugPrint('[DevPanel] Copied log to clipboard');
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Message',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(log.message, style: const TextStyle(color: Colors.white)),
                    if (log.data != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Additional Data',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: SelectableText(
                          log.data.toString(),
                          style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
