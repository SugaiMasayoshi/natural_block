import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'nodes.dart';

void main() {
  group("Font size change and reset behavior", () {
    test("inline size change is held without a closing symbol", () {
      // No closing symbol needed: :++ gives +2, :-- gives -2, netting back to 0
      const input = ":++大きい:--標準サイズ";
      final expected = [
        TextSpanNode(text: "大きい", decoration: SpanDecoration(sizeOffset: 2)),
        TextSpanNode(text: "標準サイズ", decoration: SpanDecoration(sizeOffset: 0)),
      ];

      expect(runs(input), expected);
    });

    test("consecutive size-decreasing runs accumulate", () {
      // ":-少し小さい" gives -1, then ":---" gives -3 more, for a total of -4
      const input = ":-少し小さい:---もっと小さい";
      final expected = [
        TextSpanNode(text: "少し小さい", decoration: SpanDecoration(sizeOffset: -1)),
        TextSpanNode(
          text: "もっと小さい",
          decoration: SpanDecoration(sizeOffset: -4),
        ),
      ];

      expect(runs(input), expected);
    });

    group("The `:` prefix and cheap repeat stacking", () {
      // Only the first `+`/`-` after a run needs the `:` prefix; repeating
      // the bare character right after keeps stacking just as cheaply as
      // typing `+++` used to, while a bare `+`/`-` with no leading `:`
      // never triggers anything (safe in ordinary prose, including numeric
      // ranges like "10-20" and English compounds like "well-known").
      test("a single : followed by a run of the same character stacks", () {
        const input = ":+++大きい";
        final expected = [
          TextSpanNode(text: "大きい", decoration: SpanDecoration(sizeOffset: 3)),
        ];

        expect(runs(input), expected);
      });

      test("bare + and - never trigger a size change on their own", () {
        const input = "10-20人がA+の評価、1+1^2も普通の文章";
        final expected = DocumentNode(
          children: [
            RowNode(children: [block("10-20人がA+の評価、1+1"), block("2も普通の文章")]),
          ],
        );

        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });
    });

    group("Independence of size, color, and emphasis", () {
      // Size (:+/:-), color (:!:%), and emphasis (:*) are independent
      // axes: a symbol from one axis never resets the state of another.
      test("size is preserved when a color symbol appears", () {
        const input = ":++大きく:!危険";
        final expected = [
          TextSpanNode(text: "大きく", decoration: SpanDecoration(sizeOffset: 2)),
          TextSpanNode(
            text: "危険",
            decoration: SpanDecoration(tone: Tone.negative, sizeOffset: 2),
          ),
        ];

        expect(runs(input), expected);
      });

      test(
        "a preceding color decoration is preserved when a size symbol appears",
        () {
          const input = ":!危険状態:++大きく";
          final expected = [
            TextSpanNode(
              text: "危険状態",
              decoration: SpanDecoration(tone: Tone.negative, sizeOffset: 0),
            ),
            TextSpanNode(
              text: "大きく",
              decoration: SpanDecoration(tone: Tone.negative, sizeOffset: 2),
            ),
          ];

          expect(runs(input), expected);
        },
      );

      test("color and emphasis can be specified at the same time (not mutually exclusive)", () {
        const input = ":!*重要な警告:*危険は継続:!普通";
        final expected = [
          TextSpanNode(
            text: "重要な警告",
            decoration: SpanDecoration(tone: Tone.negative, emphasis: true),
          ),
          TextSpanNode(
            text: "危険は継続",
            decoration: SpanDecoration(tone: Tone.negative, emphasis: false),
          ),
          TextSpanNode(
            text: "普通",
            decoration: SpanDecoration(tone: Tone.none),
          ),
        ];

        expect(runs(input), expected);
      });

      test("size, color, and emphasis can all be held at the same time", () {
        const input = ":++!*重要";
        final expected = [
          TextSpanNode(
            text: "重要",
            decoration: SpanDecoration(
              sizeOffset: 2,
              tone: Tone.negative,
              emphasis: true,
            ),
          ),
        ];

        expect(runs(input), expected);
      });
    });

    group("Reset at layout boundaries", () {
      test("the Row layout symbol (^) resets the font size", () {
        const input = ":++大きい^右は標準";
        final expected = DocumentNode(
          children: [
            RowNode(
              children: [
                ColumnNode(
                  children: [
                    TextNode(
                      children: [
                        TextSpanNode(
                          text: "大きい",
                          decoration: SpanDecoration(sizeOffset: 2),
                        ),
                      ],
                    ),
                  ],
                ),
                ColumnNode(
                  children: [
                    TextNode(
                      children: [
                        TextSpanNode(
                          text: "右は標準",
                          decoration: SpanDecoration(sizeOffset: 0),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });

      test("the Column layout symbol (|) resets the font size", () {
        const input = "|:++上は大きい|下は標準|";
        final expected = DocumentNode(
          children: [
            ColumnNode(
              children: [
                TextNode(
                  children: [
                    TextSpanNode(
                      text: "上は大きい",
                      decoration: SpanDecoration(sizeOffset: 2),
                    ),
                  ],
                ),
              ],
            ),
            ColumnNode(
              children: [
                TextNode(
                  children: [
                    TextSpanNode(
                      text: "下は標準",
                      decoration: SpanDecoration(sizeOffset: 0),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });
    });
  });
}
