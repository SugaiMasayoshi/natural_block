// 【解説】[テスト6/21] 色と強調のトグル。装飾の状態機械が正しいことの確認。
// 【解説】
// 【解説】 同じ記号をもう一度書くと消える(トグル)、閉じ忘れは行末まで続く、
// 【解説】 レイアウト記号を跨ぐと全部消える、という3つが中心。
// 【解説】
// 【解説】 末尾の "Collision safety" が一番大事な group で、! ? % * を
// 【解説】 普通に含む文章が完全に素通しであることを見ている。ここが崩れたら
// 【解説】 言語の前提が崩れる。
// 【解説】 次: test/font_size_test.dart

import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  group("SemanticColor & toggle parsing edge cases", () {
    test("switching between multiple styles in sequence", () {
      // Each of the four decoration kinds (danger, info, success, emphasis)
      // toggles on then off in turn, with plain text in between -- verifies
      // they don't interfere with each other across the whole sequence.
      const input = ":!赤:!通常:?青:?通常:%緑:%通常:*太字:*";
      final expected = DocumentNode(
        children: [
          ColumnNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(text: "赤", color: SemanticColor.danger),
                  TextSpanNode(text: "通常"),
                  TextSpanNode(text: "青", color: SemanticColor.info),
                  TextSpanNode(text: "通常"),
                  TextSpanNode(text: "緑", color: SemanticColor.success),
                  TextSpanNode(text: "通常"),
                  TextSpanNode(text: "太字", emphasis: true),
                ],
              ),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("overwriting a style directly with a different one", () {
      // Danger is closed by opening info directly -- no explicit `:!` or
      // `::` reset is written in between -- so switching colors mid-stream
      // must not require closing the previous one first.
      const input = ":!危険から:?情報へ切り替え:?最後は通常";
      final expected = DocumentNode(
        children: [
          ColumnNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(text: "危険から", color: SemanticColor.danger),
                  TextSpanNode(text: "情報へ切り替え", color: SemanticColor.info),
                  TextSpanNode(text: "最後は通常"),
                ],
              ),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("an unclosed symbol runs to the end of the text", () {
      // Danger is opened but never explicitly closed -- it must stay active
      // all the way to the end of the input rather than being dropped or
      // silently reverting to plain.
      const input = "通常テキスト:!ここから文末までずっと危険状態";
      final expected = DocumentNode(
        children: [
          ColumnNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(text: "通常テキスト"),
                  TextSpanNode(
                    text: "ここから文末までずっと危険状態",
                    color: SemanticColor.danger,
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

    test("the same symbol repeated in a row", () {
      // The trailing ":!!" (one cluster, "!" doubled) toggles danger on then
      // immediately off within the same cluster; verifies no empty-text
      // node is created and that it correctly falls back to plain.
      const input = ":!危険:!普通:!!普通";
      final expected = DocumentNode(
        children: [
          ColumnNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(text: "危険", color: SemanticColor.danger),
                  TextSpanNode(text: "普通"),
                  TextSpanNode(text: "普通"),
                ],
              ),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("style independence between cells inside a Row block", () {
      // Danger is opened and closed inside the left cell only -- it must
      // not leak across the `=` boundary into the right cell.
      const input = "||:!左は危険:!^右は通常||";
      final expected = DocumentNode(
        children: [
          RowNode(
            children: [
              ColumnNode(
                children: [
                  TextNode(
                    children: [
                      TextSpanNode(text: "左は危険", color: SemanticColor.danger),
                    ],
                  ),
                ],
              ),
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "右は通常")]),
                ],
              ),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("a complex multi-block document combining several styles", () {
      const input = """
|
:!警告: システムエラー:!
:*補足事項:*
|エラーコード: 500^解決策: :?管理者へ連絡:?|
処理完了
|""";

      final expected = DocumentNode(
        children: [
          ColumnNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(
                    text: "警告: システムエラー",
                    color: SemanticColor.danger,
                  ),
                  TextSpanNode(text: "\n"),
                  TextSpanNode(text: "補足事項", emphasis: true),
                ],
              ),
            ],
          ),
          RowNode(
            children: [
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "エラーコード: 500")]),
                ],
              ),
              ColumnNode(
                children: [
                  TextNode(
                    children: [
                      TextSpanNode(text: "解決策: "),
                      TextSpanNode(text: "管理者へ連絡", color: SemanticColor.info),
                    ],
                  ),
                ],
              ),
            ],
          ),
          ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: "処理完了")]),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("color and emphasis can be combined (not mutually exclusive)", () {
      // :!*緊急対応:: -- a combined cluster sets both at once, and the
      // shared reset closes them both together at the end
      const input = ":!*緊急対応::";
      final expected = DocumentNode(
        children: [
          ColumnNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(
                    text: "緊急対応",
                    color: SemanticColor.danger,
                    emphasis: true,
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

    group("Collision safety with ordinary punctuation", () {
      // The whole point of the `:`-prefixed design: a bare `!`, `?`, `%`, or
      // `*` -- which shows up constantly in normal prose, in both Japanese
      // and English -- never triggers decoration on its own.
      test("ordinary sentences full of !, ?, %, and * stay entirely plain", () {
        const input = "Really?! It's on sale for 50% off, and it's *great*!";
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
        expect(nodes, expected);
      });

      test("the shared :: reset closes color and emphasis together", () {
        const input = ":!*緊急::普通";
        final expected = DocumentNode(
          children: [
            ColumnNode(
              children: [
                TextNode(
                  children: [
                    TextSpanNode(
                      text: "緊急",
                      color: SemanticColor.danger,
                      emphasis: true,
                    ),
                    TextSpanNode(text: "普通"),
                  ],
                ),
              ],
            ),
          ],
        );

        final nodes = NaturalBlockParser.parse(input);
        expect(nodes, expected);
      });

      test(":: resets even when only one of color/emphasis is active", () {
        const input = ":*太字だけ::普通";
        final expected = DocumentNode(
          children: [
            ColumnNode(
              children: [
                TextNode(
                  children: [
                    TextSpanNode(text: "太字だけ", emphasis: true),
                    TextSpanNode(text: "普通"),
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

    group("Combined clusters (multiple symbols sharing one `:`)", () {
      // A single `:` can be followed by more than one decoration character,
      // applying each in order. This is the only way to combine symbols
      // without a `:` reset landing in between them -- writing separate
      // `:X` tokens with no text separating them is not equivalent (see
      // "a combined cluster differs from adjacent separate clusters" below).
      test("a combined :!* cluster applies danger and emphasis together", () {
        const input = ":!*緊急対応";
        final expected = DocumentNode(
          children: [
            ColumnNode(
              children: [
                TextNode(
                  children: [
                    TextSpanNode(
                      text: "緊急対応",
                      color: SemanticColor.danger,
                      emphasis: true,
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

      test("a combined cluster can mix size with color and emphasis", () {
        const input = ":+!*重要";
        final expected = DocumentNode(
          children: [
            ColumnNode(
              children: [
                TextNode(
                  children: [
                    TextSpanNode(
                      text: "重要",
                      sizeOffset: 1,
                      color: SemanticColor.danger,
                      emphasis: true,
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

      test("a combined cluster differs from adjacent separate clusters", () {
        // ":" always continues extending the current cluster (including a
        // further ":", which resets) -- so writing two separate `:X`
        // tokens back to back, with no text between them, is not the same
        // as combining them in one cluster: the second `:` in ":!:*" is
        // absorbed into the first cluster as a reset before "*" opens
        // emphasis, wiping out danger. To combine symbols without a reset
        // in between, write them in one cluster (`:!*`).
        const combined = ":!*結果";
        const adjacentSeparate = ":!:*結果";

        final combinedExpected = DocumentNode(
          children: [
            ColumnNode(
              children: [
                TextNode(
                  children: [
                    TextSpanNode(
                      text: "結果",
                      color: SemanticColor.danger,
                      emphasis: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
        final separateExpected = DocumentNode(
          children: [
            ColumnNode(
              children: [
                TextNode(children: [TextSpanNode(text: "結果", emphasis: true)]),
              ],
            ),
          ],
        );

        expect(NaturalBlockParser.parse(combined), combinedExpected);
        expect(NaturalBlockParser.parse(adjacentSeparate), separateExpected);
      });

      test("a : right before :: ends its own cluster rather than being swallowed by the reset", () {
        // ":!" (danger) then "::" (reset) are two separate clusters -- the
        // reset must not be absorbed into the first cluster's payload.
        const input = ":!危険::普通";
        final expected = DocumentNode(
          children: [
            ColumnNode(
              children: [
                TextNode(
                  children: [
                    TextSpanNode(text: "危険", color: SemanticColor.danger),
                    TextSpanNode(text: "普通"),
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
