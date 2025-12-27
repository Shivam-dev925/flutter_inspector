import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

// Global instances
late LogViewerPlugin logViewer;
late NetworkInspectorPlugin networkInspector;
late FeatureFlagsPlugin featureFlags;
late Dio dio;

void main() {
  // Initialize Flutter bindings before any platform channel access
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize plugins
  logViewer = LogViewerPlugin(maxLogs: 500);
  networkInspector = NetworkInspectorPlugin(maxCalls: 100);
  featureFlags = FeatureFlagsPlugin(
    flags: [
      FeatureFlag(
        key: 'dark_mode',
        name: 'Dark Mode',
        description: 'Enable dark theme',
        isEnabled: true,
      ),
    ],
  );

  // Initialize DevPanel
  DevPanel.init(
    enableInRelease: false,
    shakeToOpen: true,
    shakeSensitivity: 5,
    plugins: [
      AppInfoPlugin(
        appName: 'DevPanel Demo',
        version: '1.0.0',
        buildNumber: '1',
      ),
      networkInspector,
      StorageViewerPlugin(),
      logViewer,
      featureFlags,
      QuickActionsPlugin(
        actions: [
          QuickAction(
            name: 'Clear Cache',
            description: 'Clear all app cache',
            icon: Icons.delete_sweep,
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              logViewer.log('Cache cleared', level: LogLevel.info);
            },
          ),
          QuickAction(
            name: 'Test Log',
            description: 'Add a test log entry',
            icon: Icons.article,
            onTap: () async {
              logViewer.log(
                'This is a test log message',
                level: LogLevel.info,
                data: {'timestamp': DateTime.now().toString()},
              );
            },
          ),
          QuickAction(
            name: 'Test API Call',
            description: 'Make a test network request',
            icon: Icons.cloud,
            onTap: () async {
              await dio.get('https://jsonplaceholder.typicode.com/posts/1');
              logViewer.log('API call completed', level: LogLevel.info);
            },
          ),
          QuickAction(
            name: 'Show Error',
            description: 'Log an error message',
            icon: Icons.error,
            onTap: () async {
              logViewer.log(
                'This is an error message',
                level: LogLevel.error,
                data: {'error': 'Something went wrong!'},
              );
            },
          ),
        ],
      ),
    ],
  );

  // Initialize Dio with interceptor
  dio = Dio();
  dio.interceptors.add(networkInspector.getDioInterceptor());

  // Test print AFTER DevPanel init - this SHOULD be captured
  print('[AFTER INIT] This print happens after DevPanel initialization');
  debugPrint('[AFTER INIT] This debugPrint happens after DevPanel initialization');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen to feature flag changes
    featureFlags.addListener(_onFlagChanged);
  }

  @override
  void dispose() {
    featureFlags.removeListener(_onFlagChanged);
    super.dispose();
  }

  void _onFlagChanged() {
    // Rebuild when flags change
    setState(() {});
    debugPrint('Feature flag changed! Dark mode: ${featureFlags.isFlagEnabled('dark_mode')}');
  }

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    final isDarkMode = featureFlags.isFlagEnabled('dark_mode');

    return MaterialApp(
      builder: (context, child) => DevPanel.attach(child!),
      debugShowCheckedModeBanner: false,
      title: 'DevPanel Premium Demo',
      // Switch between dark and light theme based on feature flag
      theme: isDarkMode
          ? ThemeData.dark().copyWith(
              scaffoldBackgroundColor: const Color(0xFF0F172A),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF6366F1), // Indigo
                secondary: Color(0xFFEC4899), // Pink
                surface: Color(0xFF1E293B),
                surfaceContainerHigh: Color(0xFF334155),
                onSurface: Color(0xFFF8FAFC),
              ),
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
              useMaterial3: true,
            )
          : ThemeData.light().copyWith(
              scaffoldBackgroundColor: Colors.grey[50],
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF6366F1), // Indigo
                secondary: const Color(0xFFEC4899), // Pink
                surface: Colors.white,
                surfaceContainerHigh: Colors.grey[100]!,
                onSurface: Colors.black87,
              ),
              textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
              useMaterial3: true,
            ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    logViewer.log('App started', level: LogLevel.info);

    // Test print capture
    print('This is a regular print() statement - should appear in DevPanel!');
    debugPrint('This is a debugPrint() statement - also captured!');

    _loadStoredCounter();
  }

  Future<void> _loadStoredCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('counter') ?? 0;
    });
    logViewer.log('Counter loaded: $_counter', level: LogLevel.debug);
  }

  Future<void> _incrementCounter() async {
    setState(() {
      _counter++;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter', _counter);
    await prefs.setString('last_updated', DateTime.now().toIso8601String());
    await prefs.setBool('has_interacted', true);

    // Test print capture during user interaction
    print('Counter incremented! New value: $_counter');

    logViewer.log(
      'Counter incremented to $_counter',
      level: LogLevel.info,
      data: {'new_value': _counter},
    );
  }

  Future<void> _makeApiCall() async {
    try {
      logViewer.log('Making GET request...', level: LogLevel.info);

      // GET request with query parameters and custom headers
      final getResponse = await dio.get(
        'https://jsonplaceholder.typicode.com/posts',
        queryParameters: {
          'userId': 1,
          '_limit': 5,
          '_page': 1,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer demo-token-12345',
            'X-Custom-Header': 'DevPanel-Demo',
            'Accept': 'application/json',
          },
        ),
      );

      logViewer.log(
        'GET request successful',
        level: LogLevel.info,
        data: {'status': getResponse.statusCode, 'items': getResponse.data.length},
      );

      print('✅ GET request completed successfully - ${getResponse.data.length} items loaded');

      // POST request with payload and custom headers
      await Future.delayed(const Duration(milliseconds: 500));

      logViewer.log('Making POST request...', level: LogLevel.info);

      final postResponse = await dio.post(
        'https://jsonplaceholder.typicode.com/posts',
        data: {
          'title': 'DevPanel Test Post',
          'body': 'This is a test post created from DevPanel demo app',
          'userId': _counter,
          'timestamp': DateTime.now().toIso8601String(),
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer demo-token-67890',
            'X-Request-ID': 'req-${DateTime.now().millisecondsSinceEpoch}',
          },
        ),
      );

      logViewer.log(
        'POST request successful',
        level: LogLevel.info,
        data: {'status': postResponse.statusCode, 'createdId': postResponse.data['id']},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('API calls completed! Check Network tab'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      print('❌ Error during API call: $e');

      logViewer.log(
        'API call failed',
        level: LogLevel.error,
        data: {'error': e.toString()},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        title: Text(
          'DevPanel Demo',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.developer_mode),
              tooltip: 'Open Dev Panel',
              onPressed: () => DevPanel.show(),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.5,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.15),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    _buildCounterCard(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                    const SizedBox(height: 48),
                    _buildFeatureGrid(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Interaction Counter',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '$_counter',
            style: GoogleFonts.outfit(
              fontSize: 72,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Push the button',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          label: 'Increment',
          icon: Icons.add_rounded,
          color: Theme.of(context).colorScheme.primary,
          onPressed: _incrementCounter,
        ),
        const SizedBox(width: 16),
        _buildActionButton(
          label: 'API Call',
          icon: Icons.cloud_download_rounded,
          color: Theme.of(context).colorScheme.secondary,
          onPressed: _makeApiCall,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: color.withOpacity(0.5),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 0;
            return 8;
          }),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {'icon': '📱', 'label': 'App Info', 'desc': 'Device details'},
      {'icon': '🌐', 'label': 'Network', 'desc': 'Inspect APIs'},
      {'icon': '💾', 'label': 'Storage', 'desc': 'SharedPrefs'},
      {'icon': '📝', 'label': 'Logs', 'desc': 'App logs'},
      {'icon': '🚩', 'label': 'Flags', 'desc': 'Feature Toggles'},
      {'icon': '⚡', 'label': 'Actions', 'desc': 'Quick Tools'},
    ];

    return Column(
      children: [
        Text(
          'Developer Tools',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: features.map((feature) {
            return _buildFeatureChip(
              feature['icon']!,
              feature['label']!,
              feature['desc']!,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeatureChip(String icon, String label, String desc) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHigh.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
