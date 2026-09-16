// 【解説】 このファイルは grid の穴を2つ埋める。
// 【解説】 grid は装飾を '!'、寄せを '<' の1つで代表させ、値は書かない。だから:
// 【解説】   1. 代表を同じ種類の他の記号に入れ替えても形が変わらないこと(人は読まない)
// 【解説】   2. どの記号がどの値になるかの対応表(人が読む)
// 【解説】 1 が通る限り、grid が代表1つで済ませていることは網羅性を落とさない。

import 'package:natural_block/natural_block.dart';
// 【解説】 記号の定義そのもの。装飾6種と寄せ3種をここから取るので、
// 【解説】 言語に記号を足したらこのテストの対象も自動で増える。
import 'package:natural_block/src/markup.dart';
import 'package:test/test.dart';

import 'support/grid.dart';
import 'support/show.dart';

// 【解説】 grid が使う代表。
const _decorationRepresentative = '!';
const _alignRepresentative = '<';

// 【解説】 '!' と入れ替えられる装飾の記号(+ - % * @)。
// 【解説】 ':' (reset) は値を戻す別の働きで、構文としてもクラスタの開きなので外す。
final _decorationSwaps = DecorationAction.values
    .map((action) => action.char)
    .where((char) => char != _decorationRepresentative && char != clusterChar)
    .toList();

// 【解説】 '<' と入れ替えられる寄せの記号(= >)。
final _alignSwaps = alignMarkers.keys
    .where((char) => char != _alignRepresentative)
    .toList();

// 【解説】 木の形(寄せと装飾の値を書かない1行)。
// 【解説】 [swap] を渡すと、木に残った文字のうち入れ替えた記号を代表に戻す。
// 【解説】 こうしないと、記号が文字として残った入力(例 'a!')で文字列だけが
// 【解説】 食い違い、形が同じかどうかを見られない。
String _shape(String source, {String? swap, String? representative}) => show(
  NaturalBlockParser.parse(source),
  shapeOnly: true,
  rewriteText: swap == null
      ? null
      : (text) => text.replaceAll(swap, representative!),
);

// 【解説】 [source] の中の [representative] を [swaps] の各記号に入れ替えても、
// 【解説】 形が変わらないことを見る。代表を含まない入力は見る必要がない。
void _swapKeepsShape(String source, String representative, List<String> swaps) {
  if (!source.contains(representative)) return;
  final expected = _shape(source);
  for (final swap in swaps) {
    expect(
      _shape(
        source.replaceAll(representative, swap),
        swap: swap,
        representative: representative,
      ),
      expected,
      reason: '$source changes shape when $representative becomes $swap',
    );
  }
}

void main() {
  // 【解説】 grid と同じ入力(状況 × 記号X × 記号Y)を作って、そのすべてで
  // 【解説】 入れ替えを試す。落ちたときは、grid の代表が足りていないという意味。
  test('swapping a representative for its kind keeps every shape', () {
    for (final prefix in gridContexts.values) {
      for (final x in gridTokens.values) {
        for (final y in [...gridTokens.values, '']) {
          final source = '$prefix$x$y';
          _swapKeepsShape(source, _decorationRepresentative, _decorationSwaps);
          _swapKeepsShape(source, _alignRepresentative, _alignSwaps);
        }
      }
    }
  });

  // 【解説】 記号と値の対応表。ここだけは値も書く(shapeOnly を使わない)。
  // 【解説】 grid が見ないのは値だけなので、この十数行がその受け持ち。
  const values = {
    // 【解説】 寄せ。ブロックの始まりと表のセルの始まりで効く。
    '<a': 'Col<["a"]',
    '=a': 'Col=["a"]',
    '>a': 'Col>["a"]',
    '~<a': 'Col[Table[<["a"]]]',
    // 【解説】 大きさは足し引きで積み上がる。
    ':+a': 'Col["a"{+1}]',
    ':++a': 'Col["a"{+2}]',
    ':-a': 'Col["a"{-1}]',
    ':+-a': 'Col["a"]',
    // 【解説】 色合いは同じ記号で none に戻り、別の記号ならそちらになる。
    ':!a': 'Col["a"{negative}]',
    ':%a': 'Col["a"{positive}]',
    ':!!a': 'Col["a"]',
    ':!%a': 'Col["a"{positive}]',
    // 【解説】 強調と操作は入り切りが交互。
    ':*a': 'Col["a"{*}]',
    ':**a': 'Col["a"]',
    ':@a': 'Col["a"{@}]',
    ':@@a': 'Col["a"]',
    // 【解説】 重ね付けと、':' での戻し(大きさは残る)。
    ':+!*@a': 'Col["a"{+1 negative * @}]',
    ':+!*@:a': 'Col["a"{+1}]',
  };
  values.forEach((source, expected) {
    test('value: $source', () {
      expect(show(NaturalBlockParser.parse(source)), expected);
    });
  });
}
