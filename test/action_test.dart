import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  final parser = NaturalBlockParser();

  group("actionable text (:@)", () {
    test("toggles on and off", () {
      const input = ":@https://example.com:@ を参照してください";
      final expected = ColumnNode(
        children: [
          TextNode(
            children: [
              TextSpanNode(text: "https://example.com", isAction: true),
              TextSpanNode(text: " を参照してください"),
            ],
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("an unclosed :@ runs to the end of the line", () {
      const input = "詳細は:@#売上データ に記載";
      final expected = ColumnNode(
        children: [
          TextNode(
            children: [
              TextSpanNode(text: "詳細は"),
              TextSpanNode(text: "#売上データ に記載", isAction: true),
            ],
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test(":: clears an open action, along with color and emphasis", () {
      const input = ":!*@赤太字押せる::通常";
      // Note: `:@` is not a single-char decoration in this cluster since we
      // build the cluster from ':' followed by consecutive decoration
      // chars -- `!`, `*`, `@` all apply in order.
      final expected = ColumnNode(
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

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("combined cluster: :@* is both actionable and bold", () {
      const input = ":@*重要:@*";
      final expected = ColumnNode(
        children: [
          TextNode(
            children: [
              TextSpanNode(text: "重要", emphasis: true, isAction: true),
            ],
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("a bare @ is never markup", () {
      const input1 = "user@example.com";
      expect(
        parser.parse(input1),
        ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "user@example.com")]),
          ],
        ),
      );

      const input2 = "@mention";
      expect(
        parser.parse(input2),
        ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "@mention")]),
          ],
        ),
      );

      const input3 = "メール: a@b.jp";
      expect(
        parser.parse(input3),
        ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "メール: a@b.jp")]),
          ],
        ),
      );
    });

    test(r"\@ inside a cluster is literal", () {
      const input = r":---\@abc";
      final expected = ColumnNode(
        children: [
          TextNode(
            children: [
              TextSpanNode(text: "@abc", sizeOffset: -3),
            ],
          ),
        ],
      );

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });

    test("size is not cleared by :: while action is -- pins the asymmetry", () {
      const input = ":+++大:@押せる::普通";
      final expected = ColumnNode(
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

      final nodes = parser.parse(input);
      expect(nodes, expected);
    });
  });
}
