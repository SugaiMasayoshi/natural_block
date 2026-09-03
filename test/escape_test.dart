// 【解説】[テスト3/21] エスケープ。裸の記号が素通しであることの証明が大半。
// 【解説】
// 【解説】 「バックスラッシュは、その地点で記号になるものだけを打ち消す」という
// 【解説】 一文が全ての規則で、テストの数が多いのは、それが場所によって
// 【解説】 何を指すかが変わるから(クラスタの中では装飾文字、外では : だけ)。
// 【解説】
// 【解説】 裸の + - ! ? % * が素通しであるテストが並んでいるのは冗長ではない。
// 【解説】 これがこの言語の存在理由そのもので、1つでも崩れたら C++ や 100% が
// 【解説】 書けなくなる。守っている対象が大きいので、テストも厚くしてある。
// 【解説】 次: test/verbatim_test.dart

import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  group("Escape handling", () {
    group("Layout symbol escaping", () {
      test("an escaped pipe is parsed as a literal character, not a Column separator", () {
        const input = r"|A\|B|";
        final expected = DocumentNode(
          children: [
            TextNode(children: [TextSpanNode(text: "A|B")]),
          ],
        );

        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });

      test("an escaped equals sign is parsed as a single literal text, not a Row separator", () {
        const input = r"左\=右";
        final expected = DocumentNode(
          children: [
            TextNode(children: [TextSpanNode(text: "左=右")]),
          ],
        );

        final nodes = NaturalBlockParser.parse(input);
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
        final expected = DocumentNode(
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

        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });

      test("a bare minus sign is literal, no escaping needed", () {
        const input = "-100点、10-20人";
        final expected = DocumentNode(
          children: [
            TextNode(children: [TextSpanNode(text: "-100点、10-20人")]),
          ],
        );

        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });
      test("a bare exclamation mark is literal, no escaping needed", () {
        const input = "こんにちは!世界";
        final expected = DocumentNode(
          children: [
            TextNode(children: [TextSpanNode(text: "こんにちは!世界")]),
          ],
        );

        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });

      test("a bare question mark is literal, no escaping needed", () {
        const input = "本当ですか?はい";
        final expected = DocumentNode(
          children: [
            TextNode(children: [TextSpanNode(text: "本当ですか?はい")]),
          ],
        );

        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });

      test("a bare percent sign is literal, no escaping needed", () {
        const input = "進捗100%完了";
        final expected = DocumentNode(
          children: [
            TextNode(children: [TextSpanNode(text: "進捗100%完了")]),
          ],
        );

        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });

      test("a bare asterisk is literal, no escaping needed", () {
        const input = "*太字にしない*";
        final expected = DocumentNode(
          children: [
            TextNode(children: [TextSpanNode(text: "*太字にしない*")]),
          ],
        );

        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });
    });

    group("Escaping the `:`-prefixed decoration tokens", () {
      test("an escaped :! is parsed as two literal characters, not danger coloring", () {
        const input = r"こんにちは\:!世界";
        final expected = DocumentNode(
          children: [
            TextNode(
              children: [
                TextSpanNode(text: "こんにちは:!世界", color: SemanticColor.none),
              ],
            ),
          ],
        );

        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });

      test(
        "an escaped :: is parsed as two literal characters, not a reset",
        () {
          const input = r":!危険\::普通:!";
          final expected = DocumentNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(text: "危険::普通", color: SemanticColor.danger),
                ],
              ),
            ],
          );

          final nodes = NaturalBlockParser.parse(input);
          expect(nodes, expected);
        },
      );

      test(
        "an escaped :+ is parsed as two literal characters, not a size change",
        () {
          const input = r"サイズ\:+固定";
          final expected = DocumentNode(
            children: [
              TextNode(children: [TextSpanNode(text: "サイズ:+固定")]),
            ],
          );

          final nodes = NaturalBlockParser.parse(input);
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
          final expected = DocumentNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(text: "100", sizeOffset: 3),
                  TextSpanNode(text: "%off"),
                ],
              ),
            ],
          );

          expect(NaturalBlockParser.parse(input), expected);
        },
      );

      test("one backslash is enough, since the cluster is over after it", () {
        const input = r":---\%%%off";
        final expected = DocumentNode(
          children: [
            TextNode(children: [TextSpanNode(text: "%%%off", sizeOffset: -3)]),
          ],
        );

        expect(NaturalBlockParser.parse(input), expected);
      });

      test("a backslash before a non-decoration character is left alone", () {
        // Nothing needed escaping, so the backslash is ordinary text -- the
        // same reason a Windows path survives untouched.
        const input = r":---\abc";
        final expected = DocumentNode(
          children: [
            TextNode(children: [TextSpanNode(text: r"\abc", sizeOffset: -3)]),
          ],
        );

        expect(NaturalBlockParser.parse(input), expected);
      });

      test(
        "a bare decoration character outside a cluster still needs no escape",
        () {
          // Escaping only engages where the character is actually markup, so
          // this is unchanged: the backslash stays in the output.
          const input = r"100\%off";
          final expected = DocumentNode(
            children: [
              TextNode(children: [TextSpanNode(text: r"100\%off")]),
            ],
          );

          expect(NaturalBlockParser.parse(input), expected);
        },
      );

      test("a Windows path keeps every backslash", () {
        const input = r"C:\Users\sugai";
        final expected = DocumentNode(
          children: [
            TextNode(children: [TextSpanNode(text: r"C:\Users\sugai")]),
          ],
        );

        expect(NaturalBlockParser.parse(input), expected);
      });
    });

    group("Escaping inside a decoration block", () {
      test(
        "an escaped :! symbol inside a decoration block does not close it",
        () {
          const input = r":!重要\:!警告:!";
          final expected = DocumentNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(text: "重要:!警告", color: SemanticColor.danger),
                ],
              ),
            ],
          );

          final nodes = NaturalBlockParser.parse(input);
          expect(nodes, expected);
        },
      );

      test("an escaped colon right where the backslash itself ends the cluster "
          "still counts as escaped", () {
        const input = r":!\:";
        final expected = DocumentNode(
          children: [
            TextNode(
              children: [TextSpanNode(text: ":", color: SemanticColor.danger)],
            ),
          ],
        );

        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });
    });

    group("Escaping the backslash itself", () {
      // Built up from a named single backslash rather than written inline:
      // these tests are entirely about *how many* backslashes there are,
      // and a string literal full of them is exactly where a miscount hides.
      const bs = r'\';

      TextNode line(String text) =>
          TextNode(children: [TextSpanNode(text: text)]);
      ColumnNode cell(String text) => ColumnNode(children: [line(text)]);

      test("`\\\\` before a separator is a literal backslash, and the "
          "separator still separates", () {
        // The case this rule exists for: without it there is no way to end a
        // cell with a backslash, because `\\=` escapes the separator and
        // yields one cell holding `=` instead of two cells split after `\`.
        expect(
          NaturalBlockParser.parse('$bs$bs=B'),
          DocumentNode(
            children: [
              RowNode(children: [cell(bs), cell('B')]),
            ],
          ),
        );
      });

      test("the same holds for a Column separator", () {
        expect(
          NaturalBlockParser.parse('$bs$bs|B'),
          DocumentNode(children: [line(bs), line('B')]),
        );
      });

      test("a single `\\` before a separator still escapes it", () {
        expect(
          NaturalBlockParser.parse('$bs=B'),
          DocumentNode(children: [line('=B')]),
        );
      });

      test("three backslashes are a literal one plus an escaped separator", () {
        expect(
          NaturalBlockParser.parse('$bs$bs$bs=B'),
          DocumentNode(children: [line('$bs=B')]),
        );
      });

      test("a literal backslash survives in front of a decoration cluster", () {
        // Resolving escapes in one place is what makes this work: were the
        // layout scan to collapse `\\` too, the lone backslash it left
        // behind would be read as an escape again here and swallow the `:`.
        final spans =
            (NaturalBlockParser.parse('$bs$bs:*x').children.single as TextNode)
                .children
                .cast<TextSpanNode>();

        expect(spans.first.text, bs);
        expect(spans.first.emphasis, isFalse);
        expect(spans.last.text, 'x');
        expect(spans.last.emphasis, isTrue);
      });

      test("a backslash before an ordinary character is still kept", () {
        // Unchanged, and the reason Windows paths need no escaping at all.
        expect(
          NaturalBlockParser.parse('C:${bs}Users${bs}sugai'),
          DocumentNode(children: [line('C:${bs}Users${bs}sugai')]),
        );
        expect(
          NaturalBlockParser.parse('$bs!'),
          DocumentNode(children: [line('$bs!')]),
        );
      });

      test("a lone trailing backslash is literal", () {
        expect(
          NaturalBlockParser.parse(bs),
          DocumentNode(children: [line(bs)]),
        );
      });

      test("a doubled backslash collapses even away from any markup", () {
        // The accepted cost of making `\` escapable: a UNC-style `\\server`
        // now reads as `\server`. Escaping one backslash is the price of
        // being able to write one before a separator at all.
        expect(
          NaturalBlockParser.parse('A$bs${bs}B'),
          DocumentNode(children: [line('A${bs}B')]),
        );
      });

      test("it works inside a table cell too", () {
        final table =
            NaturalBlockParser.parse('|~x=y|$bs$bs=z|').children.single
                as TableNode;

        expect(table.children[1].children.first, cell(bs));
        expect(table.children[1].children.last, cell('z'));
      });
    });
  });
}
