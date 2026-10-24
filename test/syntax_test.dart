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
    '上|下': 'Col["上"], Col["下"]',
    '左^右': 'Row[Col["左"], Col["右"]]',
    '左^^右': 'Row[Col["左"], Col[], Col["右"]]',
    '左||右': 'Col["左"], Col["右"]',
    '左^右^': 'Row[Col["左"], Col["右"], Col[]]',
    '|\n本文\n|': 'Col["本文"]',
    '前の行\n|A^B|': 'Col["前の行"], Row[Col["A"], Col["B"]]',
    '前の行\nA^B|': r'Row[Col["前の行\nA"], Col["B"]]',
  });

  _table('alignment', {
    '|<品名^=数量^>価格|': 'Row[Col<["品名"], Col=["数量"], Col>["価格"]]',
    '<見出し': 'Col<["見出し"]',
    '|<>a': 'Col<[">a"]',
    r'\=> x': 'Col["=> x"]',
    'a > b': 'Col["a > b"]',
  });

  group('tables', () {
    _table('structure', {
      '~A^B|C^D~': 'Col[Table[["A"] / ["B"]; ["C"] / ["D"]]]',
      '~A^B|C^D~E^F':
          'Row[Col[Table[["A"] / ["B"]; ["C"] / ["D"]], "E"], Col["F"]]',
      '~A^B|注記|C^D~': 'Col[Table[["A"] / ["B"]; ["注記"]; ["C"] / ["D"]]]',
      '~注意~': 'Col[Table[["注意"]]]',
      '|=~A^B~': 'Col=[Table[["A"] / ["B"]]]',
      '~A^>B|C^<D|E^F~':
          'Col[Table[["A"] / >["B"]; ["C"] / <["D"]; ["E"] / ["F"]]]',
    });

    test('a column takes its alignment from the first row that has it', () {
      final block = NaturalBlockParser.parse('~A^>B|C^<D|E^F^=G~').children;
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
    '`\ncat a | grep b\n`': 'Col[Raw"cat a | grep b"]',
    '`\n\ncode\n\n`': r'Col[Raw"\ncode\n"]',
    '``a `b` c``': 'Col[raw"a `b` c"]',
    'x `a``b` y': 'Col["x " raw"a``b" " y"]',
    'a `\nb\n` c': 'Col["a ", Raw"b", " c"]',
    ':!a`x\ny`b': r'Col["a"{negative}, Raw"x\ny", "b"]',
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
    ':++大^右': 'Row[Col["大"{+2}], Col["右"]]',
    ':!赤\n黒': r'Col["赤\n"{negative} "黒"]',
  });

  _table('escapes', {
    r'A\|B': 'Col["A|B"]',
    r'\\^B': r'Row[Col["\\"], Col["B"]]',
    r'C:\Users\you': r'Col["C:\\Users\\you"]',
    r':---\%off': 'Col["%off"{-3}]',
    r'100\%': r'Col["100\\%"]',
  });

  _table('newlines and whitespace', {
    'a\nb': r'Col["a\nb"]',
    'a\r\nb': r'Col["a\nb"]',
    'text\n': 'Col["text"]',
    '  text  ': 'Col["  text  "]',
  });
}
