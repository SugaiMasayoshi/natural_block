import 'package:natural_block/parser.dart';
import 'package:test/test.dart';

void main() {
  final parser = NaturalBlockParser();

  group("SemanticRole & Toggle Parsing Edge Cases", () {
    test("複数スタイルの連続切り替え（ON/OFFの正確性）", () {
      // !赤! 通常 ?青? 通常 %緑% 通常 *太字*
      const input = "!赤!通常?青?通常%緑%通常*太字*";
      const expected =
          "ColumnNode(ColumnNode(TextNode(TextSpanNode(text:赤,style:SemanticRole.danger) TextSpanNode(text:通常,style:SemanticRole.none) TextSpanNode(text:青,style:SemanticRole.info) TextSpanNode(text:通常,style:SemanticRole.none) TextSpanNode(text:緑,style:SemanticRole.success) TextSpanNode(text:通常,style:SemanticRole.none) TextSpanNode(text:太字,style:SemanticRole.emphasis))))";

      final nodes = parser.parse(input);
      expect(nodes.toString(), expected);
    });

    test("スタイルの直上書き（トグルを閉じずに別の記号へ切り替え）", () {
      // !危険から?情報へ切り替え?最後は通常
      const input = "!危険から?情報へ切り替え?最後は通常";
      const expected =
          "ColumnNode(ColumnNode(TextNode(TextSpanNode(text:危険から,style:SemanticRole.danger) TextSpanNode(text:情報へ切り替え,style:SemanticRole.info) TextSpanNode(text:最後は通常,style:SemanticRole.none))))";

      final nodes = parser.parse(input);
      expect(nodes.toString(), expected);
    });

    test("未閉じ記号の処理（文末までスタイルが継続するケース）", () {
      // 通常テキスト!ここから文末までずっと危険状態
      const input = "通常テキスト!ここから文末までずっと危険状態";
      const expected =
          "ColumnNode(ColumnNode(TextNode(TextSpanNode(text:通常テキスト,style:SemanticRole.none) TextSpanNode(text:ここから文末までずっと危険状態,style:SemanticRole.danger))))";

      final nodes = parser.parse(input);
      expect(nodes.toString(), expected);
    });

    test("同一記号の連続（空のトグル処理 / 無効化）", () {
      // !危険!普通!!普通
      // ※ !! は ON になってすぐ OFF になるため、空文字列ノードが作られないか/通常に戻るかの検証
      const input = "!危険!普通!!普通";
      const expected =
          "ColumnNode(ColumnNode(TextNode(TextSpanNode(text:危険,style:SemanticRole.danger) TextSpanNode(text:普通,style:SemanticRole.none) TextSpanNode(text:普通,style:SemanticRole.none))))";

      final nodes = parser.parse(input);
      expect(nodes.toString(), expected);
    });

    test("Rowブロック（=）内でのスタイル独立性の検証", () {
      // |!左は危険!=右は通常|
      const input = "||!左は危険!=右は通常||";
      const expected =
          "ColumnNode(ColumnNode(RowNode(TextNode(TextSpanNode(text:左は危険,style:SemanticRole.danger)) TextNode(TextSpanNode(text:右は通常,style:SemanticRole.none)))))";

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

      const expected =
          "ColumnNode(ColumnNode(TextNode(TextSpanNode(text:警告: システムエラー,style:SemanticRole.danger)) TextNode(TextSpanNode(text:補足事項,style:SemanticRole.emphasis)) RowNode(TextNode(TextSpanNode(text:エラーコード: 500,style:SemanticRole.none)) TextNode(TextSpanNode(text:解決策: ,style:SemanticRole.none) TextSpanNode(text:管理者へ連絡,style:SemanticRole.info))) TextNode(TextSpanNode(text:処理完了,style:SemanticRole.none))))";

      final nodes = parser.parse(input);
      expect(nodes.toString(), expected);
    });
  });
}
