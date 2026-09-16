import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'support/show.dart';

/// One claim per line: the source, and the tree `show()` renders it as.
///
/// `Table[cell / cell; cell / cell]` is the table, rows split by `;` and
/// cells by `/`. A cell's own alignment marker is written before its
/// brackets (`<["A"]`).
void _table(String name, Map<String, String> cases) {
  group(name, () {
    cases.forEach((source, expected) {
      test(source.replaceAll('\n', r'\n'), () {
        expect(show(NaturalBlockParser.parse(source)), expected);
      });
    });
  });
}

/// The document's only table. A table is content, so it always sits inside
/// a block.
TableNode onlyTable(String source) =>
    (NaturalBlockParser.parse(source).children.single as ColumnNode).children
        .whereType<TableNode>()
        .single;

void main() {
  // A table is declared, never inferred: `LEFT^^RIGHT` is a layout idiom
  // that depends on plain rows splitting the width evenly, so a run of rows
  // must not silently become one.
  _table('declaring a table', {
    '~A^B|C^D~': 'Col[Table[["A"] / ["B"]; ["C"] / ["D"]]]',
    'A^B|C^D|': 'Row[Col["A"], Col["B"]], Row[Col["C"], Col["D"]]',
    // A table is content, so it goes wherever content goes -- including one
    // cell of a row. It used to end the row and stand beside it, which is
    // what made `|=` stop working at a table.
    'A^~B~': 'Row[Col["A"], Col[Table[["B"]]]]',
    '`A ~ B`': 'Col[Raw"A ~ B"]',
  });

  // Everything between the two `~` is the table's, so no implicit rule has
  // to guess where it ends -- the case that makes an explicit closer
  // necessary is rows of the same shape following a table.
  _table('where a table ends', {
    '~A^B|C^D~E^F':
        'Row[Col[Table[["A"] / ["B"]; ["C"] / ["D"]], "E"], Col["F"]]',
    // The rule it replaces -- "a paragraph ends the table" -- meant a table
    // could end on something the author never wrote as an ending.
    '~A^B|paragraph|C^D~':
        'Col[Table[["A"] / ["B"]; ["paragraph"]; ["C"] / ["D"]]]',
    // An empty block contributes nothing here as anywhere, which is what
    // lets every row be written with a leading `|`.
    '~A^B||C^D~': 'Col[Table[["A"] / ["B"]; ["C"] / ["D"]]]',
    '~\n|A^B\n|C^D\n~': 'Col[Table[["A"] / ["B"]; ["C"] / ["D"]]]',
    '~A^B': 'Col[Table[["A"] / ["B"]]]',
    // `~` separates table regions from ordinary ones the way `|` separates
    // blocks, so the author can see from the source which side they are on.
    '~A^B~note~C^D~': 'Col[Table[["A"] / ["B"]], "note", Table[["C"] / ["D"]]]',
    // It used not to be expressible at all: a block with no `^` never
    // entered a row, so it ended the table instead.
    '~A|B|C~': 'Col[Table[["A"]; ["B"]; ["C"]]]',
    // Two separators with nothing between them, the same as `||`: the table
    // receives no rows, emits no node, and what follows is ordinary.
    '~~A^B': 'Row[Col["A"], Col["B"]]',
    '~~~A^B~': 'Col[Table[["A"] / ["B"]]]',
  });

  // A table has no alignment of its own, so `~` starts the first cell the
  // way `|` starts a block, and the block holding the table is what
  // positions it.
  _table('alignment', {
    '~<=>A^B~': 'Col[Table[<["=>A"] / ["B"]]]',
    '|=~A^B~': 'Col=[Table[["A"] / ["B"]]]',
    // A marker describes the block its separator opens, and a closing
    // delimiter opens none -- so `=` after the table is just text. Aligning
    // what follows takes a `|`.
    '~A^B~=after': 'Col[Table[["A"] / ["B"]], "=after"]',
    '~A^B~|=after': 'Col[Table[["A"] / ["B"]]], Col=["after"]',
  });

  // Cells keep the behaviour they have outside a table.
  _table('cells', {
    '~A^^C|D^^F~': 'Col[Table[["A"] / [] / ["C"]; ["D"] / [] / ["F"]]]',
    '~one\ntwo^B|C^D~': r'Col[Table[["one\ntwo"] / ["B"]; ["C"] / ["D"]]]',
    '~:*bold^B|C^D~': 'Col[Table[["bold"{*}] / ["B"]; ["C"] / ["D"]]]',
  });

  group('columns', () {
    /// What each cell *stated*. `show()` renders this, but the claims below
    /// are about what it means for the cells that stated nothing.
    List<List<HorizontalAlign>> aligns(TableNode table) => [
      for (final row in table.children) [for (final c in row.children) c.align],
    ];

    /// The alignment each cell is *drawn* with -- the resolution a consumer
    /// performs, squared off to the table's width. This is the whole of what
    /// column inheritance means; the tree itself never stamps it onto a
    /// cell. `unstated` is a value rather than a gap, so this is a
    /// comparison rather than a `??`.
    HorizontalAlign resolve(TableRowNode row, TableNode table, int i) {
      if (i >= row.children.length) return table.columns[i];
      final stated = row.children[i].align;
      return stated == HorizontalAlign.unstated ? table.columns[i] : stated;
    }

    List<List<HorizontalAlign>> effective(TableNode table) => [
      for (final row in table.children)
        [for (var i = 0; i < table.columns.length; i++) resolve(row, table, i)],
    ];

    const unstated = HorizontalAlign.unstated;
    const start = HorizontalAlign.start;
    const center = HorizontalAlign.center;
    const end = HorizontalAlign.end;

    test('the rows keep what they wrote; the table records how wide it is', () {
      // A row of a different width does not end the table -- it widens it.
      // Squaring the grid off is the drawing layer's business.
      final table = onlyTable('~A^B|C^D|E^F^G~');

      expect([for (final r in table.children) r.children.length], [2, 2, 3]);
      expect(table.columns, hasLength(3), reason: 'as wide as its widest row');
    });

    test('the first row declares the columns', () {
      final table = onlyTable('~=A^B|C^D~');

      expect(table.columns, [center, unstated]);
      expect(aligns(table), [
        [center, unstated],
        [unstated, unstated],
      ]);
    });

    test('a later row inherits each column from the first row', () {
      // The point of inheriting by column: writing `^>` on every row of a
      // numeric column is repetition that carries no information.
      final table = onlyTable('~A^>B|C^D|E^F~');

      expect(table.columns, [unstated, end]);
      expect(effective(table), [
        [unstated, end],
        [unstated, end],
        [unstated, end],
      ]);
    });

    test('inheriting is not stamping: only the cell that wrote a marker '
        'carries one', () {
      // The distinction `unstated` being a value exists to keep. Rows 2 and
      // 3 stated nothing, and the tree says so; what they are drawn with is
      // a separate question, answered against `columns`.
      expect(aligns(onlyTable('~A^>B|C^D|E^F~')), [
        [unstated, end],
        [unstated, unstated],
        [unstated, unstated],
      ]);
    });

    test('a cell overrides what it would inherit, for itself only', () {
      // The override is local: inheritance keeps coming from the column, not
      // from whatever the previous row happened to say.
      final table = onlyTable('~A^>B|C^<D|E^F~');

      expect(table.columns, [unstated, end]);
      expect(effective(table), [
        [unstated, end],
        [unstated, start],
        [unstated, end],
      ]);
    });

    test('a `|` straight after `~` changes nothing', () {
      // It opens an empty block, which vanishes. The first cell starts right
      // after the `~` either way.
      for (final source in ['~|<A^>B|C^D~', '~<A^>B|C^D~']) {
        expect(effective(onlyTable(source)), [
          [start, end],
          [start, end],
        ], reason: source);
      }
    });
  });
}
