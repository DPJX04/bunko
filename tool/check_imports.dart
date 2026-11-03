// Boundary check: fails when a file in lib/ imports a layer it must not use.
//
// Run before each commit:  dart run tool/check_imports.dart
// The layer table is _allowedLayers below. Arrows only point down.
import 'dart:io';

const _appPackage = 'light_novel_downloader';

/// Which app layers each layer may import. Files in the same layer may
/// always import each other, except one feature importing another.
const _allowedLayers = <String, Set<String>>{
  'root': {
    'features',
    'widgets',
    'state',
    'repositories',
    'services',
    'utils',
    'models',
    'config',
    'routing',
    'l10n',
  },
  'routing': {
    'features',
    'widgets',
    'state',
    'utils',
    'models',
    'config',
    'l10n',
  },
  'features': {
    'state',
    'repositories',
    'widgets',
    'utils',
    'models',
    'config',
    'l10n',
  },
  'widgets': {'state', 'utils', 'models', 'l10n'},
  'state': {'repositories', 'utils', 'models'},
  'repositories': {'services', 'utils', 'models', 'config'},
  'services': {'utils', 'models', 'config'},
  'utils': {'models'},
  'models': {},
  'config': {},
  // The app's words: the ARB files, the code gen-l10n writes from them,
  // and l10n.dart, which turns error sentences into the picked language.
  'l10n': {'utils'},
};

/// Outside packages that only some layers may import.
const _restrictedPackages = <String, Set<String>>{
  'bili_novel_packer': {'repositories', 'services'},
  'dio': {'repositories', 'services', 'utils'},
};

/// One import line that breaks a rule.
class _Violation {
  const _Violation(this.file, this.line, this.target, this.reason);

  final String file;
  final int line;
  final String target;
  final String reason;

  @override
  String toString() => '$file:$line imports $target\n    $reason';
}

void main() {
  final violations = <_Violation>[];
  for (final file in _dartFilesIn('lib')) {
    violations.addAll(_checkFile(file));
  }
  if (violations.isEmpty) {
    stdout.writeln('check_imports: no violations.');
    return;
  }
  violations.forEach(stderr.writeln);
  stderr.writeln('check_imports: ${violations.length} violation(s).');
  exit(1);
}

/// Lists every .dart file under [folder], as paths relative to the project.
List<String> _dartFilesIn(String folder) {
  return Directory(folder)
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.replaceAll(r'\', '/'))
      .where((path) => path.endsWith('.dart'))
      .toList()
    ..sort();
}

/// Checks every import and export line of one file.
List<_Violation> _checkFile(String path) {
  final directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');
  final lines = File(path).readAsLinesSync();
  final violations = <_Violation>[];
  for (var i = 0; i < lines.length; i++) {
    final match = directive.firstMatch(lines[i]);
    if (match == null) continue;
    final reason = _ruleBroken(path, match.group(1)!);
    if (reason != null) {
      violations.add(_Violation(path, i + 1, match.group(1)!, reason));
    }
  }
  return violations;
}

/// Returns why importing [uri] from [fromPath] is not allowed, or null if it is.
String? _ruleBroken(String fromPath, String uri) {
  if (uri.startsWith('dart:')) return null;
  final fromLayer = _layerOf(fromPath);
  if (!_allowedLayers.containsKey(fromLayer)) {
    return 'lib/$fromLayer/ is not a layer folder. See _allowedLayers in '
        'tool/check_imports.dart.';
  }
  if (uri.startsWith('package:') && !uri.startsWith('package:$_appPackage/')) {
    return _packageRuleBroken(fromLayer, uri);
  }
  final toPath = _resolve(fromPath, uri);
  return _layerRuleBroken(fromPath, fromLayer, toPath);
}

/// Checks an import of an outside package against [_restrictedPackages].
String? _packageRuleBroken(String fromLayer, String uri) {
  final package = uri.substring('package:'.length).split('/').first;
  final allowed = _restrictedPackages[package];
  if (allowed == null || allowed.contains(fromLayer)) return null;
  return '$fromLayer/ must not import package:$package (only ${allowed.join(', ')}).';
}

/// Checks an import of another app file against [_allowedLayers].
String? _layerRuleBroken(String fromPath, String fromLayer, String toPath) {
  final toLayer = _layerOf(toPath);
  if (toLayer == 'root' && fromLayer != 'root') {
    return 'only main.dart may import app.dart; nothing imports main.dart.';
  }
  if (toLayer == 'features') return _featureRuleBroken(fromPath, toPath);
  if (fromLayer == toLayer) return null;
  if (_allowedLayers[fromLayer]!.contains(toLayer)) return null;
  return '$fromLayer/ must not import $toLayer/ (arrows only point down).';
}

/// Checks an import that points into a feature folder.
String? _featureRuleBroken(String fromPath, String toPath) {
  final fromFeature = _featureOf(fromPath);
  final toFeature = _featureOf(toPath)!;
  if (fromFeature == toFeature) return null;
  if (fromFeature != null) {
    return 'features never import each other ($fromFeature -> $toFeature).';
  }
  final fromLayer = _layerOf(fromPath);
  if (fromLayer != 'root' && fromLayer != 'routing') {
    return '$fromLayer/ must not import a feature.';
  }
  final door = 'lib/features/$toFeature/$toFeature.dart';
  return toPath == door ? null : 'import the feature through its door, $door.';
}

/// Names the layer a lib/ path belongs to, such as 'services' or 'root'.
String _layerOf(String path) {
  final parts = path.split('/');
  return parts.length <= 2 ? 'root' : parts[1];
}

/// Names the feature a path belongs to, or null if it is not in a feature.
String? _featureOf(String path) {
  final parts = path.split('/');
  final isFeature = parts.length > 3 && parts[1] == 'features';
  return isFeature ? parts[2] : null;
}

/// Turns an import URI into a project path such as lib/models/result.dart.
String _resolve(String fromPath, String uri) {
  if (uri.startsWith('package:$_appPackage/')) {
    return 'lib/${uri.substring('package:$_appPackage/'.length)}';
  }
  final folder = File(fromPath).parent.uri;
  final resolved = folder.resolve(uri).toFilePath(windows: false);
  return _normalize(resolved);
}

/// Strips any leading ./ or / so relative paths match the lib/ form.
String _normalize(String path) {
  final index = path.indexOf('lib/');
  return index < 0 ? path : path.substring(index);
}
