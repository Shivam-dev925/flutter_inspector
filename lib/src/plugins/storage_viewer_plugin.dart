import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dev_panel/src/plugins/dev_panel_plugin.dart';

/// Plugin to view and edit local storage (SharedPreferences, etc.)
class StorageViewerPlugin extends DevPanelPlugin {
  final _controller = StorageViewerController();

  StorageViewerPlugin();

  @override
  String get name => 'Storage';

  @override
  IconData get icon => Icons.storage_outlined;

  @override
  Widget build(BuildContext context) {
    return _StorageViewerWidget(controller: _controller);
  }
}

class StorageViewerController extends ChangeNotifier {
  Map<String, dynamic> _data = {};
  bool _isLoading = false;

  Map<String, dynamic> get data => _data;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _data = {};

      for (final key in prefs.getKeys()) {
        _data[key] = prefs.get(key);
      }
    } catch (e) {
      debugPrint('Error loading storage: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      await loadData();
    } catch (e) {
      debugPrint('Error deleting key: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await loadData();
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }

  Future<void> updateValue(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      }

      await loadData();
    } catch (e) {
      debugPrint('Error updating value: $e');
    }
  }
}

class _StorageViewerWidget extends StatefulWidget {
  final StorageViewerController controller;

  const _StorageViewerWidget({required this.controller});

  @override
  State<_StorageViewerWidget> createState() => _StorageViewerWidgetState();
}

class _StorageViewerWidgetState extends State<_StorageViewerWidget> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onDataChanged);
    widget.controller.loadData();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  List<MapEntry<String, dynamic>> get _filteredData {
    if (_searchQuery.isEmpty) {
      return widget.controller.data.entries.toList();
    }

    return widget.controller.data.entries
        .where((entry) =>
            entry.key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            entry.value.toString().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: widget.controller.data.isEmpty
              ? _buildEmptyState()
              : _buildStorageList(),
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
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${_filteredData.length} items',
                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: Colors.white70),
                onPressed: () => widget.controller.loadData(),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white70),
                onPressed: () => _confirmClearAll(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search keys or values...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: Icon(Icons.search, size: 20, color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF6366F1)),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storage_outlined, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            'No storage data',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'SharedPreferences data will appear here',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageList() {
    return ListView.builder(
      itemCount: _filteredData.length,
      itemBuilder: (context, index) {
        final entry = _filteredData[index];
        return _buildStorageItem(entry.key, entry.value);
      },
    );
  }

  Widget _buildStorageItem(String key, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getValueType(value),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value.toString()));
              debugPrint('[DevPanel] Copied value to clipboard');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white70),
            onPressed: () => _confirmDelete(key),
          ),
        ],
      ),
    );
  }

  String _getValueType(dynamic value) {
    if (value is String) return 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List) return 'List<String>';
    return 'Unknown';
  }

  void _confirmDelete(String key) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Item', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "$key"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              widget.controller.deleteKey(key);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Clear All Storage', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to clear all SharedPreferences data? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              widget.controller.clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
