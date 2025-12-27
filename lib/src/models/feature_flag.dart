/// A feature flag that can be toggled
class FeatureFlag {
  final String key;
  final String name;
  final String? description;
  bool isEnabled;

  FeatureFlag({
    required this.key,
    required this.name,
    this.description,
    this.isEnabled = false,
  });
}
