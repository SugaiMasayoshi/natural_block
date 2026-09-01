import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  final parser = NaturalBlockParser();

  group("Column newline trimming", () {
    // Expected: root keeps its Column wrapper
    final expected = DocumentNode(
      children: [
        TextNode(children: [TextSpanNode(text: "本文")]),
      ],
    );

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
        final nodes = parser.parse(input);
        expect(nodes, expected);
      });
    }
  });

  group("Row newline trimming", () {
    // Expected: root Column wraps one RowNode, whose two cells are each a
    // ColumnNode wrapping one TextNode
    final expected = DocumentNode(
      children: [
        RowNode(
          children: [
            ColumnNode(
              children: [
                TextNode(children: [TextSpanNode(text: "左")]),
              ],
            ),
            ColumnNode(
              children: [
                TextNode(children: [TextSpanNode(text: "右")]),
              ],
            ),
          ],
        ),
      ],
    );

    const cases = [
      "左=右",
      "|左=右",
      "|左=右|",
      "||左=右|",
      "|左=右||",
      "||左=右||",
      "||\n左=右||",
      "||左=右\n||",
      "||\n左=右\n||",
      "|\n|左=右||",
      "||左=右|\n|",
      "|\n|左=右|\n|",
    ];

    for (final (index, input) in cases.indexed) {
      test("Row newline trim pattern $index", () {
        final nodes = parser.parse(input);
        expect(nodes, expected);
      });
    }
  });

  group("Boundary and special cases", () {
    test("empty blocks are ignored / handled safely", () {
      const input = "|||";
      final nodes = parser.parse(input);
      expect(nodes.children.isEmpty, isTrue);
    });

    // A Row cell is a position, not just content: the cells around it are
    // laid out relative to it, so a blank one has to survive. This is what
    // makes a deliberately empty middle cell expressible at all -- without
    // it, "左==右" and "左=右" would parse identically.
    test("an empty Row cell between two filled ones is kept as a position", () {
      const input = "左==右";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "左")]),
                ],
              ),
              ColumnNode(children: []),
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "右")]),
                ],
              ),
            ],
          ),
        ],
      );

      expect(parser.parse(input), expected);
      expect(
        parser.parse("左==右"),
        isNot(parser.parse("左=右")),
        reason: "an extra empty cell must change the result",
      );
    });

    // The mirror of the case above: a Column block is content, so an empty
    // one contributes no node at all rather than a blank entry.
    test("an empty Column block contributes no node", () {
      const input = "左||右";
      final expected = DocumentNode(
        children: [
          TextNode(children: [TextSpanNode(text: "左")]),
          TextNode(children: [TextSpanNode(text: "右")]),
        ],
      );

      expect(parser.parse(input), expected);
    });
  });

  group("Trailing separator edge cases (pinned current behavior)", () {
    // A trailing Row separator leaves the scan positioned exactly at the
    // end of the source, so the loop that drives the scan exits before a
    // final (empty) block would be emitted for it -- the trailing "=" adds
    // no extra cell. The row started by the two cells that do exist is
    // still open when the loop ends, so a flush after the loop is what
    // emits it.
    test("a trailing Row separator does not add a final empty cell", () {
      const input = "左=右=";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "左")]),
                ],
              ),
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "右")]),
                ],
              ),
            ],
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("a leading Row separator still produces an empty cell, but a "
        "trailing one does not -- and since nothing but '=' separates them, "
        "all three cells land in a single row", () {
      const input = "=左=右=";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              ColumnNode(children: []),
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "左")]),
                ],
              ),
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "右")]),
                ],
              ),
            ],
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("a Row separator followed by a trailing Column separator does "
        "add a final empty cell to the row", () {
      const input = "左=右=|";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "左")]),
                ],
              ),
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "右")]),
                ],
              ),
              ColumnNode(children: []),
            ],
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("a mid-stream empty block (for contrast with the trailing case) "
        "does produce an empty cell, and since both sides of the '|' are "
        "Row cells they land in the same row", () {
      const input = "=|";
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

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("an escaped separator at the very end is literal text, and the "
        "block it ends up in is still emitted", () {
      const input = r"左=右\=";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "左")]),
                ],
              ),
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "右=")]),
                ],
              ),
            ],
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });
  });

  group("Row boundaries are explicit, not sibling adjacency", () {
    test("a Column separator between two rows ends the first row", () {
      const input = "a=b|c=d";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "a")]),
                ],
              ),
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "b")]),
                ],
              ),
            ],
          ),
          RowNode(
            children: [
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "c")]),
                ],
              ),
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "d")]),
                ],
              ),
            ],
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("a row followed by plain text still separates correctly", () {
      const input = "a=b|text";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "a")]),
                ],
              ),
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "b")]),
                ],
              ),
            ],
          ),
          TextNode(children: [TextSpanNode(text: "text")]),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("plain text followed by a row still separates correctly", () {
      const input = "text|a=b";
      final expected = DocumentNode(
        children: [
          TextNode(children: [TextSpanNode(text: "text")]),
          RowNode(
            children: [
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "a")]),
                ],
              ),
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "b")]),
                ],
              ),
            ],
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("a multi-line cell keeps its lines inside one ColumnNode", () {
      const input = "左1\n左2=右";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "左1")]),
                  TextNode(children: [TextSpanNode(text: "左2")]),
                ],
              ),
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "右")]),
                ],
              ),
            ],
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });
  });

  group("Block alignment", () {
    test("a marker after each separator aligns the cell it starts", () {
      const input = "|<A=>B|";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "A")]),
                ],
                align: BlockAlign.start,
              ),
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "B")]),
                ],
                align: BlockAlign.end,
              ),
            ],
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("a marker on a plain block wraps it in a centered ColumnNode", () {
      const input = "|^見出し|";
      final expected = DocumentNode(
        children: [
          ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: "見出し")]),
            ],
            align: BlockAlign.center,
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("a cell with no marker keeps the default start alignment", () {
      const input = "左=右";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "左")]),
                ],
                align: BlockAlign.start,
              ),
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "右")]),
                ],
                align: BlockAlign.start,
              ),
            ],
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("an unaligned plain block is still a bare TextNode", () {
      const input = "本文";
      final expected = DocumentNode(
        children: [
          TextNode(children: [TextSpanNode(text: "本文")]),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("an escaped separator leaves a following '>' as literal text", () {
      const input = r"x \=> y";
      final expected = DocumentNode(
        children: [
          TextNode(children: [TextSpanNode(text: "x => y")]),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("'>' in ordinary prose stays literal", () {
      const cases = ["a > b", "List<String>", "->"];
      for (final input in cases) {
        final expected = DocumentNode(
          children: [
            TextNode(children: [TextSpanNode(text: input)]),
          ],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected, reason: input);
      }
    });

    test("the marker is consumed and never appears in the cell's text", () {
      const input = "|>右寄せ|";
      final expected = DocumentNode(
        children: [
          ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: "右寄せ")]),
            ],
            align: BlockAlign.end,
          ),
        ],
      );

      final nodes = parser.parse(input);
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
                  TextSpanNode(text: "赤い数字", color: SemanticColor.danger),
                ],
              ),
            ],
            align: BlockAlign.end,
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });
  });
}
