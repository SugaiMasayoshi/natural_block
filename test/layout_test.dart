import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  final parser = NaturalBlockParser();

  group("Column newline trimming", () {
    // Expected: root keeps its Column wrapper
    final expected = ColumnNode(
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
    // Expected: root Column wraps RowNodes, each RowNode wraps one TextNode
    final expected = ColumnNode(
      children: [
        RowNode(
          children: [
            TextNode(children: [TextSpanNode(text: "左")]),
          ],
        ),
        RowNode(
          children: [
            TextNode(children: [TextSpanNode(text: "右")]),
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
      final expected = ColumnNode(
        children: [
          RowNode(
            children: [
              TextNode(children: [TextSpanNode(text: "左")]),
            ],
          ),
          RowNode(children: []),
          RowNode(
            children: [
              TextNode(children: [TextSpanNode(text: "右")]),
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
      final expected = ColumnNode(
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
    // final (empty) block would be emitted for it -- no trailing empty
    // RowNode appears. This is specific to running out of input right at
    // the end; a mid-stream empty block (see "=|" below) still produces an
    // empty RowNode as usual.
    test("a trailing Row separator does not produce a final empty RowNode", () {
      const input = "左=右=";
      final expected = ColumnNode(
        children: [
          RowNode(
            children: [
              TextNode(children: [TextSpanNode(text: "左")]),
            ],
          ),
          RowNode(
            children: [
              TextNode(children: [TextSpanNode(text: "右")]),
            ],
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test(
      "a leading Row separator still produces an empty RowNode, but a "
      "trailing one does not",
      () {
        const input = "=左=右=";
        final expected = ColumnNode(
          children: [
            RowNode(children: []),
            RowNode(
              children: [
                TextNode(children: [TextSpanNode(text: "左")]),
              ],
            ),
            RowNode(
              children: [
                TextNode(children: [TextSpanNode(text: "右")]),
              ],
            ),
          ],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected);
      },
    );

    test(
      "a Row separator followed by a trailing Column separator does "
      "produce a final empty RowNode",
      () {
        const input = "左=右=|";
        final expected = ColumnNode(
          children: [
            RowNode(
              children: [
                TextNode(children: [TextSpanNode(text: "左")]),
              ],
            ),
            RowNode(
              children: [
                TextNode(children: [TextSpanNode(text: "右")]),
              ],
            ),
            RowNode(children: []),
          ],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected);
      },
    );

    test(
      "a mid-stream empty block (for contrast with the trailing case) "
      "does produce an empty RowNode",
      () {
        const input = "=|";
        final expected = ColumnNode(
          children: [RowNode(children: []), RowNode(children: [])],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected);
      },
    );

    test(
      "an escaped separator at the very end is literal text, and the "
      "block it ends up in is still emitted",
      () {
        const input = r"左=右\=";
        final expected = ColumnNode(
          children: [
            RowNode(
              children: [
                TextNode(children: [TextSpanNode(text: "左")]),
              ],
            ),
            RowNode(
              children: [
                TextNode(children: [TextSpanNode(text: "右=")]),
              ],
            ),
          ],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected);
      },
    );
  });
}
