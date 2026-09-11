// 【解説】[テスト2/21] | と ^ の骨格。この言語で一番地味で一番重要な部分。
// 【解説】
// 【解説】 前半は改行の削り方を表駆動で総当たりしている。「塊の先頭と末尾の
// 【解説】 空行1つだけを落とす」という規則が、記号を単独行に置ける根拠。
// 【解説】
// 【解説】 後半が読みどころで、空の扱いの非対称をここで固定している。
// 【解説】 空の Column ブロックは消える(内容が無いから)が、空の Row セルは
// 【解説】 残る(位置だから)。これが 左^^右 を成立させている。
// 【解説】 末尾の区切りの扱いは "pinned current behavior" と名前に書いてあり、
// 【解説】 設計というより「今こうである」を固定しているだけだと明示している。
// 【解説】 次: test/escape_test.dart

import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'nodes.dart';

void main() {
  group("Column newline trimming", () {
    // Expected: root keeps its Column wrapper
    final expected = DocumentNode(children: [block("本文")]);

    const cases = [
      "本文",
      "|本文",
      "本文|",
      "|本文|",
      "|\n本文|",
      "|本文\n|",
      "|\n本文\n|",
      "\n|本文|",
      "|本文|\n",
      "\n|本文|\n",
    ];

    for (final (index, input) in cases.indexed) {
      test("Column newline trim pattern $index", () {
        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });
    }
  });

  group("Row newline trimming", () {
    // Expected: root Column wraps one RowNode, whose two cells are each a
    // ColumnNode wrapping one TextNode
    final expected = DocumentNode(
      children: [
        RowNode(children: [block("左"), block("右")]),
      ],
    );

    const cases = [
      "左^右",
      "|左^右",
      "|左^右|",
      "||左^右|",
      "|左^右||",
      "||左^右||",
      "||\n左^右||",
      "||左^右\n||",
      "||\n左^右\n||",
      "|\n|左^右||",
      "||左^右|\n|",
      "|\n|左^右|\n|",
    ];

    for (final (index, input) in cases.indexed) {
      test("Row newline trim pattern $index", () {
        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });
    }
  });

  group("Boundary and special cases", () {
    test("empty blocks are ignored / handled safely", () {
      const input = "|||";
      final nodes = NaturalBlockParser.parse(input);
      expect(nodes.children.isEmpty, isTrue);
    });

    // A Row cell is a position, not just content: the cells around it are
    // laid out relative to it, so a blank one has to survive. This is what
    // makes a deliberately empty middle cell expressible at all -- without
    // it, "左^^右" and "左^右" would parse identically.
    test("an empty Row cell between two filled ones is kept as a position", () {
      const input = "左^^右";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              block("左"),
              ColumnNode(children: []),
              block("右"),
            ],
          ),
        ],
      );

      expect(NaturalBlockParser.parse(input), expected);
      expect(
        NaturalBlockParser.parse("左^^右"),
        isNot(NaturalBlockParser.parse("左^右")),
        reason: "an extra empty cell must change the result",
      );
    });

    // The mirror of the case above: a Column block is content, so an empty
    // one contributes no node at all rather than a blank entry.
    test("an empty Column block contributes no node", () {
      const input = "左||右";
      final expected = DocumentNode(children: [block("左"), block("右")]);

      expect(NaturalBlockParser.parse(input), expected);
    });
  });

  group("A trailing separator opens a cell, wherever the row ends", () {
    // This used to be an exception: a `=` at the very end of the source
    // opened nothing, so `左=右=` was two cells while the identical row in
    // `左=右=|c` was three. The row meant one thing at the end of a document
    // and another with a character after it -- which a reader watched happen
    // live as they typed past it, the layout jumping on the next keystroke.
    //
    // The general rules already covered this without a special case: an
    // empty Row cell is a position the layout keeps (`左^^右`), and a `^`
    // before a `|` or `~` opens a cell the same way. `isEnd` was the only
    // place in the parser that read the end of the source as anything other
    // than one more boundary.

    /// The number of cells in each row a source parses to, inside a table
    /// or out.
    List<int> widths(String source) => [
      for (final block in NaturalBlockParser.parse(source).children)
        if (block is RowNode)
          block.children.length
        else if (block is ColumnNode)
          for (final piece in block.children)
            if (piece is TableNode)
              for (final row in piece.children) row.children.length,
    ];

    test("a trailing Row separator adds a final empty cell", () {
      const input = "左^右^";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              block("左"),
              block("右"),
              ColumnNode(children: []),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("the same row is the same width whatever follows it", () {
      // The regression this group exists for. Appending one character must
      // not change how many cells the row before it has.
      expect(widths("左^右^"), [3]);
      expect(widths("左^右^|c"), [3]);
      expect(widths("左^右^~c").first, 3);
      expect(widths("~左^右^~"), [3]);
    });

    test("a trailing `^` does not change a table's declared width", () {
      // It reaches further inside a table: the width comes from the widest
      // row, so a row that changed width with the document's end would
      // change how every other row is squared off for drawing.
      final open = onlyTable("~左^右^");
      final closed = onlyTable("~左^右^~");

      expect(open.columns.length, 3);
      expect(closed.columns.length, 3);
    });

    test("both ends behave alike, and since nothing but '^' separates them, "
        "all four cells land in a single row", () {
      const input = "^左^右^";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              ColumnNode(children: []),
              block("左"),
              block("右"),
              ColumnNode(children: []),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("a Row separator followed by a trailing Column separator does "
        "add a final empty cell to the row", () {
      const input = "左^右^|";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              block("左"),
              block("右"),
              ColumnNode(children: []),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("a mid-stream empty block (for contrast with the trailing case) "
        "does produce an empty cell, and since both sides of the '|' are "
        "Row cells they land in the same row", () {
      const input = "^|";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              ColumnNode(children: []),
              ColumnNode(children: []),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("an escaped separator at the very end is literal text, and the "
        "block it ends up in is still emitted", () {
      const input = r"左^右\^";
      final expected = DocumentNode(
        children: [
          RowNode(children: [block("左"), block("右^")]),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });
  });

  group("Row boundaries are explicit, not sibling adjacency", () {
    test("a Column separator between two rows ends the first row", () {
      const input = "a^b|c^d";
      final expected = DocumentNode(
        children: [
          RowNode(children: [block("a"), block("b")]),
          RowNode(children: [block("c"), block("d")]),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("a row followed by plain text still separates correctly", () {
      const input = "a^b|text";
      final expected = DocumentNode(
        children: [
          RowNode(children: [block("a"), block("b")]),
          block("text"),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("plain text followed by a row still separates correctly", () {
      const input = "text|a^b";
      final expected = DocumentNode(
        children: [
          block("text"),
          RowNode(children: [block("a"), block("b")]),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("a multi-line cell keeps its lines inside one ColumnNode", () {
      const input = "左1\n左2^右";
      final expected = DocumentNode(
        children: [
          RowNode(children: [block("左1\n左2"), block("右")]),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });
  });

  group("Block alignment", () {
    test("a marker after each separator aligns the cell it starts", () {
      const input = "|<A^>B|";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              cell("A", HorizontalAlign.start),
              cell("B", HorizontalAlign.end),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("a marker on a plain block wraps it in a centered ColumnNode", () {
      const input = "|=見出し|";
      final expected = DocumentNode(
        children: [cell("見出し", HorizontalAlign.center)],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("a cell with no marker states no alignment at all", () {
      const input = "左^右";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              ColumnNode(
                children: [line("左")],
                align: HorizontalAlign.unstated,
              ),
              ColumnNode(
                children: [line("右")],
                align: HorizontalAlign.unstated,
              ),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("saying nothing is not the same as saying `<`", () {
      // The whole reason align is nullable. A theme can give unaligned
      // blocks whatever it likes -- centered headings, say -- and a block
      // that wrote `<` still opts out of that and sits at the start.
      ColumnNode only(String source) =>
          NaturalBlockParser.parse(source).children.single as ColumnNode;

      expect(only("本文").align, HorizontalAlign.unstated);
      expect(only("|<本文|").align, HorizontalAlign.start);
      expect(only("本文"), isNot(only("|<本文|")));
    });

    test("an unaligned plain block is still a bare TextNode", () {
      const input = "本文";
      final expected = DocumentNode(children: [block("本文")]);

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("an escaped separator leaves a following '>' as literal text", () {
      const input = r"x \^> y";
      final expected = DocumentNode(children: [block("x ^> y")]);

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("'>' in ordinary prose stays literal", () {
      const cases = ["a > b", "List<String>", "->"];
      for (final input in cases) {
        final expected = DocumentNode(
          children: [
            ColumnNode(
              children: [
                TextNode(children: [TextSpanNode(text: input)]),
              ],
            ),
          ],
        );

        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected, reason: input);
      }
    });

    test("the marker is consumed and never appears in the cell's text", () {
      const input = "|>右寄せ|";
      final expected = DocumentNode(
        children: [cell("右寄せ", HorizontalAlign.end)],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("a marker combines with decoration on the same block", () {
      const input = "|>:!赤い数字|";
      final expected = DocumentNode(
        children: [
          ColumnNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(
                    text: "赤い数字",
                    decoration: SpanDecoration(color: SemanticColor.danger),
                  ),
                ],
              ),
            ],
            align: HorizontalAlign.end,
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("a second marker is ordinary text", () {
      // 【解説】 寄せは1つの軸の1つの値なので、2文字目は矛盾しか言えない。
      // どちらを採るかの規則を持たず、読むのは1文字だけにしてある。
      // 装飾クラスタが並びを読むのは軸が複数あるからで、`:+!*` は3つの
      // 別のことを言う。`|<>` は同じことを2回言っている。
      expect(
        NaturalBlockParser.parse("|<>a"),
        DocumentNode(children: [cell(">a", HorizontalAlign.start)]),
      );
    });

    test("a row symbol ends the markers rather than being one", () {
      // 【解説】 `^` はマーカーではないので、寄せの並びをそこで終わらせて
      // 新しいセルを開く。`|<^>a` は「end 寄せの塊」ではなく行になる。
      expect(
        NaturalBlockParser.parse("|<^>a"),
        DocumentNode(
          children: [
            RowNode(
              children: [
                empty(HorizontalAlign.start),
                cell("a", HorizontalAlign.end),
              ],
            ),
          ],
        ),
      );
    });
  });

  group("An empty block contributes nothing, marker or not", () {
    test("an alignment marker does not materialize an empty block", () {
      // An empty Column block contributes no node at all; a marker cannot
      // change that, because there is nothing inside to be aligned.
      // Previously `a||b` gave two nodes while `a|>|b` gave three, the
      // middle one an empty ColumnNode -- contradicting the stated rule.
      expect(
        NaturalBlockParser.parse(r"a|>|b"),
        NaturalBlockParser.parse(r"a||b"),
      );
    });

    test("this holds for every alignment marker", () {
      final plain = NaturalBlockParser.parse("a||b");

      for (final marker in ["<", "=", ">"]) {
        expect(
          NaturalBlockParser.parse("a|$marker|b"),
          plain,
          reason: "an empty block marked `$marker` is still nothing",
        );
      }
    });
  });
}
