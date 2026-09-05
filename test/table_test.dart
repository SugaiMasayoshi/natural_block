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
  List<List<BlockAlign?>> aligns(TableNode table) => [
    for (final row in table.children) [for (final c in row.children) c.align],
  ];

  /// The alignment each cell is *drawn* with -- the resolution a consumer
  /// performs, squared off to the table's width. This is the whole of what
  /// column inheritance means; the tree itself never stamps it onto a cell.
  List<List<BlockAlign?>> effective(TableNode table) => [
    for (final row in table.children)
      [
        for (var i = 0; i < table.columns.length; i++)
          (i < row.children.length ? row.children[i].align : null) ??
              table.columns[i],
      ],
  ];

  TableNode onlyTable(String source) =>
      NaturalBlockParser.parse(source).children.single as TableNode;

  group('declaring a table', () {
    test('`~` turns a run of rows into one TableNode', () {
      expect(
        NaturalBlockParser.parse('~A^B|C^D~'),
        DocumentNode(
          children: [
            TableNode(
              children: [
                RowNode(children: [cell('A'), cell('B')]),
                RowNode(children: [cell('C'), cell('D')]),
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

    test('`~` ends a cell as readily as a block, being the level above', () {
      // `^` separates cells, `|` separates rows, `~` separates tables. Each
      // ends everything below it, so a `~` written mid-row closes the cell,
      // closes the row, and opens the table.
      final document = NaturalBlockParser.parse('A^~B~');

      expect(document.children.first, RowNode(children: [cell('A'), empty()]));
      expect(document.children[1], isA<TableNode>());
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
      final document = NaturalBlockParser.parse('~A^B|C^D~E^F');

      expect(document.children, hasLength(2));
      expect((document.children[0] as TableNode).children, hasLength(2));
      expect(document.children[1], isA<RowNode>());
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
      expect(table.children[1], RowNode(children: [cell('paragraph')]));
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
      final document = NaturalBlockParser.parse('~A^B~note~C^D~');

      expect(document.children[0], isA<TableNode>());
      expect(document.children[1], block('note'));
      expect(document.children[2], isA<TableNode>());
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
      expect(
        NaturalBlockParser.parse('~~~A^B~').children.single,
        isA<TableNode>(),
      );
    });

    test('contradictory alignment markers keep the last one', () {
      final table = onlyTable('~<=>A^B~');

      expect(table.align, BlockAlign.end);
    });
  });

  group('alignment', () {
    test('the alignment that opens a table belongs to the table, not to its '
        'first cell', () {
      // `~=` is a centered table, and the separator that declares it is the
      // same one that opens the first cell -- so the marker has to go to one
      // or the other. It goes to the table. Letting it reach the cell would
      // be worse than a one-off mistake: the first row fixes every column's
      // alignment, so a leaked `^` would center that whole column in every
      // row that follows.
      final table = onlyTable('~=A^B|C^D~');

      expect(table.align, BlockAlign.center);
      expect(aligns(table), [
        [null, null],
        [null, null],
      ]);
    });

    test('a marker in the opening cluster aligns the table itself', () {
      // `~=` reads as one cluster describing one block: `~` says it is a
      // table, `^` says how it sits. Meaningful because a table is sized to
      // its content, so there is room around it to be positioned within.
      expect(onlyTable('~=A^B~').align, BlockAlign.center);
      expect(onlyTable('~>A^B~').align, BlockAlign.end);
      expect(onlyTable('~A^B~').align, isNull);
    });

    test('a later row inherits each column from the first row', () {
      // The point of inheriting by column: writing `^>` on every row of a
      // numeric column is repetition that carries no information.
      final table = onlyTable('~A^>B|C^D|E^F~');

      expect(table.columns, [null, BlockAlign.end]);
      expect(effective(table), [
        [null, BlockAlign.end],
        [null, BlockAlign.end],
        [null, BlockAlign.end],
      ]);
    });

    test('inheriting is not stamping: only the cell that wrote a marker '
        'carries one', () {
      // The distinction `align` being nullable exists to keep. Rows 2 and 3
      // stated nothing, and the tree says so; what they are drawn with is a
      // separate question, answered against `columns`.
      expect(aligns(onlyTable('~A^>B|C^D|E^F~')), [
        [null, BlockAlign.end],
        [null, null],
        [null, null],
      ]);
    });

    test('a cell with its own marker overrides what it would inherit', () {
      expect(effective(onlyTable('~A^>B|C^<D~')), [
        [null, BlockAlign.end],
        [null, BlockAlign.start],
      ]);
    });

    test('an overriding cell does not change the column for later rows', () {
      // The override is local to that cell: inheritance keeps coming from
      // the column, not from whatever the previous row happened to say.
      final table = onlyTable('~A^>B|C^<D|E^F~');

      expect(table.columns, [null, BlockAlign.end]);
      expect(effective(table), [
        [null, BlockAlign.end],
        [null, BlockAlign.start],
        [null, BlockAlign.end],
      ]);
    });

    test('a leading `|` opens the first cell so it can carry a marker', () {
      // Why the README writes every row with a leading `|`. The first cell
      // of the first row would otherwise be opened by the `~` that declares
      // the table, whose markers describe the table -- so the cell has no
      // marker slot of its own. Writing `|` opens an empty block (which
      // vanishes) and gives that cell its slot back, uniformly on every row.
      expect(effective(onlyTable('~|<A^>B|C^D~')), [
        [BlockAlign.start, BlockAlign.end],
        [BlockAlign.start, BlockAlign.end],
      ]);
      expect(effective(onlyTable('~|>A^B|C^D~')), [
        [BlockAlign.end, null],
        [BlockAlign.end, null],
      ]);
    });

    test('closing a table aligns the block that follows, not the table', () {
      final document = NaturalBlockParser.parse('~A^B~=after');

      expect((document.children[0] as TableNode).align, isNull);
      expect((document.children[1] as ColumnNode).align, BlockAlign.center);
    });
  });

  group('cells keep their existing behaviour inside a table', () {
    test('an empty cell still holds its position', () {
      final table = onlyTable('~A^^C|D^^F~');

      expect(table.children.first.children, hasLength(3));
      expect(table.children.first.children[1], ColumnNode(children: []));
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
