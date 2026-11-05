import 'dart:io';

import 'package:test/test.dart';

import 'support/grid.dart';

void main() {
  for (final name in gridContexts.keys) {
    test('grid: $name', () {
      // A checkout can hand the file back with CRLF, which says nothing
      // about any tree.
      expect(
        gridText(name),
        File(gridPath(name))
            .readAsStringSync()
            .replaceAll('\r\n', '\n')
            .trimRight(),
        reason:
            'a pair parses differently than it used to. If intended, read '
            'the diff, then regenerate with: dart run tool/update_grid.dart',
      );
    });
  }

  test('grid: markup', () {
    expect(
      markupText(),
      File(markupPath).readAsStringSync().replaceAll('\r\n', '\n').trimRight(),
      reason:
          'the parser reads a character as markup differently than it used '
          'to. If intended, read the diff, then regenerate with: '
          'dart run tool/update_grid.dart, and copy test/grid/markup.txt to '
          'natural_block_editors',
    );
  });
}
