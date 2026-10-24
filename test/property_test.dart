import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'support/grid.dart';

Iterable<String> _strings(List<String> alphabet, int maxLength) sync* {
  var previous = [''];
  for (var length = 1; length <= maxLength; length++) {
    final current = <String>[];
    for (final head in previous) {
      for (final c in alphabet) {
        current.add('$head$c');
      }
    }
    yield* current;
    previous = current;
  }
}

void main() {
  final sources = _strings(gridTokens.values.toList(), 5).toList();

  // Longer than the grid reaches. A loop that stops advancing, or a node
  // built in a shape its constructor rejects, trips an assert and fails here.
  test('${sources.length} sources parse without throwing', () {
    for (final source in sources) {
      expect(
        () => NaturalBlockParser.parse(source),
        returnsNormally,
        reason: source,
      );
    }
  });

  test('a line break written as CRLF or CR parses as LF', () {
    for (final source in sources.where((s) => s.contains('\n'))) {
      final expected = NaturalBlockParser.parse(source);
      for (final lineBreak in ['\r\n', '\r']) {
        expect(
          NaturalBlockParser.parse(source.replaceAll('\n', lineBreak)),
          expected,
          reason: source,
        );
      }
    }
  });

  // Every character that could be markup, escaped, leaves one plain run of
  // exactly the text. Line breaks are left out: they cannot be escaped.
  test('escaping every symbol gives back exactly the text', () {
    final symbols = gridTokens.values.where((c) => c != '\n').toList();
    for (final source in _strings(symbols, 5)) {
      final escaped = StringBuffer();
      for (var i = 0; i < source.length; i++) {
        final char = source[i];
        final live =
            {'|', '^', '~', '`', ':', r'\'}.contains(char) ||
            (i == 0 && char == '<');
        escaped.write(live ? '\\$char' : char);
      }

      expect(
        NaturalBlockParser.parse(escaped.toString()),
        DocumentNode(
          children: [
            ColumnNode(
              children: [
                TextNode(children: [TextSpanNode(text: source)]),
              ],
            ),
          ],
        ),
        reason: escaped.toString(),
      );
    }
  });
}
