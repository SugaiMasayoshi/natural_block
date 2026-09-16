// 【解説】 このファイルは「組み合わせ表(grid)」のテスト。
// 【解説】 やることは3つだけ:
// 【解説】   1. 状況 × 記号X × 記号Y の全組み合わせの入力を作ってパースする
// 【解説】   2. できた木を1行の文字列にして、同じ形になった組をまとめる
// 【解説】   3. その一覧を期待値ファイル(test/grid/<状況>.txt)と比べる
// 【解説】 パーサは「今の文字と次の1文字」だけで判断するので、記号2つの全組を
// 【解説】 通せば、判断の場所を一度ずつ全部通ったことになる。
// 【解説】 状況ごとに1ファイル。同じ形になった組をまとめて書き出す。

// 【解説】 ファイルの読み書き(期待値ファイル)と環境変数(UPDATE_GRID)に使う。
import 'dart:io';

// 【解説】 パーサ本体。NaturalBlockParser.parse を呼ぶ。
import 'package:natural_block/natural_block.dart';
// 【解説】 test / expect などのテストの仕組み。
import 'package:test/test.dart';

// 【解説】 試す記号(gridTokens)と状況(gridContexts)の一覧。
// 【解説】 性質テストと代表のテストも同じ一覧を使うので、別のファイルに置いている。
import 'support/grid.dart';
// 【解説】 木を1行の文字列にする show()。test/support/show.dart にある。
import 'support/show.dart';

/// What the source ends with after the pair, so a decision that looks past
/// the second character sees the end of the document.
// 【解説】 Yの側にだけ混ぜる「文書の終わり」。値が空文字なので、X の直後で
// 【解説】 入力が終わる。表示名の '$' は正規表現と同じ「文字列の終わり」。
// 【解説】 gridTokens と同じ MapEntry の形にして、下のループで一緒に回せるようにしている。
const _end = MapEntry(r'$', '');

/// Every pair in one context, as `pair name -> shape of the tree`.
// 【解説】 1つの状況について、組の名前 → 木の形(1行の文字列)を作る。
Map<String, String> _shapes(String prefix) {
  final shapes = <String, String>{};
  // 【解説】 X は記号10種すべて。
  for (final x in gridTokens.entries) {
    // 【解説】 Y は記号10種 + 文書の終わり(_end)の11通り。
    for (final y in [...gridTokens.entries, _end]) {
      // 【解説】 前置き + X + Y を実際にパースする。これが1組ぶんの入力。
      final tree = NaturalBlockParser.parse('$prefix${x.value}${y.value}');
      // 【解説】 木を1行の文字列にする。
      shapes['${x.key}${y.key}'] = show(
        tree,
        // 【解説】 shapeOnly: 寄せと装飾の値は書かず、形だけにする。
        // 【解説】 値の確認は別のテスト(記号と値の対応表)が受け持つ。
        shapeOnly: true,
        // 【解説】 木の中に残った文字のうち、X の文字を 'X'、Y の文字を 'Y' に
        // 【解説】 置き換える。こうすると bb と !! のように、違う記号でも同じ形に
        // 【解説】 なる組が同じ文字列になり、1グループにまとまる。
        rewriteText: (s) => [
          // 【解説】 s.split('') で1文字ずつに分け、1文字ずつ見て置き換える。
          for (final c in s.split(''))
            c == x.value ? 'X' : (c == y.value ? 'Y' : c),
        ].join(),
      );
    }
  }
  return shapes;
}

/// The shapes grouped by the shape itself, in the order the pairs were tried.
// 【解説】 同じ形になった組をまとめて、「形」の行と字下げした「組の一覧」にする。
String _groups(Map<String, String> shapes) {
  final groups = <String, List<String>>{};
  // 【解説】 Dart の Map は入れた順を覚えるので、並びは X の順になる。
  for (final MapEntry(key: pair, value: shape) in shapes.entries) {
    groups.putIfAbsent(shape, () => []).add(pair);
  }
  return [
    for (final MapEntry(key: shape, value: pairs) in groups.entries)
      '$shape\n    ${pairs.join('  ')}',
  ].join('\n');
}

void main() {
  // 【解説】 状況ごとにテストを1つ作る。
  for (final MapEntry(key: name, value: prefix) in gridContexts.entries) {
    test('grid: $name', () {
      // 【解説】 見出しに前置きを書く(改行は \n と書く)。そのあとにグループ。
      final actual =
          '# prefix: "${prefix.replaceAll('\n', r'\n')}"\n'
          '${_groups(_shapes(prefix))}';
      // 【解説】 比べる相手(期待値ファイル)。
      final file = File('test/grid/$name.txt');

      // 【解説】 UPDATE_GRID=1 で走らせたときは、比べずに期待値を書き出す。
      // 【解説】 規則を変えたら、差分を読んでからこれで作り直す(probe と同じ運用)。
      if (Platform.environment['UPDATE_GRID'] == '1') {
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('$actual\n');
        return;
      }

      // 【解説】 ふだんはファイルの中身と比べる。Windows の clone で CRLF に
      // 【解説】 なっていても落ちないよう、LF に直し、末尾の空白を落としてから比べる。
      expect(
        file.readAsStringSync().replaceAll('\r\n', '\n').trimRight(),
        actual,
        reason:
            'a pair parses differently than it used to. If intended, read '
            'the diff, then regenerate with UPDATE_GRID=1.',
      );
    });
  }
}
