import 'package:natural_block/node/node.dart';
import 'package:natural_block/parser.dart';
import 'package:natural_block/symbol/semantic_symbol.dart';
import 'package:test/test.dart';

void main() {
  final parser = Parser();

  group("SemanticSymbol & Toggle Parsing Edge Cases", () {
    test("複数スタイルの連続切り替え", () {
      // !赤! 通常 ?青? 通常 %緑% 通常 *太字*
      const input = "!赤!通常?青?通常%緑%通常*太字*";
      final expected = ColumnNode(
        children: [
          TextNode(
            children: [
              TextSpanNode(text: "赤", style: SemanticSymbol.danger),
              TextSpanNode(text: "通常"),
              TextSpanNode(text: "青", style: SemanticSymbol.info),
              TextSpanNode(text: "通常"),
              TextSpanNode(text: "緑", style: SemanticSymbol.success),
              TextSpanNode(text: "通常"),
              TextSpanNode(text: "太字", style: SemanticSymbol.emphasis),
            ],
          ),
        ],
      ).toString();

      final nodes = parser.parse(input);
      expect(nodes.toString(), expected);
    });

    test("スタイルの直上書き", () {
      // !危険から?情報へ切り替え?最後は通常
      const input = "!危険から?情報へ切り替え?最後は通常";
      final expected = ColumnNode(
        children: [
          TextNode(
            children: [
              TextSpanNode(text: "危険から", style: SemanticSymbol.danger),
              TextSpanNode(text: "情報へ切り替え", style: SemanticSymbol.info),
              TextSpanNode(text: "最後は通常"),
            ],
          ),
        ],
      ).toString();

      final nodes = parser.parse(input);
      expect(nodes.toString(), expected);
    });

    test("未閉じ記号の処理", () {
      // 通常テキスト!ここから文末までずっと危険状態
      const input = "通常テキスト!ここから文末までずっと危険状態";
      final expected = ColumnNode(
        children: [
          TextNode(
            children: [
              TextSpanNode(text: "通常テキスト"),
              TextSpanNode(
                text: "ここから文末までずっと危険状態",
                style: SemanticSymbol.danger,
              ),
            ],
          ),
        ],
      ).toString();

      final nodes = parser.parse(input);
      expect(nodes.toString(), expected);
    });

    test("同一記号の連続", () {
      // !危険!普通!!普通
      // ※ !! は ON になってすぐ OFF になるため、空文字列ノードが作られないか/通常に戻るかの検証
      const input = "!危険!普通!!普通";
      final expected = ColumnNode(
        children: [
          TextNode(
            children: [
              TextSpanNode(text: "危険", style: SemanticSymbol.danger),
              TextSpanNode(text: "普通"),
              TextSpanNode(text: "普通"),
            ],
          ),
        ],
      ).toString();

      final nodes = parser.parse(input);
      expect(nodes.toString(), expected);
    });

    test("Rowブロック内でのスタイル独立性の検証", () {
      // |!左は危険!=右は通常|
      const input = "||!左は危険!=右は通常||";
      final expected = ColumnNode(
        children: [
          RowNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(text: "左は危険", style: SemanticSymbol.danger),
                ],
              ),
            ],
          ),
          RowNode(
            children: [
              TextNode(children: [TextSpanNode(text: "右は通常")]),
            ],
          ),
        ],
      ).toString();

      final nodes = parser.parse(input);
      expect(nodes.toString(), expected);
    });

    test("複雑なマルチブロック＆複数スタイルの結合テスト", () {
      const input = """
|
!警告: システムエラー!
*補足事項*
|エラーコード: 500=解決策: ?管理者へ連絡?|
処理完了
|""";

      final expected = ColumnNode(
        children: [
          TextNode(
            children: [
              TextSpanNode(text: "警告: システムエラー", style: SemanticSymbol.danger),
            ],
          ),
          TextNode(
            children: [
              TextSpanNode(text: "補足事項", style: SemanticSymbol.emphasis),
            ],
          ),
          RowNode(
            children: [
              TextNode(children: [TextSpanNode(text: "エラーコード: 500")]),
            ],
          ),
          RowNode(
            children: [
              TextNode(
                children: [
                  TextSpanNode(text: "解決策: "),
                  TextSpanNode(text: "管理者へ連絡", style: SemanticSymbol.info),
                ],
              ),
            ],
          ),
          TextNode(children: [TextSpanNode(text: "処理完了")]),
        ],
      ).toString();

      final nodes = parser.parse(input);
      expect(nodes.toString(), expected);
    });
  });
}
