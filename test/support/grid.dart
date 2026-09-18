import 'package:natural_block/natural_block.dart';

import 'show.dart';

/// One character for each kind of thing the parser tells apart, keyed by the
/// name the grid files show it under.
///
/// The parser decides from the character it is on and the one after it, so
/// every pair of these, in every context, passes through every decision it
/// makes. `b` stands for any ordinary character, `!` for all decoration
/// characters and `<` for all alignment markers;
/// `representative_test.dart` checks that standing in is sound.
///
/// A name in capitals is one for a character that cannot be shown as itself:
/// `N` is the newline, and `E` the end of the document.
const Map<String, String> gridTokens = {
  'b': 'b',
  '|': '|',
  '^': '^',
  '~': '~',
  '`': '`',
  ':': ':',
  '!': '!',
  r'\': r'\',
  'N': '\n',
  '<': '<',
};

/// Where a pair is written, keyed by the name of its grid file.
///
/// A prefix leaves at most the letter `a` in the tree, so the placeholder
/// substitution below cannot mistake a prefix character for the pair's.
/// `after_newline` is written `|\n` rather than `a\n` for that reason: the `|`
/// ends the block before it and the newline is the one a block drops at its
/// start, so nothing of the prefix reaches the tree. `cluster_escape` is the
/// one exception -- its backslash can survive as text. A `\` in its shapes is
/// the prefix's; where the pair's first character is a backslash too, the
/// two collapse into one and it is shown as `X`.
///
/// `after_newline` is a line start past the start of its block: the pair
/// still opens a raw block there, but the alignment marker slot and the one
/// newline a block drops are both behind it. That is all that tells it apart
/// from `document`.
///
/// A prefix also puts the pair where a decision reads it as its *next*
/// character: in `cluster_escape` the cluster is sitting on the backslash, so
/// the pair's first character is what it escapes.
const Map<String, String> gridContexts = {
  'document': '',
  'text': 'a',
  'row_cell': 'a^',
  'table_cell': '~',
  'decorated': ':!a',
  'cluster': ':!',
  'cluster_escape': r':!\',
  'table_row': '~a|',
  'after_newline': '|\n',
};

/// What the source ends with after the pair, so a decision that looks past
/// the second character sees the end of the document.
const _end = MapEntry('E', '');

/// The file that pins the context named [name]: the prefix it is written
/// with, then every shape a pair comes out as, each with the pairs that
/// share it.
String gridText(String name) {
  final prefix = gridContexts[name]!;
  return '# prefix: "${prefix.replaceAll('\n', r'\n')}"\n${_groups(prefix)}';
}

/// Where that file lives, relative to the package root.
String gridPath(String name) => 'test/grid/$name.txt';

/// The shapes of one context's pairs, grouped by the shape itself, in the
/// order the pairs were tried.
String _groups(String prefix) {
  final groups = <String, List<String>>{};
  for (final MapEntry(key: pair, value: shape) in _shapes(prefix).entries) {
    groups.putIfAbsent(shape, () => []).add(pair);
  }
  return [
    for (final MapEntry(key: shape, value: pairs) in groups.entries)
      '$shape\n    ${pairs.join('  ')}',
  ].join('\n');
}

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
