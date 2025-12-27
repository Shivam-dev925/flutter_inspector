# flutter_dev_panel

**An in-app developer toolkit for Flutter.** Inspect network calls, view storage, toggle feature flags, and debug your app without external tools.

[![pub package](https://img.shields.io/pub/v/flutter_dev_panel.svg)](https://pub.dev/packages/flutter_dev_panel)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> The in-app developer toolkit Flutter deserves. Bring React Native's DX to Flutter.

## ✨ Why flutter_dev_panel?

Every Flutter developer has wished for better in-app debugging tools. While Flutter DevTools is powerful, it requires USB connection, desktop access, and can't be used in production builds or shared with QA teams.

**flutter_dev_panel** solves this by providing:
- 📱 **In-app access** - No external tools needed
- 🤝 **QA-friendly** - Non-technical team members can inspect app state
- 🚀 **Production-safe** - Built-in guards prevent accidental release exposure
- ⚡ **Zero friction** - Drop-in with minimal configuration
- 🔌 **Extensible** - Plugin architecture for custom tools
- 🎨 **Beautiful Dark UI** - Modern, polished interface
- 📱 **Shake to Open** - Natural gesture on mobile devices

## 🎯 Features

### 🌐 Network Inspector
- Intercepts HTTP/HTTPS requests and responses
- Works with both `http` and `Dio` packages
- View request/response headers, body, and timing
- Pretty-printed JSON responses
- Search and filter by status, URL, or method
- View full request details with cURL export

### 💾 Storage Viewer
- View all SharedPreferences key-value pairs
- Edit or delete storage entries in real-time
- Search functionality
- Type indicators (String, int, bool, etc.)
- Refresh to reload data

### 📝 Log Viewer
- In-app console for all your logs
- **Auto-captures `debugPrint()` calls** - All your existing debug prints appear automatically!
- Multiple log levels (debug, info, warning, error)
- Color-coded by severity
- Searchable and filterable by level
- Attach metadata to logs
- Tap to view full details
- Copy logs to clipboard

### 🚩 Feature Flags
- Toggle features on/off without rebuilding
- Perfect for A/B testing during development
- Real-time UI updates when flags change
- Conditional rendering based on flags
- Persistent across app restarts

### ⚡ Quick Actions
- Execute common tasks with one tap
- Clear cache, reset onboarding, trigger API calls
- Custom actions with icons and descriptions
- Loading states for async operations
- Fully customizable

### 📱 App Info
- View app version, build number
- Device information and OS details
- Screen dimensions and pixel ratio
- Platform and locale information

### 🎨 Beautiful Dark Theme
- Modern, polished dark UI
- Easy on the eyes during development
- Consistent across all plugins
- Smooth animations and transitions

### 📳 Shake Detection
- Open panel by shaking your device
- Works on X, Y, and Z axes
- Adjustable sensitivity (1-10)
- Natural gesture for mobile development

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_dev_panel: ^0.1.0

  # For network inspection
  dio: ^5.7.0          # if using Dio

  # Other dependencies used by DevPanel
  shared_preferences: ^2.3.3  # for Storage Viewer
```

Run:
```bash
flutter pub get
```

## 🚀 Quick Start

### 1. Initialize DevPanel

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:dio/dio.dart';

// Global instances for easy access
late LogViewerPlugin logViewer;
late NetworkInspectorPlugin networkInspector;
late FeatureFlagsPlugin featureFlags;
late Dio dio;

void main() {
  // IMPORTANT: Initialize bindings first
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
    enableInRelease: false,     // Safety: only enable in debug mode
    shakeToOpen: true,           // Open panel by shaking device
    shakeSensitivity: 5,         // 1-10, higher = more sensitive
    capturePrint: true,          // Auto-capture debugPrint() calls
    plugins: [
      AppInfoPlugin(
        appName: 'My App',
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
            icon: Icons.delete_sweep,
            onTap: () async {
              // Your cache clearing logic
            },
          ),
        ],
      ),
    ],
  );

  // Initialize Dio with network inspector
  dio = Dio();
  dio.interceptors.add(networkInspector.getDioInterceptor());

  runApp(const MyApp());
}
```

### 2. Attach DevPanel to Your App

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Use builder to attach DevPanel
      builder: (context, child) => DevPanel.attach(child!),
      debugShowCheckedModeBanner: false,
      title: 'My App',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}
```

### 3. Add Developer Button (Optional)

```dart
AppBar(
  title: Text('My App'),
  actions: [
    IconButton(
      icon: const Icon(Icons.developer_mode),
      tooltip: 'Open Dev Panel',
      onPressed: () => DevPanel.show(),
    ),
  ],
)
```

### 4. Start Using!

**Shake your device** or tap the developer button to open the panel!

## 📖 Usage Examples

### Network Inspection with Dio

```dart
final networkInspector = NetworkInspectorPlugin(maxCalls: 100);

DevPanel.init(plugins: [networkInspector]);

// Add interceptor to Dio
final dio = Dio();
dio.interceptors.add(networkInspector.getDioInterceptor());

// Make requests with custom headers and parameters
final response = await dio.get(
  'https://api.example.com/posts',
  queryParameters: {'userId': 1, '_limit': 5},
  options: Options(
    headers: {
      'Authorization': 'Bearer token',
      'X-Custom-Header': 'value',
    },
  ),
);

// POST with body
await dio.post(
  'https://api.example.com/posts',
  data: {
    'title': 'My Post',
    'body': 'Content here',
    'userId': 1,
  },
);

// All requests are automatically captured in Network tab!
```

### Logging

```dart
final logViewer = LogViewerPlugin(maxLogs: 500);

DevPanel.init(
  capturePrint: true,  // Enable auto-capture
  plugins: [logViewer],
);

// Method 1: Use debugPrint (auto-captured)
debugPrint('User logged in successfully');
debugPrint('Payment amount: \$99.99');

// Method 2: Use LogViewer directly for structured logs
logViewer.log('User logged in', level: LogLevel.info);

logViewer.log(
  'Payment failed',
  level: LogLevel.error,
  data: {
    'amount': 99.99,
    'reason': 'Insufficient funds',
    'timestamp': DateTime.now().toIso8601String(),
  },
);

// Logs appear in the Logs tab with filtering and search
```

### Feature Flags with Real-Time Updates

```dart
final featureFlags = FeatureFlagsPlugin(
  flags: [
    FeatureFlag(
      key: 'dark_mode',
      name: 'Dark Mode',
      description: 'Enable dark theme',
      isEnabled: true,
    ),
  ],
);

DevPanel.init(plugins: [featureFlags]);

// In your StatefulWidget
class MyApp extends StatefulWidget {
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
    setState(() {}); // Rebuild when flags change
  }

  @override
  Widget build(BuildContext context) {
    // Check flag and switch theme in real-time
    final isDarkMode = featureFlags.isFlagEnabled('dark_mode');

    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomePage(),
    );
  }
}
```

### Quick Actions

```dart
QuickActionsPlugin(
  actions: [
    QuickAction(
      name: 'Clear Cache',
      description: 'Clear all app cache',
      icon: Icons.delete_sweep,
      onTap: () async {
        await CacheManager.clearAll();
        logViewer.log('Cache cleared', level: LogLevel.info);
      },
    ),
    QuickAction(
      name: 'Test API',
      description: 'Make a test network request',
      icon: Icons.cloud,
      onTap: () async {
        await dio.get('https://jsonplaceholder.typicode.com/posts/1');
      },
    ),
    QuickAction(
      name: 'Reset Onboarding',
      description: 'Show onboarding again',
      icon: Icons.refresh,
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_complete', false);
      },
    ),
  ],
)
```

## ⚙️ Configuration Options

### DevPanel.init() Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enableInRelease` | `bool` | `false` | Enable panel in release mode (use with caution) |
| `shakeToOpen` | `bool` | `true` | Open panel by shaking device |
| `shakeSensitivity` | `int` | `5` | Shake sensitivity (1-10, higher = more sensitive) |
| `capturePrint` | `bool` | `true` | Auto-capture `debugPrint()` calls |
| `plugins` | `List<DevPanelPlugin>` | `[]` | List of plugins to enable |
| `theme` | `DevPanelTheme?` | `null` | Custom theme (currently limited) |

