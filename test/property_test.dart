// 【解説】 このファイルは「性質テスト」。
// 【解説】 grid が「この入力はこの木」を確かめるのに対して、こちらは
// 【解説】 「どんな入力でも成り立つこと」を、短い入力の全組み合わせで確かめる。
// 【解説】 文字10種 × 長さ1〜5 = 111,110通りを、そのまま全部読ませる。
// 【解説】 エスケープの性質だけは改行を除く9種なので 66,429通り。
// 【解説】 正しい木が何かは見ない。代わりに、例外を投げないこと、形が崩れない
// 【解説】 こと、入力を決まった形に変えたときの関係が保たれることを見る。

import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'support/grid.dart';

// 【解説】 試す文字。grid と同じ一覧(記号の代表と、普通の文字 'b'、改行)を使う。
// 【解説】 片方にだけ記号を足して網が抜けることがないよう、定義は1箇所に置く。
final _alphabet = gridTokens.values.toList();

// 【解説】 エスケープの性質(4つ目)で使う、改行を除いた文字。
// 【解説】 改行は打ち消せないので、この性質の対象から外す。
final _escapableAlphabet = _alphabet.where((c) => c != '\n').toList();

// 【解説】 [alphabet] の文字で作れる、長さ1〜[maxLength] の文字列を全部返す。
Iterable<String> _strings(List<String> alphabet, int maxLength) sync* {
  var previous = [''];
  for (var length = 1; length <= maxLength; length++) {
    final current = <String>[];
    for (final head in previous) {
      for (final c in alphabet) {
        current.add('$head$c');
      }
    }
    yield* current;
    previous = current;
  }
}

// 【解説】 木のどこかがおかしければ、その説明を返す。問題なければ null。
// 【解説】 ここに書くのは「どんな入力でも成り立つはずのこと」だけ。
String? _brokenShape(NaturalBlockNode node) {
  switch (node) {
    case DocumentNode(:final children):
      for (final child in children) {
        // 【解説】 中身のない列は残らない(空のブロックはノードを作らない)。
        if (child is ColumnNode && child.children.isEmpty) {
          return 'the document holds an empty column';
        }
      }
      return _firstBroken(children);
    case RowNode(:final children):
      // 【解説】 行は必ず2つ以上のセルを持つ(1つなら列のままになる)。
      if (children.length < 2) return 'a row holds ${children.length} cells';
      return _firstBroken(children);
    case ColumnNode(:final children):
      return _firstBroken(children);
    case TextNode(:final children):
      // 【解説】 中身のない文章は残らない。
      if (children.isEmpty) return 'an empty text node';
      return _firstBroken(children);
    case TableNode(:final children):
      // 【解説】 行のない表は残らない。
      if (children.isEmpty) return 'an empty table';
      return _firstBroken(children);
    case TableRowNode(:final children):
      // 【解説】 セルのない行は残らない。
      if (children.isEmpty) return 'an empty table row';
      return _firstBroken(children);
    case TableCellNode(:final children):
      return _firstBroken(children);
    case TextSpanNode(:final text):
      // 【解説】 空の run は残らない。
      if (text.isEmpty) return 'an empty run';
      return _noCarriageReturn(text);
    case RawSpanNode(:final text):
      // 【解説】 中身のない文中の raw 区間は残らない。
      if (text.isEmpty) return 'an empty raw run';
      return _noCarriageReturn(text);
    case RawNode(:final text):
      return _noCarriageReturn(text);
  }
}

String? _firstBroken(List<NaturalBlockNode> nodes) {
  for (final node in nodes) {
    final broken = _brokenShape(node);
    if (broken != null) return broken;
  }
  return null;
}

// 【解説】 入力の CR は読み込み時に \n に直されるので、木には残らない。
String? _noCarriageReturn(String text) =>
    text.contains('\r') ? 'a \\r survived into the tree' : null;

// 【解説】 [source] の各文字を、打ち消しが要るものだけ `\` を付けて返す。
// 【解説】 `|` `^` `~` `` ` `` `:` は文中でも記号なのでいつも付ける。`\` 自身も付ける。
// 【解説】 `<` は先頭(ブロックの始まり)でだけ記号なので、そこだけ付ける。
// 【解説】 `!` は文中では記号でないので、付けると `\` が残ってしまう。付けない。
String _escapeAll(String source) {
  final out = StringBuffer();
  for (var i = 0; i < source.length; i++) {
    final c = source[i];
    final needsEscape =
        c == r'\' ||
        const ['|', '^', '~', '`', ':'].contains(c) ||
        (c == '<' && i == 0);
    if (needsEscape) out.write(r'\');
    out.write(c);
  }
  return out.toString();
}

void main() {
  // 【解説】 全文字列を1度作って、以下のテストで使い回す。
  final sources = _strings(_alphabet, 5).toList();

  test('${sources.length} sources parse without throwing', () {
    // 【解説】 例外(と assert 失敗)が出ないこと。ここが落ちるのは、
    // 【解説】 進まないループや、想定外の位置での読み取り。
    for (final source in sources) {
      expect(
        () => NaturalBlockParser.parse(source),
        returnsNormally,
        reason: source,
      );
    }
  });

  test('every tree keeps its shape', () {
    for (final source in sources) {
      final broken = _brokenShape(NaturalBlockParser.parse(source));
      expect(broken, isNull, reason: '$broken for: $source');
    }
  });

  test('CRLF parses the same as LF', () {
    for (final source in sources) {
      expect(
        NaturalBlockParser.parse(source.replaceAll('\n', '\r\n')),
        NaturalBlockParser.parse(source),
        reason: source,
      );
    }
  });

  test('escaping every symbol gives one plain run of the source', () {
    for (final source in _strings(_escapableAlphabet, 5)) {
      final document = NaturalBlockParser.parse(_escapeAll(source));
      final column = document.children.single as ColumnNode;
      final text = column.children.single as TextNode;
      expect(
        text.children.single,
        TextSpanNode(text: source),
        reason: '${_escapeAll(source)} should be the text $source',
      );
    }
  });
}
