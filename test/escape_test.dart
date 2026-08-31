import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  final parser = NaturalBlockParser();

  group("Escape handling", () {
    group("Layout symbol escaping", () {
      test("an escaped pipe is parsed as a literal character, not a Column separator", () {
        const input = r"|A\|B|";
        final expected = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "A|B")]),
          ],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected);
      });

      test("an escaped equals sign is parsed as a single literal text, not a Row separator", () {
        const input = r"左\=右";
        final expected = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "左=右")]),
          ],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected);
      });
    });

    group("Bare decoration characters never need escaping", () {
      // Every decoration symbol requires the `:` prefix (`:!`, `:?`, `:%`,
      // `:*`, `:+`, `:-`) to activate, so a bare `!`, `?`, `%`, `*`, `+`, or
      // `-` -- extremely common in ordinary prose in both Japanese and
      // English -- is always literal text on its own, with no escaping.
      test("a bare plus sign is literal, no escaping needed", () {
        const input = "C++言語、1+1=2";
        final expected = ColumnNode(
          children: [
            RowNode(
              children: [
                TextNode(children: [TextSpanNode(text: "C++言語、1+1")]),
              ],
            ),
            RowNode(
              children: [
                TextNode(children: [TextSpanNode(text: "2")]),
              ],
            ),
          ],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected);
      });

      test("a bare minus sign is literal, no escaping needed", () {
        const input = "-100点、10-20人";
        final expected = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "-100点、10-20人")]),
          ],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected);
      });
      test("a bare exclamation mark is literal, no escaping needed", () {
        const input = "こんにちは!世界";
        final expected = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "こんにちは!世界")]),
          ],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected);
      });

      test("a bare question mark is literal, no escaping needed", () {
        const input = "本当ですか?はい";
        final expected = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "本当ですか?はい")]),
          ],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected);
      });

      test("a bare percent sign is literal, no escaping needed", () {
        const input = "進捗100%完了";
        final expected = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "進捗100%完了")]),
          ],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected);
      });

      test("a bare asterisk is literal, no escaping needed", () {
        const input = "*太字にしない*";
        final expected = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "*太字にしない*")]),
          ],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected);
      });
    });

    group("Escaping the `:`-prefixed decoration tokens", () {
      test("an escaped :! is parsed as two literal characters, not danger coloring", () {
        const input = r"こんにちは\:!世界";
        final expected = ColumnNode(
          children: [
            TextNode(
              children: [
                TextSpanNode(text: "こんにちは:!世界", color: SemanticColor.none),
              ],
            ),
          ],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected);
      });

      test(
        "an escaped :: is parsed as two literal characters, not a reset",
        () {
          const input = r":!危険\::普通:!";
          final expected = ColumnNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(text: "危険::普通", color: SemanticColor.danger),
                ],
              ),
            ],
          );

          final nodes = parser.parse(input);
          expect(nodes, expected);
        },
      );

      test(
        "an escaped :+ is parsed as two literal characters, not a size change",
        () {
          const input = r"サイズ\:+固定";
          final expected = ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: "サイズ:+固定")]),
            ],
          );

          final nodes = parser.parse(input);
          expect(nodes, expected);
        },
      );
    });

    group("Escaping inside a decoration block", () {
      test(
        "an escaped :! symbol inside a decoration block does not close it",
        () {
          const input = r":!重要\:!警告:!";
          final expected = ColumnNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(text: "重要:!警告", color: SemanticColor.danger),
                ],
              ),
            ],
          );

          final nodes = parser.parse(input);
          expect(nodes, expected);
        },
      );

      test("an escaped colon right where the backslash itself ends the cluster "
          "still counts as escaped", () {
        const input = r":!\:";
        final expected = ColumnNode(
          children: [
            TextNode(
              children: [TextSpanNode(text: ":", color: SemanticColor.danger)],
            ),
          ],
        );

        final nodes = parser.parse(input);
        expect(nodes, expected);
      });
    });
  });
}
