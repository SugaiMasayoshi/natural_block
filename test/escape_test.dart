import 'package:natural_block/node/node.dart';
import 'package:natural_block/parser.dart';
import 'package:natural_block/symbol/semantic_symbol.dart';
import 'package:test/test.dart';

void main() {
  final parser = NaturalBlockParser();

  group("エスケープ処理の検証", () {
    group("レイアウト記号のエスケープ", () {
      test("パイプ記号（\\|）がColumn区切りにならず文字としてパースされること", () {
        const input = r"|A\|B|";
        final expected = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "A|B")]),
          ],
        ).toString();

        final nodes = parser.parse(input);
        expect(nodes.toString(), expected);
      });

      test("イコール記号（\\=）がRow区切りにならず単一のテキストとしてパースされること", () {
        const input = r"左\=右";
        final expected = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "左=右")]),
          ],
        ).toString();

        final nodes = parser.parse(input);
        expect(nodes.toString(), expected);
      });
    });

    group("文字サイズ記号のエスケープ", () {
      test("プラス記号（\\+）がサイズ変更にならず文字としてパースされること", () {
        const input = r"C\+\+言語";
        final expected = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "C++言語", sizeOffset: 0)]),
          ],
        ).toString();

        final nodes = parser.parse(input);
        expect(nodes.toString(), expected);
      });

      test("マイナス記号（\\-）がサイズ変更にならず文字としてパースされること", () {
        const input = r"\-100点";
        final expected = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "-100点", sizeOffset: 0)]),
          ],
        ).toString();

        final nodes = parser.parse(input);
        expect(nodes.toString(), expected);
      });
    });

    group("セマンティック装飾記号のエスケープ", () {
      test("感嘆符（\\!）がdanger装飾にならず文字としてパースされること", () {
        const input = r"こんにちは\!世界";
        final expected = ColumnNode(
          children: [
            TextNode(
              children: [
                TextSpanNode(text: "こんにちは!世界", style: SemanticSymbol.none),
              ],
            ),
          ],
        ).toString();

        final nodes = parser.parse(input);
        expect(nodes.toString(), expected);
      });

      test("疑問符（\\?）がinfo装飾にならず文字としてパースされること", () {
        const input = r"本当ですか\?はい";
        final expected = ColumnNode(
          children: [
            TextNode(
              children: [
                TextSpanNode(text: "本当ですか?はい", style: SemanticSymbol.none),
              ],
            ),
          ],
        ).toString();

        final nodes = parser.parse(input);
        expect(nodes.toString(), expected);
      });

      test("パーセント（\\%）がsuccess装飾にならず文字としてパースされること", () {
        const input = r"進捗100\%完了";
        final expected = ColumnNode(
          children: [
            TextNode(
              children: [
                TextSpanNode(text: "進捗100%完了", style: SemanticSymbol.none),
              ],
            ),
          ],
        ).toString();

        final nodes = parser.parse(input);
        expect(nodes.toString(), expected);
      });

      test("アスタリスク（\\*）がemphasis装飾にならず文字としてパースされること", () {
        const input = r"\*太字にしない\*";
        final expected = ColumnNode(
          children: [
            TextNode(
              children: [
                TextSpanNode(text: "*太字にしない*", style: SemanticSymbol.none),
              ],
            ),
          ],
        ).toString();

        final nodes = parser.parse(input);
        expect(nodes.toString(), expected);
      });
    });

    group("装飾ブロック内でのエスケープ（トグル終了の防止）", () {
      test("装飾ブロック内部でエスケープされた記号がトグル終了にならないこと", () {
        const input = r"!重要\!警告!";
        final expected = ColumnNode(
          children: [
            TextNode(
              children: [
                TextSpanNode(text: "重要!警告", style: SemanticSymbol.danger),
              ],
            ),
          ],
        ).toString();

        final nodes = parser.parse(input);
        expect(nodes.toString(), expected);
      });
    });
  });
}