### Plugin Options

**LogViewerPlugin:**
```dart
LogViewerPlugin(
  maxLogs: 500,  // Maximum logs to keep in memory
)
```

**NetworkInspectorPlugin:**
```dart
NetworkInspectorPlugin(
  maxCalls: 100,  // Maximum network calls to keep
)
```

## 🎨 UI Features

- **Dark Theme**: Beautiful dark interface optimized for development
- **Smooth Animations**: Slide-up panel with backdrop blur
- **Tab Navigation**: Easy switching between tools
- **Search & Filter**: Find what you need quickly
- **Copy to Clipboard**: Copy logs, values, and network data
- **Empty States**: Helpful messages when no data is available
- **Scrollable Content**: All tabs work on small mobile screens

## 📱 Platform Support

| Platform | Supported | Notes |
|----------|-----------|-------|
| Android  | ✅ | Shake detection works on physical devices |
| iOS      | ✅ | Shake detection works on physical devices |
| Web      | ✅ | No shake detection (use button instead) |
| Desktop  | ✅ | No shake detection (use button instead) |

## 🐛 Troubleshooting

### Panel not opening?

1. **Check initialization**: Make sure `DevPanel.init()` is called before `runApp()`
2. **Check release mode**: Panel is disabled in release builds by default (`enableInRelease: false`)
3. **Shake not working**: Try increasing `shakeSensitivity` to 8-10, or use the manual button
4. **Add `WidgetsFlutterBinding.ensureInitialized()`** at the start of `main()`

