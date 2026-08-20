import 'package:natural_block/parser.dart';
import 'package:test/test.dart';

void main() {
  final parser = NaturalBlockParser();

  group("Columnの改行トリム検証", () {
    // 期待値: ルートの Column 2重構造を維持
    const expected =
        "ColumnNode(ColumnNode(TextNode(TextSpanNode(text:本文,style:SemanticSymbol.none))))";

    const cases = [
      "|本文|",
      "|\n本文|",
      "|本文\n|",
      "|\n本文\n|",
      "\n|本文|",
      "|本文|\n",
      "\n|本文|\n",
    ];

    for (final (index, input) in cases.indexed) {
      test("Columnの改行トリムパターン : $index", () {
        final nodes = parser.parse(input);
        expect(nodes.toString(), expected);
      });
    }
  });

  group("Rowの改行トリム検証", () {
    // 期待値: ルートの Column 2重構造 + Row 直下は直接 TextNode
    const expected =
        "ColumnNode(ColumnNode(RowNode(TextNode(TextSpanNode(text:左,style:SemanticSymbol.none)) TextNode(TextSpanNode(text:右,style:SemanticSymbol.none)))))";

    const cases = [
      "||左=右||",
      "||\n左=右||",
      "||左=右\n||",
      "||\n左=右\n||",
      "|\n|左=右||",
      "||左=右|\n|",
      "|\n|左=右|\n|",
    ];

    for (final (index, input) in cases.indexed) {
      test("Rowの改行トリムパターン : $index", () {
        final nodes = parser.parse(input);
        expect(nodes.toString(), expected);
      });
    }
  });

  group("境界値・特殊ケースの検証", () {
    test("空のブロックは無視または安全に処理されること", () {
      const input = "|||";
      final nodes = parser.parse(input);
      expect(nodes.children.isEmpty, isTrue);
    });
  });
}
