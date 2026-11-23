import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'support/show.dart';

/// The syntax as it is published: a few representative sources per
/// construct, each with the tree `show()` renders it as. Everything finer
/// than this -- how each pair of characters behaves wherever it can be
/// written -- is the grid's.
void _table(String name, Map<String, String> cases) {
  group(name, () {
    cases.forEach((source, expected) {
      test(source.replaceAll('\n', r'\n').replaceAll('\r', r'\r'), () {
        expect(show(NaturalBlockParser.parse(source)), expected);
      });
    });
  });
}

void main() {
  _table('blocks and rows', {
    '上\n下': r'Col["上\n下"]',
    '上\n\n下': r'Col["上\n\n下"]',
    '^左^右^': 'Row[Col["左"], Col["右"]]',
    '^左^^右^': 'Row[Col["左"], Cell[], Col["右"]]',
    '^左^右^^': 'Row[Col["左"], Col["右"], Cell[]]',
    '^左\n2行目^右^': r'Row[Col["左\n2行目"], Col["右"]]',
    '^左\n^右^': 'Row[Col["左"], Col["右"]]',
    '^a^b': 'Row[Col["a"], Col["b"]]',
    '^注意^': 'Row[Col["注意"]]',
    '^^': 'Row[Cell[]]',
    '前の行\n^A^B^\n次の行': 'Col["前の行"], Row[Col["A"], Col["B"]], Col["次の行"]',
    'a ^ b | c': 'Col["a ^ b | c"]',
  });

  _table('blank lines', {
    '上\n\n=下': r'Col["上\n"], Col=["下"]',
    '~\n^A^\n~\n\n=下': 'Col[Table[["A"]], ""], Col=["下"]',
    '^A^\n\n=下': 'Row[Col["A"]], Col[""], Col=["下"]',
    '^A^\n\n^B^': 'Row[Col["A"]], Col[""], Row[Col["B"]]',
    '^A^\n\n\n=下': r'Row[Col["A"]], Col["\n"], Col=["下"]',
    '^~\n^A^\n~\n\n|^': 'Row[Cell[Col[Table[["A"]], ""], Space1]]',
  });

  _table('spacers', {
    '|\n=タイトル\n|': 'Space1, Col=["タイトル"], Space1',
    '本文\n|\n>出典': 'Col["本文"], Space1, Col>["出典"]',
    '||\n=タイトル\n|': 'Space2, Col=["タイトル"], Space1',
    '|  \n本文': 'Space1, Col["本文"]',
    '本文\n\n|\n\n出典': r'Col["本文\n"], Space1, Col["\n出典"]',
    '^画像^|\n説明\n|^': 'Row[Col["画像"], Cell[Space1, Col["説明"], Space1]]',
    '^=上\n|\n下^': 'Row[Cell[Col=["上"], Space1, Col=["下"]]]',
    '|本文': 'Col["|本文"]',
    '^画像^|説明|^': 'Row[Col["画像"], Col["|説明|"]]',
    '~\n^|^\n~': 'Col[Table[["|"]]]',
    r'\|': 'Col["|"]',
  });

  _table('alignment', {
    '=見出し\n本文': r'Col=["見出し\n本文"]',
    '=見出し\n\n本文': r'Col=["見出し\n\n本文"]',
    '=見出し\n\n<本文': r'Col=["見出し\n"], Col<["本文"]',
    '本文\n=\n見出し': r'Col["本文"], Col=["\n見出し"]',
    '本文\n\n=見出し': r'Col["本文\n"], Col=["見出し"]',
    '=中央\n>右': 'Col=["中央"], Col>["右"]',
    '^<品名^=数量^>価格^': 'Row[Col<["品名"], Col=["数量"], Col>["価格"]]',
    '=^A^B^>C^': 'Row[Col=["A"], Col=["B"], Col>["C"]]',
    '<>a': 'Col<[">a"]',
    r'\=> x': 'Col["=> x"]',
    'a\n\\> b': r'Col["a\n> b"]',
    'a > b': 'Col["a > b"]',
  });

  group('tables', () {
    _table('structure', {
      '~\n^A^B^\n^C^D^\n~': 'Col[Table[["A"] / ["B"]; ["C"] / ["D"]]]',
      '~\nA^B^\nC^D^\n~': 'Col[Table[["A"] / ["B"]; ["C"] / ["D"]]]',
      '~^A^B^\n~': 'Col[Table[["A"] / ["B"]]]',
      '~\n^A^B^\n\n^C^D^\n~': 'Col[Table[["A"] / ["B"]; ["C"] / ["D"]]]',
      '~\n^^\n^A^\n~': 'Col[Table[[]; ["A"]]]',
      '~\n^A\n2行目^B^\n~': r'Col[Table[["A\n2行目"] / ["B"]]]',
      '~\nA^B\nC^D\n~': r'Col[Table[["A"] / ["B\nC"] / ["D"]]]',
      '~\n<品名^>価格^\nりんご^150^\n~':
          'Col[Table[<["品名"] / >["価格"]; ["りんご"] / ["150"]]]',
      '前の行\n~\n^A^B^\n~\n次の行': 'Col["前の行", Table[["A"] / ["B"]], "次の行"]',
      '^~\n^A^B^\n~^右^': 'Row[Col[Table[["A"] / ["B"]]], Col["右"]]',
      '^左\n~\n^A^B^\n~\n^右^': 'Row[Col["左", Table[["A"] / ["B"]]], Col["右"]]',
      '=~\n^A^B^\n~': 'Col=[Table[["A"] / ["B"]]]',
      '~\n^10~20^人^\n~': 'Col[Table[["10~20"] / ["人"]]]',
      '~\n注意': 'Col[Table[["注意"]]]',
    });

    test('a column takes its alignment from the first row that has it', () {
      final block = NaturalBlockParser.parse('~\nA^>B^\nC^<D^\nE^F^=G^\n~')
          .children;
      final table = (block.single as ColumnNode).children.single as TableNode;

      expect(table.columns, [
        HorizontalAlign.unstated,
        HorizontalAlign.end,
        HorizontalAlign.center,
      ]);
    });
  });

  _table('raw regions', {
    '比較は`a == b`です': 'Col["比較は" raw"a == b" "です"]',
    '```\ncat a | grep b\n```': 'Col[Raw"cat a | grep b"]',
    '```\n\ncode\n\n```': r'Col[Raw"\ncode\n"]',
    '`make で実行\n次': r'Col[raw"make で実行" "\n次"]',
    '``a `b` c``': 'Col[raw"a `b` c"]',
    'x `a``b` y': 'Col["x " raw"a``b" " y"]',
    '```\nx\n``` c': 'Col[Raw"x", " c"]',
    '```dart\nx\n```': r'Col[Raw"dart\nx"]',
    '`make` で実行': 'Col[raw"make" " で実行"]',
    ':+```\nx\n```': 'Col[Raw"x"{+1}]',
    '=:!*```\nx\n```': 'Col=[Raw"x"{negative *}]',
    ':+a\n```\nx\n```': 'Col["a"{+1}, Raw"x"]',
    '^:+```\nx\n```^': 'Row[Col[Raw"x"{+1}]]',
    '^```\nx\n```^```\ny\n```^': 'Row[Col[Raw"x"], Col[Raw"y"]]',
    '```\nx': 'Col[Raw"x"]',
    'a `x\nb': r'Col["a " raw"x" "\nb"]',
    'a ```\nb': r'Col["a \nb"]',
    'a\n```\nx\n```': 'Col["a", Raw"x"]',
    ':++*a `x` b': 'Col["a "{+2 *} raw"x"{+2 *} " b"{+2 *}]',
    ':+`x` b': 'Col[raw"x"{+1} " b"{+1}]',
    'a `b | c': 'Col["a " raw"b | c"]',
    r'a \` b': 'Col["a ` b"]',
  });

  _table('decoration', {
    ':+a': 'Col["a"{+1}]',
    ':+++a': 'Col["a"{+3}]',
    ':-a': 'Col["a"{-1}]',
    ':!a': 'Col["a"{negative}]',
    ':%a': 'Col["a"{positive}]',
    ':!%a': 'Col["a"{positive}]',
    ':*a': 'Col["a"{*}]',
    ':@a': 'Col["a"{@}]',
    ':!赤:!黒': 'Col["赤"{negative} "黒"]',
    ':!*a': 'Col["a"{negative *}]',
    ':!:*a': 'Col["a"{*}]',
    ':+!*@::a': 'Col["a"{+1}]',
    ':@https://example.com:@ を参照': 'Col["https://example.com"{@} " を参照"]',
    'C++ 10-20 100% you@example.com': 'Col["C++ 10-20 100% you@example.com"]',
    '10~20人、月~金': 'Col["10~20人、月~金"]',
    '^:++大^右^': 'Row[Col["大"{+2}], Col["右"]]',
    ':!赤\n黒': r'Col["赤"{negative} "\n黒"]',
    ':++見出し\n\n=本文': r'Col["見出し"{+2} "\n"], Col=["本文"]',
  });

  _table('escapes', {
    r'\^B^': 'Col["^B^"]',
    r'A\^B': r'Col["A\\^B"]',
    r'^A\^B^': 'Row[Col["A^B"]]',
    r'^\\^B^': r'Row[Col["\\"], Col["B"]]',
    r'\~/.bashrc': 'Col["~/.bashrc"]',
    r'10\~20': r'Col["10\\~20"]',
    r'C:\Users\you': r'Col["C:\\Users\\you"]',
    r':---\%off': 'Col["%off"{-3}]',
    r'100\%': r'Col["100\\%"]',
  });

  _table('newlines and whitespace', {
    'a\nb': r'Col["a\nb"]',
    'a\r\nb': r'Col["a\nb"]',
    'text\n': 'Col["text"]',
    'text\n\n': r'Col["text\n"]',
    '  text  ': 'Col["  text  "]',
  });
}
