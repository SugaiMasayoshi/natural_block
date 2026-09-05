// 【解説】[テスト7/21] サイズ。他の軸と違って加算であることの確認。
// 【解説】
// 【解説】 色・強調・アクションはトグルだがサイズだけは +1/-1 の加算で、
// 【解説】 :: でも消えない。この非対称は意図的で、独立した軸だという主張。
// 【解説】 :+++ が +3 になるのは「クラスタは同じ文字を続けられる」だけの
// 【解説】 帰結で、サイズ専用の規則があるわけではない。
// 【解説】
// 【解説】 "Independence" の group が軸の独立を4通り総当たりしている。
// 【解説】 次: test/action_test.dart

import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'nodes.dart';

void main() {
  group("Font size change and reset behavior", () {
    test("inline size change is held without a closing symbol", () {
      // No closing symbol needed: :++ gives +2, :-- gives -2, netting back to 0
      const input = ":++大きい:--標準サイズ";
      final expected = [
        TextSpanNode(text: "大きい", sizeOffset: 2),
        TextSpanNode(text: "標準サイズ", sizeOffset: 0),
      ];

      expect(runs(input), expected);
    });

    test("consecutive size-decreasing runs accumulate", () {
      // ":-少し小さい" gives -1, then ":---" gives -3 more, for a total of -4
      const input = ":-少し小さい:---もっと小さい";
      final expected = [
        TextSpanNode(text: "少し小さい", sizeOffset: -1),
        TextSpanNode(text: "もっと小さい", sizeOffset: -4),
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
        final expected = [TextSpanNode(text: "大きい", sizeOffset: 3)];

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
          TextSpanNode(text: "大きく", sizeOffset: 2),
          TextSpanNode(text: "危険", color: SemanticColor.danger, sizeOffset: 2),
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
              color: SemanticColor.danger,
              sizeOffset: 0,
            ),
            TextSpanNode(
              text: "大きく",
              color: SemanticColor.danger,
              sizeOffset: 2,
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
            color: SemanticColor.danger,
            emphasis: true,
          ),
          TextSpanNode(
            text: "危険は継続",
            color: SemanticColor.danger,
            emphasis: false,
          ),
          TextSpanNode(text: "普通", color: SemanticColor.none),
        ];

        expect(runs(input), expected);
      });

      test("size, color, and emphasis can all be held at the same time", () {
        const input = ":++!*重要";
        final expected = [
          TextSpanNode(
            text: "重要",
            sizeOffset: 2,
            color: SemanticColor.danger,
            emphasis: true,
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
                      children: [TextSpanNode(text: "大きい", sizeOffset: 2)],
                    ),
                  ],
                ),
                ColumnNode(
                  children: [
                    TextNode(
                      children: [TextSpanNode(text: "右は標準", sizeOffset: 0)],
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
                  children: [TextSpanNode(text: "上は大きい", sizeOffset: 2)],
                ),
              ],
            ),
            ColumnNode(
              children: [
                TextNode(children: [TextSpanNode(text: "下は標準", sizeOffset: 0)]),
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
