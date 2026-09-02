// 【解説】[テスト5/21] 表(|~)。宣言して初めて表になる、という設計の固定。
// 【解説】
// 【解説】 「行が連続していたら自動で表」にしなかった理由が2つ目の group に
// 【解説】 出てくる。左==右 は「幅を等分する普通の行」に依存した書き方なので、
// 【解説】 勝手に表にすると成立しなくなる。だから推論せず宣言させる。
// 【解説】
// 【解説】 暗黙終了の条件(列数が変わる/行以外が来る/入力が終わる)と、
// 【解説】 空ブロックはその条件に入らないこと。空が表を閉じると || が
// 【解説】 AST に残らない不可視の区切りになってしまう。
// 【解説】
// 【解説】 最後の group は「1行だけの表」「1列だけの表」など、利用側が手で
// 【解説】 組める形。パーサからは出てこないが、レンダラは受け取りうる。
// 【解説】 次: test/semantic_color_test.dart

import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

/// One line of text, the shape most table cells take.
TextNode line(String text) => TextNode(children: [TextSpanNode(text: text)]);

/// A single-line cell.
ColumnNode cell(String text, [BlockAlign align = BlockAlign.start]) =>
    ColumnNode(children: [line(text)], align: align);

void main() {

  /// The alignment of every cell of every row, as a grid -- the thing column
  /// inheritance is about.
  List<List<BlockAlign>> aligns(TableNode table) => [
    for (final row in table.children) [for (final c in row.children) c.align],
  ];

  TableNode onlyTable(String source) =>
      NaturalBlockParser.parse(source).children.single as TableNode;

  group('declaring a table', () {
    test('`|~` turns a run of rows into one TableNode', () {
      expect(
        NaturalBlockParser.parse('|~A=B|C=D|'),
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
      // A table is declared, never inferred: `LEFT==RIGHT` is a layout
      // idiom that depends on plain rows splitting the width evenly, so a
      // run of rows must not silently become a table.
      expect(
        NaturalBlockParser.parse('A=B|C=D|'),
        DocumentNode(
          children: [
            RowNode(children: [cell('A'), cell('B')]),
            RowNode(children: [cell('C'), cell('D')]),
          ],
        ),
      );
    });

    test('`~` after `=` is ordinary text, not a table declaration', () {
      // A table is a run of rows, so it is only declarable at a `|`. After
      // a `=` -- which separates cells within one row -- a table would mean
      // a cell that is itself a table, which the language does not express.
      final row = NaturalBlockParser.parse('A=~B|').children.single as RowNode;

      expect(row.children[1], cell('~B'));
    });

    test('an escaped separator leaves the marker as text', () {
      final row = NaturalBlockParser.parse(r'\|~A=B|').children.single as RowNode;

      expect(row.children.first, cell('|~A'));
    });
  });

  group('where a table ends', () {
    test('a second `|~` closes it, and later rows stand on their own', () {
      // The case that makes an explicit closer necessary: rows of the same
      // shape following a table, which no implicit rule could separate --
      // an empty block between them would not survive parsing.
      final document = NaturalBlockParser.parse('|~A=B|C=D|~E=F|');

      expect(document.children, hasLength(2));
      expect((document.children[0] as TableNode).children, hasLength(2));
      expect(document.children[1], isA<RowNode>());
    });

    test('a row with a different cell count ends it and stands alone', () {
      // Not merely a preference: rows of differing width have nothing to
      // line up against, and the renderer's Table requires every row to
      // hold the same number of cells.
      final document = NaturalBlockParser.parse('|~A=B|C=D|E=F=G|');

      expect((document.children[0] as TableNode).children, hasLength(2));
      expect((document.children[1] as RowNode).children, hasLength(3));
    });

    test('anything that is not a row ends it', () {
      final document = NaturalBlockParser.parse('|~A=B|paragraph|C=D|');

      expect(document.children[0], isA<TableNode>());
      expect(document.children[1], line('paragraph'));
      expect(
        document.children[2],
        isA<RowNode>(),
        reason: 'the table ended, so the later row is not part of it',
      );
    });

    test('an empty block does not end it', () {
      // An empty Column block contributes no node at all, so letting one
      // close a table would make `||` an invisible separator -- a table
      // silently split in two by something the AST does not even record.
      expect(onlyTable('|~A=B||C=D|').children, hasLength(2));
    });

    test('the end of the document closes it', () {
      expect(onlyTable('|~A=B|').children, hasLength(1));
    });

    test('after an implicit end, the next `|~` opens rather than closes', () {
      // Pinned deliberately, not a bug. `~` toggles a state the author
      // cannot see -- the same property decoration symbols already have
      // (`:!` flips danger on when it is already off). Once a paragraph has
      // implicitly ended the table, table mode is off, so the next `|~`
      // reads as an opening.
      //
      // That is the right answer for the document people actually write:
      // "table, note, table" wants the second `|~` to start a second table,
      // which is exactly what happens. What it costs is that a *redundant*
      // close -- one written after something already ended the table --
      // opens instead, and a table given no rows contributes nothing.
      //
      // Giving `~` a second state ("declared but not accumulating") would
      // fix only that redundant case and would add permanent complexity to
      // the parser for it.
      final twoTables = NaturalBlockParser.parse('|~A=B|note|~C=D|');
      expect(twoTables.children[0], isA<TableNode>());
      expect(twoTables.children[1], line('note'));
      expect(
        twoTables.children[2],
        isA<TableNode>(),
        reason: 'the second `|~` starts a second table',
      );

      // A redundant close with nothing after it is harmless: it opens a
      // table that never receives a row, which emits no node.
      final harmless = NaturalBlockParser.parse('|~A=B|note|~');
      expect(harmless.children, hasLength(2));
    });

    test('a table given no rows contributes no node', () {
      expect(NaturalBlockParser.parse('|~text').children, [line('text')]);
      expect(NaturalBlockParser.parse('a|~').children, [line('a')]);
    });

    test('a run of single-cell blocks is not a table', () {
      // A block with no `=` never enters a row, so it cannot be a one-column
      // table -- such a table is currently not expressible. Pinned so the
      // limitation is visible rather than discovered.
      final document = NaturalBlockParser.parse('|~A|B|');

      expect(document.children, [line('A'), line('B')]);
    });
  });

  group('degenerate marker clusters', () {
    test('`~` twice in one cluster cancels out', () {
      // `~` toggles, so writing it twice in the same cluster is two
      // toggles and leaves table mode off. Nothing in the language gives
      // that a meaning; pinned so the behaviour is at least defined.
      expect(NaturalBlockParser.parse('|~~A=B|').children.single, isA<RowNode>());
      expect(NaturalBlockParser.parse('|~~~A=B|').children.single, isA<TableNode>());
    });

    test('contradictory alignment markers keep the last one', () {
      final table = onlyTable('|~<^>A=B|');

      expect(table.align, BlockAlign.end);
    });
  });

  group('alignment', () {
    test('a marker in the opening cluster aligns the table itself', () {
      // `|~^` reads as one cluster describing one block: `~` says it is a
      // table, `^` says how it sits. Meaningful because a table is sized to
      // its content, so there is room around it to be positioned within.
      expect(onlyTable('|~^A=B|').align, BlockAlign.center);
      expect(onlyTable('|~>A=B|').align, BlockAlign.end);
      expect(onlyTable('|~A=B|').align, BlockAlign.start);
    });

    test('a later row inherits each column from the first row', () {
      // The point of inheriting by column: writing `=>` on every row of a
      // numeric column is repetition that carries no information.
      expect(aligns(onlyTable('|~A=>B|C=D|E=F|')), [
        [BlockAlign.start, BlockAlign.end],
        [BlockAlign.start, BlockAlign.end],
        [BlockAlign.start, BlockAlign.end],
      ]);
    });

    test('a cell with its own marker overrides what it would inherit', () {
      expect(aligns(onlyTable('|~A=>B|C=<D|')), [
        [BlockAlign.start, BlockAlign.end],
        [BlockAlign.start, BlockAlign.start],
      ]);
    });

    test('an overriding cell does not change the column for later rows', () {
      // The override is local to that cell: inheritance keeps coming from
      // the first row, not from whatever the previous row happened to say.
      expect(aligns(onlyTable('|~A=>B|C=<D|E=F|')), [
        [BlockAlign.start, BlockAlign.end],
        [BlockAlign.start, BlockAlign.start],
        [BlockAlign.start, BlockAlign.end],
      ]);
    });

    test('an extra `|` opens the first cell so it can carry a marker', () {
      // The first cell of the first row is opened by the same separator
      // that declares the table, so it has no marker slot of its own.
      // Writing the separator again opens an empty block (which vanishes)
      // and gives that cell its slot back.
      expect(aligns(onlyTable('|~|<A=>B|C=D|')), [
        [BlockAlign.start, BlockAlign.end],
        [BlockAlign.start, BlockAlign.end],
      ]);
      expect(aligns(onlyTable('|~|>A=B|C=D|')), [
        [BlockAlign.end, BlockAlign.start],
        [BlockAlign.end, BlockAlign.start],
      ]);
    });

    test('closing a table aligns the block that follows, not the table', () {
      final document = NaturalBlockParser.parse('|~A=B|~^after');

      expect((document.children[0] as TableNode).align, BlockAlign.start);
      expect((document.children[1] as ColumnNode).align, BlockAlign.center);
    });
  });

  group('cells keep their existing behaviour inside a table', () {
    test('an empty cell still holds its position', () {
      final table = onlyTable('|~A==C|D==F|');

      expect(table.children.first.children, hasLength(3));
      expect(table.children.first.children[1], ColumnNode(children: []));
    });

    test('a multi-line cell stacks its lines', () {
      final table = onlyTable('|~one\ntwo=B|C=D|');

      expect(table.children.first.children.first.children, [
        line('one'),
        line('two'),
      ]);
    });

    test('decoration inside a table cell is parsed as usual', () {
      final table = onlyTable('|~:*bold=B|C=D|');
      final span =
          table.children.first.children.first.children.first.children.single
              as TextSpanNode;

      expect(span.text, 'bold');
      expect(span.emphasis, isTrue);
    });
  });
}
