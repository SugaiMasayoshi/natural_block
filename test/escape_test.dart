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
                ColumnNode(
                  children: [
                    TextNode(children: [TextSpanNode(text: "C++言語、1+1")]),
                  ],
                ),
                ColumnNode(
                  children: [
                    TextNode(children: [TextSpanNode(text: "2")]),
                  ],
                ),
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

    group("Escaping a decoration character inside a cluster", () {
      // A decoration character is markup only while a cluster is open, so
      // that is exactly where a backslash in front of one has work to do.
      // Without it there is no way to butt literal text starting with a
      // decoration character right up against a cluster -- a space would be
      // the only separator, and a space is often not what you want.
      test(
        "an escaped decoration character ends the cluster and stays literal",
        () {
          const input = r":+++100:---\%off";
          final expected = ColumnNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(text: "100", sizeOffset: 3),
                  TextSpanNode(text: "%off"),
                ],
              ),
            ],
          );

          expect(parser.parse(input), expected);
        },
      );

      test("one backslash is enough, since the cluster is over after it", () {
        const input = r":---\%%%off";
        final expected = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "%%%off", sizeOffset: -3)]),
          ],
        );

        expect(parser.parse(input), expected);
      });

      test("a backslash before a non-decoration character is left alone", () {
        // Nothing needed escaping, so the backslash is ordinary text -- the
        // same reason a Windows path survives untouched.
        const input = r":---\abc";
        final expected = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: r"\abc", sizeOffset: -3)]),
          ],
        );

        expect(parser.parse(input), expected);
      });

      test(
        "a bare decoration character outside a cluster still needs no escape",
        () {
          // Escaping only engages where the character is actually markup, so
          // this is unchanged: the backslash stays in the output.
          const input = r"100\%off";
          final expected = ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: r"100\%off")]),
            ],
          );

          expect(parser.parse(input), expected);
        },
      );

      test("a Windows path keeps every backslash", () {
        const input = r"C:\Users\sugai";
        final expected = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: r"C:\Users\sugai")]),
          ],
        );

        expect(parser.parse(input), expected);
      });
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
