/// Packages that are legitimately declared in pubspec.yaml without ever
/// being imported in Dart source — e.g. asset/font-only packages, or
/// code-generation tools invoked via the command line rather than an API.
/// Excluded from [DependencyHygieneAudit]'s unused-dependency check to
/// avoid false positives.
const Set<String> unusedDependencyIgnoreList = {
  // Bundles the CupertinoIcons font; used via Flutter's own CupertinoIcons
  // class, never imported directly.
  'cupertino_icons',
  // Icon/splash generators invoked via `dart run`, not imported by app code.
  'flutter_launcher_icons',
  'flutter_native_splash',
};
