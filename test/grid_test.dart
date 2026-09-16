import 'dart:io';

import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'support/grid.dart';
import 'support/show.dart';

/// What the source ends with after the pair, so a decision that looks past
/// the second character sees the end of the document.
const _end = MapEntry('E', '');

/// Every pair in one context, as `pair name -> shape of the tree`.
///
/// The pair's own characters are written `X` and `Y` wherever they survive
/// as text, so pairs that differ only in which characters they are come out
/// as the same shape.
Map<String, String> _shapes(String prefix) {
  final shapes = <String, String>{};
  for (final x in gridTokens.entries) {
    for (final y in [...gridTokens.entries, _end]) {
      final tree = NaturalBlockParser.parse('$prefix${x.value}${y.value}');
      shapes['${x.key}${y.key}'] = show(
        tree,
        shapeOnly: true,
        rewriteText: (s) => [
          for (final c in s.split(''))
            c == x.value ? 'X' : (c == y.value ? 'Y' : c),
        ].join(),
      );
    }
  }
  return shapes;
}

/// The shapes grouped by the shape itself, in the order the pairs were tried.
String _groups(Map<String, String> shapes) {
  final groups = <String, List<String>>{};
  for (final MapEntry(key: pair, value: shape) in shapes.entries) {
    groups.putIfAbsent(shape, () => []).add(pair);
  }
  return [
    for (final MapEntry(key: shape, value: pairs) in groups.entries)
      '$shape\n    ${pairs.join('  ')}',
  ].join('\n');
}

void main() {
  for (final MapEntry(key: name, value: prefix) in gridContexts.entries) {
    test('grid: $name', () {
      final actual =
          '# prefix: "${prefix.replaceAll('\n', r'\n')}"\n'
          '${_groups(_shapes(prefix))}';
      final file = File('test/grid/$name.txt');

      if (Platform.environment['UPDATE_GRID'] == '1') {
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('$actual\n');
        return;
      }

      // A checkout can hand the file back with CRLF, which says nothing
      // about any tree.
      expect(
        file.readAsStringSync().replaceAll('\r\n', '\n').trimRight(),
        actual,
        reason:
            'a pair parses differently than it used to. If intended, read '
            'the diff, then regenerate with UPDATE_GRID=1.',
      );
    });
  }
}
