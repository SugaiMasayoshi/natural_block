// 【解説】[テスト8/21] アクション(:@)。何を意味するかは決めない、という構文。
// 【解説】
// 【解説】 パーサが記録するのは「この範囲は操作可能」だけで、範囲のテキスト
// 【解説】 そのものが全ての情報。URL を開くのか節に飛ぶのかはアプリの判断。
// 【解説】 だから画像もここに乗っている(:@image(url):@)。言語に画像構文を
// 【解説】 足さずに済ませたのがこの設計の見返り。
// 【解説】
// 【解説】 末尾のテストが名前で「非対称を固定する」と言っている。:: が
// 【解説】 アクションを消すのにサイズを消さないのは仕様、という宣言。
// 【解説】 次: test/input_normalization_test.dart

import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  group("actionable text (:@)", () {
    test("toggles on and off", () {
      const input = ":@https://example.com:@ を参照してください";
      final expected = DocumentNode(
        children: [
          TextNode(
            children: [
              TextSpanNode(text: "https://example.com", isAction: true),
              TextSpanNode(text: " を参照してください"),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("an unclosed :@ runs to the end of the line", () {
      const input = "詳細は:@#売上データ に記載";
      final expected = DocumentNode(
        children: [
          TextNode(
            children: [
              TextSpanNode(text: "詳細は"),
              TextSpanNode(text: "#売上データ に記載", isAction: true),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test(":: clears an open action, along with color and emphasis", () {
      const input = ":!*@赤太字押せる::通常";
      // Note: `:@` is not a single-char decoration in this cluster since we
      // build the cluster from ':' followed by consecutive decoration
      // chars -- `!`, `*`, `@` all apply in order.
      final expected = DocumentNode(
        children: [
          TextNode(
            children: [
              TextSpanNode(
                text: "赤太字押せる",
                color: SemanticColor.danger,
                emphasis: true,
                isAction: true,
              ),
              TextSpanNode(text: "通常"),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("combined cluster: :@* is both actionable and bold", () {
      const input = ":@*重要:@*";
      final expected = DocumentNode(
        children: [
          TextNode(
            children: [
              TextSpanNode(text: "重要", emphasis: true, isAction: true),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("a bare @ is never markup", () {
      const input1 = "user@example.com";
      expect(
        NaturalBlockParser.parse(input1),
        DocumentNode(
          children: [
            TextNode(children: [TextSpanNode(text: "user@example.com")]),
          ],
        ),
      );

      const input2 = "@mention";
      expect(
        NaturalBlockParser.parse(input2),
        DocumentNode(
          children: [
            TextNode(children: [TextSpanNode(text: "@mention")]),
          ],
        ),
      );

      const input3 = "メール: a@b.jp";
      expect(
        NaturalBlockParser.parse(input3),
        DocumentNode(
          children: [
            TextNode(children: [TextSpanNode(text: "メール: a@b.jp")]),
          ],
        ),
      );
    });

    test(r"\@ inside a cluster is literal", () {
      const input = r":---\@abc";
      final expected = DocumentNode(
        children: [
          TextNode(children: [TextSpanNode(text: "@abc", sizeOffset: -3)]),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });

    test("size is not cleared by :: while action is -- pins the asymmetry", () {
      const input = ":+++大:@押せる::普通";
      final expected = DocumentNode(
        children: [
          TextNode(
            children: [
              TextSpanNode(text: "大", sizeOffset: 3),
              TextSpanNode(text: "押せる", sizeOffset: 3, isAction: true),
              TextSpanNode(text: "普通", sizeOffset: 3),
            ],
          ),
        ],
      );

      final nodes = NaturalBlockParser.parse(input);
      expect(nodes, expected);
    });
  });
}
