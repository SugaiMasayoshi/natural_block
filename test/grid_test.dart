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

// 【解説】 木を1行の文字列にする show()。test/support/show.dart にある。
import 'support/show.dart';

/// One character for each kind of thing the parser tells apart, keyed by the
/// name the grid files show it under.
///
/// The parser decides from the character it is on and the one after it, so
/// every pair of these, in every context, passes through every decision it
/// makes. `!` stands for all decoration characters and `<` for all alignment
/// markers.
// 【解説】 試す記号の一覧。キー = 一覧での表示名、値 = 実際に入力に入れる文字。
// 【解説】 'b' は「普通の文字」の代表。状況の前置きに使う 'a' と区別するため b。
// 【解説】 '!' は装飾の文字(+ - ! % * @)の代表、'<' は寄せ(< = >)の代表。
// 【解説】 '⏎' は改行の表示名で、実際の文字は '\n'。
const _tokens = {
  'b': 'b',
  '|': '|',
  '^': '^',
  '~': '~',
  '`': '`',
  ':': ':',
  '!': '!',
  r'\': r'\',
  '⏎': '\n',
  '<': '<',
};

/// What the source ends with after the pair, so a decision that looks past
/// the second character sees the end of the document.
// 【解説】 Yの側にだけ混ぜる「文書の終わり」。値が空文字なので、X の直後で
// 【解説】 入力が終わる。表示名の '$' は正規表現と同じ「文字列の終わり」。
// 【解説】 _tokens と同じ MapEntry の形にして、下のループで一緒に回せるようにしている。
const _end = MapEntry(r'$', '');

/// Where the pair is written, keyed by the name of its grid file.
///
/// A prefix leaves at most the letter `a` in the tree, so the placeholder
/// substitution below cannot mistake a prefix character for the pair's. The
/// line start is written `|\n` rather than `a\n` for that reason: the `|` ends
/// the block before it and the newline is the one a block drops at its start,
/// so nothing of the prefix reaches the tree. `cluster_escape` is the one
/// exception — its backslash can survive as text, so a `\` in its shapes is
/// the prefix's whenever the pair has no backslash of its own.
///
/// A prefix also puts the pair where a decision reads it as its *next*
/// character: in `cluster_escape` the cluster is sitting on the backslash, so
/// the pair's first character is what it escapes.
// 【解説】 状況(記号2つを書く場所)。キー = 期待値ファイルの名前、
// 【解説】 値 = 記号の前に置く文字列。
// 【解説】 どの前置きも、木に残るのは 'a' だけ(または何も残らない)。だから
// 【解説】 下の置き換えが、前置きの文字を X や Y と取り違えることがない。
// 【解説】 行頭が 'a⏎' でなく '|⏎' なのはそのため。'|' が手前のブロックを閉じ、
// 【解説】 続く改行はブロックの始まりの改行として食べられるので、何も残らない。
// 【解説】 例外は cluster_escape で、前置きの '\' は文字として木に残ることがある。
// 【解説】 その一覧に出る '\' は、組の側に '\' がない限り前置きのもの。
// 【解説】 前置きは「記号2つを、ある判断が“次の1文字”として読む位置」に置く役も
// 【解説】 する。cluster_escape では '\' の上にいるので、X が打ち消される文字になる。
const _contexts = {
  'document': '', // 【解説】 文書の先頭
  'text': 'a', // 【解説】 文の途中
  'row_cell': 'a^', // 【解説】 行のセルの中
  'table_cell': '~', // 【解説】 表のセルの中
  'decorated': ':!a', // 【解説】 装飾が付いた run の中
  'cluster': ':!', // 【解説】 クラスタの中(まだ読み終えていない)
  'cluster_escape': r':!\', // 【解説】 クラスタの中で '\' の上にいる
  'table_row': '~a|', // 【解説】 表の行の始まり(表が | を食べた直後)
  'line_start': '|\n', // 【解説】 行頭
};

/// Every pair in one context, as `pair name -> shape of the tree`.
// 【解説】 1つの状況について、組の名前 → 木の形(1行の文字列)を作る。
Map<String, String> _shapes(String prefix) {
  final shapes = <String, String>{};
  // 【解説】 X は記号10種すべて。
  for (final x in _tokens.entries) {
    // 【解説】 Y は記号10種 + 文書の終わり(_end)の11通り。
    for (final y in [..._tokens.entries, _end]) {
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
  for (final MapEntry(key: name, value: prefix) in _contexts.entries) {
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
