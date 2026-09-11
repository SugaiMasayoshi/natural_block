// 【解説】[テスト5/21] 表(~)。宣言して初めて表になる、という設計の固定。
// 【解説】
// 【解説】 「行が連続していたら自動で表」にしなかった理由が2つ目の group に
// 【解説】 出てくる。左^^右 は「幅を等分する普通の行」に依存した書き方なので、
// 【解説】 勝手に表にすると成立しなくなる。だから推論せず宣言させる。
// 【解説】
// 【解説】 ~ は3つ目のレイアウトシンボルで、| の1つ上の階層。^ がセルを、
// 【解説】 | が行とブロックを、~ が表の区間を区切る。だから表の終わりは
// 【解説】 ~ か入力の終わりだけで、間にあるものは全部その表のもの。
// 【解説】 幅の足りない行は弾かれずに空セルで埋められる。
// 【解説】
// 【解説】 最後の group は「1行だけの表」「1列だけの表」など、利用側が手で
// 【解説】 組める形。パーサからは出てこないが、レンダラは受け取りうる。
// 【解説】 次: test/semantic_color_test.dart

import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'nodes.dart';

void main() {
  /// What each cell *stated*, as a grid. Null where the source wrote no
  /// marker on that cell, whatever its column says.
  List<List<HorizontalAlign?>> aligns(TableNode table) => [
    for (final row in table.children) [for (final c in row.children) c.align],
  ];

  /// The alignment each cell is *drawn* with -- the resolution a consumer
  /// performs, squared off to the table's width. This is the whole of what
  /// column inheritance means; the tree itself never stamps it onto a cell.
  /// What a cell is drawn with: what it stated, else what its column
  /// declared. `unstated` is a value rather than a gap, so this is a
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

  group('declaring a table', () {
    test('`~` turns a run of rows into one TableNode', () {
      // A table is content, so it sits inside a block the way a verbatim
      // region does -- not beside one.
      expect(
        NaturalBlockParser.parse('~A^B|C^D~'),
        DocumentNode(
          children: [
            ColumnNode(
              children: [
                TableNode(
                  children: [
                    TableRowNode(children: [tableCell('A'), tableCell('B')]),
                    TableRowNode(children: [tableCell('C'), tableCell('D')]),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });

    test('without the marker the same rows stay separate RowNodes', () {
      // A table is declared, never inferred: `LEFT^^RIGHT` is a layout
      // idiom that depends on plain rows splitting the width evenly, so a
      // run of rows must not silently become a table.
      expect(
        NaturalBlockParser.parse('A^B|C^D|'),
        DocumentNode(
          children: [
            RowNode(children: [cell('A'), cell('B')]),
            RowNode(children: [cell('C'), cell('D')]),
          ],
        ),
      );
    });

    test('a table written after a `^` lands in that cell', () {
      // A table is content, so it goes wherever content goes -- including
      // one cell of a row. It used to end the row and stand beside it,
      // which is what made `|=` stop working at a table.
      final row = NaturalBlockParser.parse('A^~B~').children.single as RowNode;

      expect(row.children.first, cell('A'));
      expect(row.children[1].children.single, isA<TableNode>());
    });

    test('an escaped `~` is ordinary text', () {
      expect(NaturalBlockParser.parse(r'A \~ B').children, [block(r'A ~ B')]);
    });

    test('a `~` inside a verbatim region opens nothing', () {
      expect(
        NaturalBlockParser.parse('`A ~ B`').children.single,
        isA<ColumnNode>(),
      );
    });
  });

  group('where a table ends', () {
    test('a second `~` closes it, and later rows stand on their own', () {
      // The case that makes an explicit closer necessary: rows of the same
      // shape following a table, which no implicit rule could separate --
      // an empty block between them would not survive parsing.
      // What follows the closer is ordinary content again, and the `^`
      // in it makes a row -- with the table sitting in that row's first
      // cell, because a table is content and content is what cells hold.
      final row =
          NaturalBlockParser.parse('~A^B|C^D~E^F').children.single as RowNode;

      expect(row.children, hasLength(2));
      expect(
        (row.children.first.children.first as TableNode).children,
        hasLength(2),
      );
      expect(row.children.first.children.last, line('E'));
    });

    test('a row of a different width does not end it -- the table widens', () {
      // Everything between the two `~` is the table's. The rows keep exactly
      // the cells the author wrote; the table records how wide that makes
      // it, and squaring the grid off is the drawing layer's business.
      final table = onlyTable('~A^B|C^D|E^F^G~');

      expect(table.children, hasLength(3));
      expect([for (final r in table.children) r.children.length], [2, 2, 3]);
      expect(table.columns, hasLength(3), reason: 'as wide as its widest row');
    });

    test('anything that is not a row becomes a one-cell row', () {
      // The rule it replaces -- "a paragraph ends the table" -- meant a
      // table could end on something the author never wrote as an ending.
      final table = onlyTable('~A^B|paragraph|C^D~');

      expect(table.children, hasLength(3));
      expect(
        table.children[1],
        TableRowNode(children: [tableCell('paragraph')]),
      );
    });

    test('an empty block contributes nothing, here as anywhere', () {
      // Which is what lets every row be written with a leading `|`: the
      // separator that opens the first row opens an empty block first.
      expect(onlyTable('~A^B||C^D~').children, hasLength(2));
      expect(onlyTable('~\n|A^B\n|C^D\n~').children, hasLength(2));
    });

    test('the end of the document closes it', () {
      expect(onlyTable('~A^B').children, hasLength(1));
    });

    test('`~` alternates: table, prose, table', () {
      // `~` separates table regions from ordinary ones, the way `|`
      // separates blocks. Nothing else opens or closes one, so the author
      // can see from the source alone which side of a `~` they are on.
      final block = onlyBlock('~A^B~note~C^D~');

      expect(block.children[0], isA<TableNode>());
      expect(block.children[1], line('note'));
      expect(block.children[2], isA<TableNode>());
    });

    test('a table given no rows contributes no node', () {
      expect(NaturalBlockParser.parse('a~').children, [block('a')]);
      expect(NaturalBlockParser.parse('~~').children, isEmpty);
    });

    test('a run of single-cell blocks is a one-column table', () {
      // It used not to be expressible at all: a block with no `^` never
      // entered a row, so it ended the table instead.
      final table = onlyTable('~A|B|C~');

      expect(table.children, hasLength(3));
      expect([for (final r in table.children) r.children.length], [1, 1, 1]);
    });
  });

  group('degenerate markup', () {
    test('`~~` opens and closes at once, leaving table mode off', () {
      // Two separators with nothing between them, the same as `||`. The
      // table they delimit receives no rows, so it emits no node and what
      // follows is ordinary.
      expect(NaturalBlockParser.parse('~~A^B').children.single, isA<RowNode>());
      expect(onlyBlock('~~~A^B~').children.single, isA<TableNode>());
    });

    test("a backslash after `~` cancels the first cell's marker", () {
      expect(
        onlyTable(r'~\<a~').children.single.children.single,
        tableCell('<a'),
      );
    });

    test('the first cell takes one marker straight after `~`', () {
      // 【解説】 1つの位置が読む寄せは1文字だけ。区切りの側は layout_test.dart。
      expect(
        onlyTable('~<=>A^B~').children.first.children.first,
        tableCell('=>A', HorizontalAlign.start),
      );
    });
  });

  group('alignment', () {
    test('a marker straight after `~` aligns the first cell', () {
      // A table has no alignment of its own, so `~` starts the first cell
      // the way `|` starts a block. The first row declares the columns, so
      // that marker is the first column's.
      final table = onlyTable('~=A^B|C^D~');

      expect(table.columns, [HorizontalAlign.center, HorizontalAlign.unstated]);
      expect(aligns(table), [
        [HorizontalAlign.center, HorizontalAlign.unstated],
        [HorizontalAlign.unstated, HorizontalAlign.unstated],
      ]);
    });

    test('the block that holds a table is what positions it', () {
      final block = onlyBlock('|=~A^B~');

      expect(block.align, HorizontalAlign.center);
      expect(block.children.single, isA<TableNode>());
    });

    test('a later row inherits each column from the first row', () {
      // The point of inheriting by column: writing `^>` on every row of a
      // numeric column is repetition that carries no information.
      final table = onlyTable('~A^>B|C^D|E^F~');

      expect(table.columns, [HorizontalAlign.unstated, HorizontalAlign.end]);
      expect(effective(table), [
        [HorizontalAlign.unstated, HorizontalAlign.end],
        [HorizontalAlign.unstated, HorizontalAlign.end],
        [HorizontalAlign.unstated, HorizontalAlign.end],
      ]);
    });

    test('inheriting is not stamping: only the cell that wrote a marker '
        'carries one', () {
      // The distinction `align` being nullable exists to keep. Rows 2 and 3
      // stated nothing, and the tree says so; what they are drawn with is a
      // separate question, answered against `columns`.
      expect(aligns(onlyTable('~A^>B|C^D|E^F~')), [
        [HorizontalAlign.unstated, HorizontalAlign.end],
        [HorizontalAlign.unstated, HorizontalAlign.unstated],
        [HorizontalAlign.unstated, HorizontalAlign.unstated],
      ]);
    });

    test('a cell with its own marker overrides what it would inherit', () {
      expect(effective(onlyTable('~A^>B|C^<D~')), [
        [HorizontalAlign.unstated, HorizontalAlign.end],
        [HorizontalAlign.unstated, HorizontalAlign.start],
      ]);
    });

    test('an overriding cell does not change the column for later rows', () {
      // The override is local to that cell: inheritance keeps coming from
      // the column, not from whatever the previous row happened to say.
      final table = onlyTable('~A^>B|C^<D|E^F~');

      expect(table.columns, [HorizontalAlign.unstated, HorizontalAlign.end]);
      expect(effective(table), [
        [HorizontalAlign.unstated, HorizontalAlign.end],
        [HorizontalAlign.unstated, HorizontalAlign.start],
        [HorizontalAlign.unstated, HorizontalAlign.end],
      ]);
    });

    test('a `|` straight after `~` changes nothing', () {
      // It opens an empty block, which vanishes. The first cell starts right
      // after the `~` either way.
      for (final source in ['~|<A^>B|C^D~', '~<A^>B|C^D~']) {
        expect(effective(onlyTable(source)), [
          [HorizontalAlign.start, HorizontalAlign.end],
          [HorizontalAlign.start, HorizontalAlign.end],
        ]);
      }
      expect(effective(onlyTable('~|>A^B|C^D~')), [
        [HorizontalAlign.end, HorizontalAlign.unstated],
        [HorizontalAlign.end, HorizontalAlign.unstated],
      ]);
    });

    test(
      'the `~` that closes a table opens nothing, so it takes no marker',
      () {
        // Both `~` belong to the table, the way both fences belong to a
        // verbatim region. A marker describes the block its separator opens,
        // and a closing delimiter opens none -- so `=` here is just text.
        // Aligning what follows a table takes a `|`: the block goes on past
        // the table, and a marker is read only where a block begins.
        final document = NaturalBlockParser.parse('~A^B~=after');

        final pieces = (document.children.single as ColumnNode).children;
        expect(pieces[0], isA<TableNode>());
        expect(pieces[1], line('=after'));

        final aligned = NaturalBlockParser.parse('~A^B~|=after');
        expect(
          (aligned.children[1] as ColumnNode).align,
          HorizontalAlign.center,
        );
      },
    );
  });

  group('cells keep their existing behaviour inside a table', () {
    test('an empty cell still holds its position', () {
      final table = onlyTable('~A^^C|D^^F~');

      expect(table.children.first.children, hasLength(3));
      expect(table.children.first.children[1], emptyTableCell());
    });

    test('a multi-line cell stacks its lines', () {
      final table = onlyTable('~one\ntwo^B|C^D~');

      expect(table.children.first.children.first.children, [line('one\ntwo')]);
    });

    test('decoration inside a table cell is parsed as usual', () {
      final table = onlyTable('~:*bold^B|C^D~');
      final span =
          (table.children.first.children.first.children.first as TextNode)
                  .children
                  .single
              as TextSpanNode;

      expect(span.text, 'bold');
      expect(span.decoration.emphasis, isTrue);
    });
  });
}
