# FVM Setup Guide for flutter_dev_panel

## ✅ Current Configuration

Your project is now using **Flutter 3.38.5** with **Dart 3.10.4** via FVM (Flutter Version Manager).

### What Changed

- **Old Version**: Flutter 3.27.1 (Dart 3.6.0) - December 2024
- **New Version**: Flutter 3.38.5 (Dart 3.10.4) - December 2025
- **Improvement**: ~1 year of Flutter updates, bug fixes, and new features

## 📂 FVM Configuration Files

The following files were created:

```
flutter_dev_panel/
├── .fvm/                    # FVM cache directory (ignored in git)
├── .fvmrc                   # FVM version config
└── .gitignore              # Already configured to ignore FVM files
```

### .fvmrc Content

```json
{
  "flutter": "3.38.5"
}
```

## 🚀 Using FVM Commands

### Basic Commands

Replace all `flutter` commands with `fvm flutter`:

```bash
# Instead of: flutter run
fvm flutter run

# Instead of: flutter pub get
fvm flutter pub get

# Instead of: flutter test
fvm flutter test

# Instead of: flutter build
fvm flutter build apk
```

### Common FVM Commands

```bash
# Check current Flutter version
fvm flutter --version

# List installed Flutter versions
fvm list

# See available Flutter releases
fvm releases

# Install a different version
fvm install 3.40.0

# Switch to another version
fvm use 3.40.0

# Remove unused versions
fvm remove 3.27.1
```

## 🔧 IDE Configuration

### VS Code

1. **Install FVM Extension** (recommended):
   - Install "FVM" extension from VS Code marketplace
   - Restart VS Code
   - Extension will auto-detect `.fvmrc`

