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
}
