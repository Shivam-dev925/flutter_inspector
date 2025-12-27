import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dev_panel/src/plugins/dev_panel_plugin.dart';
import 'package:flutter_dev_panel/src/models/network_call.dart';
import 'package:flutter_dev_panel/src/plugins/network_inspector/dio_interceptor.dart';
import 'package:flutter_dev_panel/src/plugins/network_inspector/http_client_wrapper.dart';

/// Plugin to inspect network requests and responses
class NetworkInspectorPlugin extends DevPanelPlugin {
  final Map<String, NetworkCall> _calls = {};
  final _controller = NetworkInspectorController();
  final int maxCalls;

  NetworkInspectorPlugin({this.maxCalls = 100});

  @override
  String get name => 'Network';

  @override
  IconData get icon => Icons.network_check;

  /// Wrap an HTTP client to capture requests
  http.Client wrapHttpClient(http.Client client) {
    return DevPanelHttpClient(client, _recordCall);
  }

  /// Get a Dio interceptor to add to your Dio instance
  DevPanelDioInterceptor getDioInterceptor() {
    return DevPanelDioInterceptor(_recordCall);
  }

  void _recordCall(NetworkCall call) {
    _calls[call.id] = call;

    // Trim old calls if exceeding max
    if (_calls.length > maxCalls) {
      final keysToRemove = _calls.keys.take(_calls.length - maxCalls).toList();
      for (final key in keysToRemove) {
        _calls.remove(key);
      }
    }

    _controller._notifyListeners();
  }

  void clear() {
    _calls.clear();
    _controller._notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return _NetworkInspectorWidget(
      calls: _calls.values.toList().reversed.toList(),
      onClear: clear,
      controller: _controller,
    );
  }
}

class NetworkInspectorController extends ChangeNotifier {
  void _notifyListeners() {
    notifyListeners();
  }
}

class _NetworkInspectorWidget extends StatefulWidget {
  final List<NetworkCall> calls;
  final VoidCallback onClear;
  final NetworkInspectorController controller;

  const _NetworkInspectorWidget({
    required this.calls,
    required this.onClear,
    required this.controller,
  });

  @override
  State<_NetworkInspectorWidget> createState() => _NetworkInspectorWidgetState();
}