2. **Manual Configuration**:
   - Open `.vscode/settings.json` (create if doesn't exist)
   - Add:
     ```json
     {
       "dart.flutterSdkPath": ".fvm/flutter_sdk"
     }
     ```

3. **Restart Terminal**:
   - Close and reopen VS Code terminal
   - Or run: `source ~/.zshrc` (macOS/Linux)

### Android Studio / IntelliJ

1. **Preferences** → **Languages & Frameworks** → **Flutter**
2. **Flutter SDK path**: `/path/to/project/.fvm/flutter_sdk`
3. **Apply** → **OK**

### Terminal Alias (Optional)

Add to `~/.zshrc` or `~/.bashrc`:

```bash
alias fl="fvm flutter"
alias fld="fvm flutter doctor"
alias flr="fvm flutter run"
alias flb="fvm flutter build"
```

Then use:
```bash
fl run          # instead of fvm flutter run
fl pub get      # instead of fvm flutter pub get
```

## 📦 Testing Your Package

### 1. Run Example App

```bash
cd flutter_dev_panel
fvm flutter run -d chrome  # Web
fvm flutter run -d iPhone  # iOS Simulator
fvm flutter run            # Connected device
```

### 2. Run Tests

```bash
fvm flutter test
```

### 3. Analyze Code

```bash
fvm flutter analyze
```

### 4. Format Code

```bash
fvm flutter format .
```

## 🧪 Creating Test Projects

When creating test projects to use your package:

### Method 1: Same FVM Version

```bash
cd ~/Desktop
flutter create test_app
cd test_app

# Use same Flutter version
fvm use 3.38.5

# Add your package
# Edit pubspec.yaml to add:
# flutter_dev_panel:
#   path: /path/to/flutter_dev_panel

fvm flutter pub get
fvm flutter run
```

### Method 2: Use Script

Use the provided test script:

```bash
cd /Users/shivamchoudhary/Downloads/research
./create_test_project.sh
```

Then:
```bash
cd ~/Desktop/devpanel_test_app
fvm use 3.38.5
fvm flutter run
```

## 🔄 Updating Flutter Version

To update to newer Flutter versions in the future:

```bash
# Check for new releases
fvm releases

# Install latest stable
fvm install stable

# Or install specific version
fvm install 3.40.0

# Switch to new version
fvm use 3.40.0

# Update dependencies
fvm flutter pub get

# Test everything works
fvm flutter analyze
fvm flutter test
```

## ⚠️ Common Issues & Solutions

### Issue 1: "fvm: command not found"

**Solution:**
```bash
# Install FVM
dart pub global activate fvm

# Or via Homebrew
brew tap leoafarias/fvm
brew install fvm
```

### Issue 2: "Flutter SDK not found"

**Solution:**
```bash
# Reinstall the Flutter version
fvm install 3.38.5 --force

# Use it for the project
fvm use 3.38.5 --force
```

### Issue 3: VS Code not recognizing FVM

**Solution:**
1. Restart VS Code completely (Cmd+Q, then reopen)
2. Kill terminal: Cmd+Shift+P → "Terminal: Kill All Terminals"
3. Open new terminal
4. Verify: `which flutter` should point to `.fvm/flutter_sdk/bin/flutter`

### Issue 4: Different team members have different versions

**Solution:**
- Commit `.fvmrc` to git (already done)
- Team members run: `fvm use` (it reads from .fvmrc)
- Everyone gets the same version automatically

### Issue 5: CI/CD Pipeline

For GitHub Actions:

```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.38.5'
```

Or use FVM in CI:

```yaml
- name: Install FVM
  run: dart pub global activate fvm

- name: Setup Flutter with FVM
  run: |
    fvm install
    fvm flutter pub get
```

## 📊 Version Comparison

| Aspect | Old (3.27.1) | New (3.38.5) | Benefit |
|--------|-------------|--------------|---------|
| Dart Version | 3.6.0 | 3.10.4 | Newer language features |
| Release Date | Dec 2024 | Dec 2025 | Latest stable |
| DevTools | 2.40.2 | 2.51.1 | Better debugging |
| Performance | Good | Better | Optimizations |
| Bug Fixes | - | 11 releases | Many fixes |

## 🎯 Benefits of Using FVM

1. **Version Consistency**: Everyone on your team uses the same Flutter version
2. **Easy Switching**: Test your package with different Flutter versions
3. **No Global Conflicts**: Multiple projects can use different Flutter versions
4. **Reproducible Builds**: CI/CD uses exact same version as local
5. **Quick Updates**: Update Flutter without affecting other projects

## 📝 Team Workflow

### For New Team Members

```bash
# 1. Clone the repo
git clone https://github.com/Shivam-dev925/flutter_dev_panel
cd flutter_dev_panel

# 2. Install FVM if not already installed
dart pub global activate fvm

# 3. Install the project's Flutter version
fvm install

# 4. Get dependencies
fvm flutter pub get

# 5. You're ready!
fvm flutter run
```

### For Existing Projects

```bash
# Switch to project directory
cd flutter_dev_panel

# FVM automatically uses the version in .fvmrc
fvm flutter run
```

## 🔍 Verification

Verify your setup is correct:

```bash
# Check FVM is using correct version
fvm flutter --version
# Should show: Flutter 3.38.5

# Check Dart version
fvm dart --version
# Should show: Dart 3.10.4

# Check path (in project directory)
which flutter
# Should show: /path/to/project/.fvm/flutter_sdk/bin/flutter
```

## 📚 Resources

- [FVM Documentation](https://fvm.app/)
- [FVM GitHub](https://github.com/leoafarias/fvm)
- [Flutter Releases](https://docs.flutter.dev/release/archive)
- [Dart SDK Changelog](https://dart.dev/releases)

---

## ✅ Quick Checklist

- [x] Flutter 3.38.5 installed via FVM
- [x] Project configured to use FVM (.fvmrc created)
- [x] .gitignore updated (already had .fvm entries)
- [x] pubspec.yaml SDK constraints updated
- [x] Dependencies updated
- [x] Code analysis passes
- [x] Example app configured

---

**You're all set! 🎉**

Use `fvm flutter` instead of `flutter` for all commands in this project.
