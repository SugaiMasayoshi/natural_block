import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'support/show.dart';

/// One claim per line: the source, and the tree `show()` renders it as.
///
/// `Col[...]` is a block, `Row[...]` a row of cells, and a stated alignment
/// is written on the node it belongs to (`Col<`, `Col=`, `Col>`).
void _table(String name, Map<String, String> cases) {
  group(name, () {
    cases.forEach((source, expected) {
      test(source.replaceAll('\n', r'\n'), () {
        expect(show(NaturalBlockParser.parse(source)), expected);
      });
    });
  });
}

void main() {
  // A block drops one blank line at each end, which is what lets a block's
  // symbol sit on a line of its own. However the `|` are written around it,
  // the block itself is the same.
  _table('a block drops its own blank line at each end', {
    '本文': 'Col["本文"]',
    '|本文|': 'Col["本文"]',
    '|\n本文\n|': 'Col["本文"]',
    '\n|本文|\n': 'Col["本文"]',
    '左^右': 'Row[Col["左"], Col["右"]]',
    '||\n左^右\n||': 'Row[Col["左"], Col["右"]]',
    '|\n|左^右|\n|': 'Row[Col["左"], Col["右"]]',
  });

  // A cell is a position, not just content: the cells around it are laid out
  // relative to it, so a blank one has to survive -- that is what makes a
  // deliberately empty middle cell expressible. A block is content, so an
  // empty one contributes no node at all. The two halves of the same rule.
  _table('an empty cell is a position, an empty block is nothing', {
    '左^^右': 'Row[Col["左"], Col[], Col["右"]]',
    '左||右': 'Col["左"], Col["右"]',
  });

  // This used to be an exception: a separator at the very end opened
  // nothing, so a row meant one thing at the end of a document and another
  // with a character after it -- which a reader watched happen live as they
  // typed past it, the layout jumping on the next keystroke. The general
  // rules already covered it: an empty cell is a position the layout keeps.
  _table('a trailing separator opens a cell, wherever the row ends', {
    '左^右^': 'Row[Col["左"], Col["右"], Col[]]',
    '左^右^|c': 'Row[Col["左"], Col["右"], Col[]], Col["c"]',
    '左^右^|': 'Row[Col["左"], Col["右"], Col[]]',
    '^左^右^': 'Row[Col[], Col["左"], Col["右"], Col[]]',
    '~左^右^~': 'Col[Table[["左"] / ["右"] / []]]',
    // An escaped one is text, and the block it lands in is still emitted.
    r'左^右\^': 'Row[Col["左"], Col["右^"]]',
  });

  test('a trailing `^` does not change a table\'s declared width', () {
    // It reaches further inside a table: the width comes from the widest
    // row, so a row that changed width with the document's end would change
    // how every other row is squared off for drawing.
    for (final source in ['~左^右^', '~左^右^~']) {
      final block = NaturalBlockParser.parse(source).children.single;
      final table = (block as ColumnNode).children.single as TableNode;

      expect(table.columns, hasLength(3), reason: source);
    }
  });

  // A row's boundaries are written, not inferred from what sits next to it.
  // A `|` ends the block before it -- reading it as "a new block starts
  // here" agrees everywhere but one place: the leading `|` of a row is the
  // full stop on whatever came before, and `^` cannot stand in for it.
  _table('rows end where a `|` says they do', {
    'a^b|c^d': 'Row[Col["a"], Col["b"]], Row[Col["c"], Col["d"]]',
    'a^b|text': 'Row[Col["a"], Col["b"]], Col["text"]',
    'text|a^b': 'Col["text"], Row[Col["a"], Col["b"]]',
    // A newline is a character, not a boundary, so a multi-line cell keeps
    // its lines in one block.
    '左1\n左2^右': r'Row[Col["左1\n左2"], Col["右"]]',
  });

  // A marker is read only where a block begins, and it describes the block
  // its separator opens. Saying nothing is not the same as saying `<`: a
  // theme may centre unaligned blocks, and a block that wrote `<` opts out
  // of that -- which is why `unstated` is a value of its own.
  _table('alignment', {
    '|<A^>B|': 'Row[Col<["A"], Col>["B"]]',
    '|=見出し|': 'Col=["見出し"]',
    '|>右寄せ|': 'Col>["右寄せ"]',
    // The first block of a document has no separator but is still a
    // beginning, so it reads a marker too.
    '<a': 'Col<["a"]',
    '=>': 'Col=[">"]',
    // Only one marker is read, so the second is ordinary text. `|<>` says
    // the same thing twice; a decoration cluster reads a run because its
    // characters say different things.
    '|<>a': 'Col<[">a"]',
    // A `^` opens a new cell rather than continuing the markers.
    '|<^>a': 'Row[Col<[], Col>["a"]]',
    'a > b': 'Col["a > b"]',
    '|>:!赤い数字|': 'Col>["赤い数字"{negative}]',
  });

  // A backslash cancels a marker only where one would be read. Mid-sentence
  // a `<` is not markup, so the backslash stays in the text.
  _table('escaping a marker', {
    r'\<a': 'Col["<a"]',
    r'x|\=>': 'Col["x"], Col["=>"]',
    r'a^\>b': 'Row[Col["a"], Col[">b"]]',
    r'a\<b': r'Col["a\\<b"]',
    r'\\<a': r'Col["\\<a"]',
    r'x \^> y': 'Col["x ^> y"]',
  });

  // A marker cannot materialize an empty block, because there is nothing
  // inside to align. `a|>|b` used to give three nodes where `a||b` gave
  // two, contradicting the stated rule.
  _table('a marker does not make an empty block appear', {
    'a||b': 'Col["a"], Col["b"]',
    'a|<|b': 'Col["a"], Col["b"]',
    'a|=|b': 'Col["a"], Col["b"]',
    'a|>|b': 'Col["a"], Col["b"]',
  });
}