class _NetworkInspectorWidgetState extends State<_NetworkInspectorWidget> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, success, error

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCallsChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCallsChanged);
    super.dispose();
  }

  void _onCallsChanged() {
    setState(() {});
  }

  List<NetworkCall> get _filteredCalls {
    var calls = widget.calls;

    // Filter by status
    if (_statusFilter == 'success') {
      calls = calls.where((call) => call.isSuccess).toList();
    } else if (_statusFilter == 'error') {
      calls = calls.where((call) => call.isError).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      calls = calls.where((call) {
        return call.url.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            call.method.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return calls;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: widget.calls.isEmpty ? _buildEmptyState() : _buildCallsList(),
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
                '${_filteredCalls.length}',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilter('all', 'All'),
                      _buildStatusFilter('success', 'OK'),
                      _buildStatusFilter('error', 'Err'),
                    ],
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
          const SizedBox(height: 8),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search URL or method...',
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

  Widget _buildStatusFilter(String value, String label) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 3),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFF6366F1),
        backgroundColor: Colors.white.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        labelPadding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
        onSelected: (selected) {
          setState(() {
            _statusFilter = value;
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
          const Icon(Icons.network_check, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            'No network calls yet',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'HTTP requests will appear here',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCallsList() {
    return ListView.builder(
      itemCount: _filteredCalls.length,
      itemBuilder: (context, index) {
        final call = _filteredCalls[index];
        return _buildCallItem(call);
      },
    );
  }

  Widget _buildCallItem(NetworkCall call) {
    final color = call.isError
        ? Colors.red
        : call.isSuccess
            ? Colors.green
            : Colors.orange;

    return InkWell(
      onTap: () => _showCallDetails(call),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getMethodColor(call.method),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          call.method,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (call.statusCode != null)
                        Text(
                          call.statusCode.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      if (call.duration != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${call.duration}ms',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getUrlPath(call.url),
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getUrlPath(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.path + (uri.query.isNotEmpty ? '?${uri.query}' : '');
    } catch (e) {
      return url;
    }
  }

  void _showCallDetails(NetworkCall call) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _CallDetailsPage(call: call),
      ),
    );
  }
}

class _CallDetailsPage extends StatefulWidget {
  final NetworkCall call;

  const _CallDetailsPage({required this.call});

  @override
  State<_CallDetailsPage> createState() => _CallDetailsPageState();
}

class _CallDetailsPageState extends State<_CallDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dateFormat = DateFormat('HH:mm:ss.SSS');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.call.method),
        actions: [
          IconButton(
            tooltip: 'Copy cURL',
            icon: const Icon(Icons.terminal),
            onPressed: _copyCurl,
          ),
          IconButton(
            tooltip: 'Copy All',
            icon: const Icon(Icons.copy),
            onPressed: _copyAllDetails,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Request'),
            Tab(text: 'Response'),
            Tab(text: 'Headers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildRequestTab(),
          _buildResponseTab(),
          _buildHeadersTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard('General', [
          _buildInfoRow('URL', widget.call.url),
          _buildInfoRow('Method', widget.call.method),
          if (widget.call.statusCode != null)
            _buildInfoRow('Status', '${widget.call.statusCode} ${widget.call.statusMessage ?? ''}'),
          if (widget.call.duration != null)
            _buildInfoRow('Duration', '${widget.call.duration}ms'),
          _buildInfoRow('Time', _dateFormat.format(widget.call.requestTime)),
        ]),
        if (widget.call.error != null) ...[
          const SizedBox(height: 16),
          _buildInfoCard('Error', [
            Text(
              widget.call.error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildRequestTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.call.requestBody != null) ...[
          _buildCodeBlock('Request Body', widget.call.requestBody),
        ] else
          Center(child: Text('No request body', style: TextStyle(color: Colors.white.withOpacity(0.6)))),
      ],
    );
  }

  Widget _buildResponseTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.call.responseBody != null) ...[
          _buildCodeBlock('Response Body', widget.call.responseBody),
        ] else
          Center(child: Text('No response body', style: TextStyle(color: Colors.white.withOpacity(0.6)))),
      ],
    );
  }

  Widget _buildHeadersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.call.requestHeaders != null &&
            widget.call.requestHeaders!.isNotEmpty) ...[
          _buildInfoCard('Request Headers', [
            ...widget.call.requestHeaders!.entries.map(
              (e) => _buildInfoRow(e.key, e.value),
            ),
          ]),
        ],
        if (widget.call.responseHeaders != null &&
            widget.call.responseHeaders!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInfoCard('Response Headers', [
            ...widget.call.responseHeaders!.entries.map(
              (e) => _buildInfoRow(e.key, e.value),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
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
            width: 100,
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

  Widget _buildCodeBlock(String title, dynamic content) {
    String formattedContent;
    try {
      if (content is String) {
        // Try to parse and pretty-print JSON
        final decoded = jsonDecode(content);
        formattedContent = const JsonEncoder.withIndent('  ').convert(decoded);
      } else {
        formattedContent = const JsonEncoder.withIndent('  ').convert(content);
      }
    } catch (e) {
      formattedContent = content.toString();
    }

    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: formattedContent));
                    debugPrint('[DevPanel] Copied to clipboard');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: SelectableText(
                formattedContent,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyAllDetails() {
    final buffer = StringBuffer();
    buffer.writeln('${widget.call.method} ${widget.call.url}');
    buffer.writeln('Status: ${widget.call.statusCode}');
    if (widget.call.duration != null) {
      buffer.writeln('Duration: ${widget.call.duration}ms');
    }
    buffer.writeln('\nRequest Body:');
    buffer.writeln(widget.call.requestBody?.toString() ?? 'None');
    buffer.writeln('\nResponse Body:');
    buffer.writeln(widget.call.responseBody?.toString() ?? 'None');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    debugPrint('[DevPanel] Copied all network details to clipboard');
  }

  void _copyCurl() {
    final call = widget.call;
    final buffer = StringBuffer();
    buffer.write("curl -X ${call.method.toUpperCase()}");

    // Headers
    call.requestHeaders?.forEach((key, value) {
      buffer.write(" -H '$key: $value'");
    });

    // Body
    if (call.requestBody != null && call.requestBody.toString().isNotEmpty) {
      // Basic escaping for single quotes
      final body = call.requestBody.toString().replaceAll("'", "'\\''");
      buffer.write(" -d '$body'");
    }

    buffer.write(" '${call.url}'");

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied cURL command')),
    );
  }
}
