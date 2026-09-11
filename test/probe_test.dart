// 【解説】 他のテストが「何を約束しているか」を教えるのに対し、これは何も
// 【解説】 教えません。仕事は1つ、「意図しない変化の検出」だけ。
// 【解説】
// 【解説】 テストは *書いた主張* を守ります。この探査は *書き忘れた主張* を
// 【解説】 守ります。実際に何度も、他のテストが全部通っているのにここが
// 【解説】 差分を出して間違いを捕まえました(表の寄せが消えていたことがある)。
// 【解説】
// 【解説】 使い方: 挙動を変えるつもりの変更をしたら、ここが落ちます。落ちた
// 【解説】 差分が「変えるつもりだったケースだけ」かを目で確認してから、
// 【解説】   UPDATE_PROBE=1 dart test test/probe_test.dart
// 【解説】 で期待値を更新します。確認せずに更新すると、この網は意味を失います。

import 'dart:io';

import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

/// Every source whose whole tree is pinned, byte for byte.
///
/// Not chosen to cover a rule each -- the numbered tests do that. These are
/// the shapes where a change is most likely to leak somewhere nobody looked:
/// the empty and degenerate ones, the boundaries between two symbols, and
/// the prose that must survive untouched.
const _cases = [
  // Nothing, and nearly nothing.
  '', ' ', '   ', '\n', 'a',

  // One separator, and separators with nothing between them.
  '|', '^', '~', '|^', '^|', '~~', '|~', '~|~',

  // A separator at each end, where "opens a cell" and "ends a block" meet.
  'a|', '|a', 'a^', '^a', 'a^b^', 'a^b^|', 'a^b^|c', '~a^b^~',

  // Blocks and rows.
  'a|b', 'a^b', 'a||b', 'a^^b', 'a^b|c^d', 'left line 1\nleft line 2^right',

  // Alignment markers, including the ones that must stay literal.
  'a|>|b', '|=a|', '|>a|', '|<a|', 'a > b', '=>', '^>', 'List<String>',

  // Tables, in both spellings, and the alignment that belongs to the table.
  '~a^b|c^d~', '~=A^B~', '~A|B|C~', '~A^B|C^D', 'まえ~A^B~あと',
  '|~a^b|', '|~a^b|~', '|~=a^b|', '|~a^b|c^d|~e', '|~a^b|c|', '|~a|', '|~|',
  '|~a^b|~=c', '|~x^`a|b`|y^z|',

  // Newlines: characters, except for the one at each end of a block.
  'a\nb', 'a\n\nb', '\na\n', 'a\n\n\nb', 'a\r\nb', 'a\rb',

  // Verbatim regions, closed and not.
  '`c`', 'a`c`b', '`\nc\n`', 'a`b', '``a`b`c``', 'a``b', '\n`c`\n',
  '文章\n`c`\n続き', 'x^`a|b`|y^z', 'a `b | c', '`a ~ b`',

  // Decoration.
  ':*b:*', ':!d:!p', ':+x', ':::a', ':@u:@',

  // Escapes and paths.
  r'a\|b', r'a\^b', r'a \~ b', r'C:\Users', r'\\server', r':---\%%%',

  // Prose that must come through with no escaping at all.
  'C++', '10-20', '100%', 'you@example.com',

  // The two lines that made verbatim necessary.
  'cat a | grep b | wc -l', 'final x = a == b ? 1 : 2;',
];

String _label(String source) =>
    source.replaceAll('\n', r'\n').replaceAll('\r', r'\r');

void main() {
  test('every pinned source parses to the same tree as last time', () {
    final actual = [
      for (final source in _cases)
        '${_label(source)} => ${NaturalBlockParser.parse(source)}',
    ].join('\n');

    final expected = File('test/probe.expected.txt');

    if (Platform.environment['UPDATE_PROBE'] == '1') {
      expected.writeAsStringSync('$actual\n');
      return;
    }

    expect(
      expected.existsSync(),
      isTrue,
      reason:
          'test/probe.expected.txt is missing. Regenerate it with '
          'UPDATE_PROBE=1 dart test test/probe_test.dart',
    );
    // Line endings are normalised before comparing. A checkout can hand this
    // file back with CRLF -- git does that by default on Windows -- and then
    // every line would differ by a trailing `\r`, which says nothing about
    // any tree. `.gitattributes` keeps it from happening; this keeps it from
    // mattering.
    expect(
      actual.split('\n'),
      expected
          .readAsStringSync()
          .replaceAll('\r\n', '\n')
          .trimRight()
          .split('\n'),
      reason:
          'a source parses differently than it used to. If the change was '
          'intended, check that only the cases you meant to change moved, '
          'then regenerate with UPDATE_PROBE=1.',
    );
  });

  test('no case is listed twice', () {
    // A duplicate would quietly halve what a line of the expectation proves.
    expect(_cases.toSet(), hasLength(_cases.length));
  });
}