### Prints not appearing in logs?

1. Use `debugPrint()` instead of `print()` - it's automatically captured
2. Make sure `capturePrint: true` in `DevPanel.init()`
3. Regular `print()` goes directly to console in debug mode and won't be captured

### Overflow errors?

The panel UI is optimized for mobile screens. If you see overflow errors, please file an issue with your device specs.

### Network calls not showing?

1. **For Dio**: Make sure you added the interceptor: `dio.interceptors.add(networkInspector.getDioInterceptor())`
2. **For http**: Use the wrapped client: `networkInspector.wrapHttpClient(http.Client())`

## 📚 API Reference

### DevPanel

| Method | Description |
|--------|-------------|
| `DevPanel.init()` | Initialize the dev panel with configuration |
| `DevPanel.attach(Widget child)` | Attach panel to your app (use in MaterialApp.builder) |
| `DevPanel.show()` | Show the panel programmatically |
| `DevPanel.hide()` | Hide the panel |
| `DevPanel.toggle()` | Toggle panel visibility |
| `DevPanel.dispose()` | Clean up resources (call when app closes) |

### LogViewerPlugin

```dart
logViewer.log(
  String message,
  {LogLevel level = LogLevel.debug, Map<String, dynamic>? data}
)
```

**LogLevel enum:** `debug`, `info`, `warning`, `error`

### NetworkInspectorPlugin

```dart
// Get Dio interceptor
final interceptor = networkInspector.getDioInterceptor();

// Wrap http.Client
final client = networkInspector.wrapHttpClient(http.Client());
```

### FeatureFlagsPlugin

```dart
// Check if flag is enabled
bool isEnabled = featureFlags.isFlagEnabled('flag_key');

// Toggle a flag programmatically
featureFlags.toggle('flag_key');

// Listen to changes
featureFlags.addListener(() {
  // Rebuild UI
});
```

## 📂 Example App

Check out the [example](example/) directory for a full demo app showcasing all features.

To run the example:

```bash
cd example
flutter pub get
flutter run
```

The example demonstrates:
- Network inspection with GET/POST requests
- Feature flags controlling app theme
- Logging with different levels
- Storage viewer with SharedPreferences
- Quick actions for common tasks

## 🗺️ Roadmap

Features we're considering:

- [ ] Performance metrics (FPS, memory, CPU)
- [ ] Widget inspector
- [ ] Database viewer (SQLite, Drift, Hive)
- [ ] Remote logging to external service
- [ ] Custom plugin API for third-party extensions
- [ ] Screenshot/screen recording tools
- [ ] Export logs/network calls to file
- [ ] GraphQL support
- [ ] WebSocket inspection
- [ ] Push notification testing

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please read our [Contributing Guidelines](CONTRIBUTING.md) for more details.

## 📝 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

Inspired by:
- React Native's Debug Menu
- TanStack Query DevTools
- Flutter DevTools
- Flipper by Meta

## 📧 Support

- **Issues**: [GitHub Issues](https://github.com/Shivam-dev925/flutter_dev_panel/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Shivam-dev925/flutter_dev_panel/discussions)
- **Email**: your-email@example.com

## ⭐ Show Your Support

If this package helps you, please give it a ⭐ on [GitHub](https://github.com/Shivam-dev925/flutter_dev_panel)!

---

**Made with ❤️ for the Flutter community**

*Debugging should be delightful, not difficult.*
