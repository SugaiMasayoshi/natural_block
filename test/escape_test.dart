import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'support/show.dart';

/// One claim per line: the source, and the tree `show()` renders it as.
///
/// `\` engages only where the next character is markup *at that point*, so
/// what needs checking is where that is and how many backslashes survive.
/// The pairs `\|`, `\^`, `\~`, `` \` ``, `\:` and `\\` in every context are
/// the grid's business; so is `\<` at the start of a block.
void _table(String name, Map<String, String> cases) {
  group(name, () {
    cases.forEach((source, expected) {
      test(source.replaceAll('\n', r'\n'), () {
        expect(show(NaturalBlockParser.parse(source)), expected);
      });
    });
  });
}

void main() {
  // Nothing needed escaping, so the backslash is ordinary text. This is what
  // lets a Windows path through untouched.
  _table('only where markup is', {
    r'C:\Users\sugai': r'Col["C:\\Users\\sugai"]',
    r'100\%off': r'Col["100\\%off"]',
    r'\!': r'Col["\\!"]',
    r':---\abc': r'Col["\\abc"{-3}]',
  });

  // A decoration character takes a `:` to become markup, so the bare ones --
  // constant in ordinary prose, Japanese and English alike -- are literal
  // with no escape at all. That is the whole reason for the prefix.
  _table('characters that are never markup', {
    'C++言語、1+1^2': 'Row[Col["C++言語、1+1"], Col["2"]]',
    '-100点、10-20人': 'Col["-100点、10-20人"]',
    'こんにちは!世界': 'Col["こんにちは!世界"]',
    '本当ですか?はい': 'Col["本当ですか?はい"]',
    '進捗100%完了': 'Col["進捗100%完了"]',
    '*太字にしない*': 'Col["*太字にしない*"]',
  });

  // The `:` is what is live, so escaping it leaves the character after it as
  // text -- including a second `:`, which would otherwise reset.
  _table('escaping a `:` token', {
    r'こんにちは\:!世界': 'Col["こんにちは:!世界"]',
    r'サイズ\:+固定': 'Col["サイズ:+固定"]',
    r':!危険\::普通:!': 'Col["危険::普通"{negative}]',
    r':!重要\:!警告:!': 'Col["重要:!警告"{negative}]',
  });

  // Inside a cluster every decoration character is live, which is where a
  // backslash in front of one has work to do: it is the only way to butt
  // literal text starting with one right up against a cluster. The escape
  // also ends the cluster, so one backslash covers the whole run.
  _table('escaping inside a cluster', {
    r':+++100:---\%off': 'Col["100"{+3} "%off"]',
    r':---\%%%off': 'Col["%%%off"{-3}]',
  });

  // How many backslashes there are is the whole claim here, which is why
  // each case is spelled out rather than described.
  _table('the backslash itself', {
    // Without `\\` there is no way to end a cell with a backslash: a single
    // one would escape the separator instead of standing on its own.
    r'\\^B': r'Row[Col["\\"], Col["B"]]',
    r'\\|B': r'Col["\\"], Col["B"]',
    r'\^B': 'Col["^B"]',
    r'\\\^B': r'Col["\\^B"]',
    // Resolving escapes in one place is what makes this work: were the
    // cluster reader to collapse `\\` as well, the backslash the first one
    // left behind would be read as an escape again and swallow the `:`.
    r'\\:*x': r'Col["\\" "x"{*}]',
    // The accepted cost of making `\` escapable: a UNC-style `\\server`
    // reads as `\server`. Being able to write one before a separator is
    // what it buys.
    r'A\\B': r'Col["A\\B"]',
    r'~x^y|\\^z~': r'Col[Table[["x"] / ["y"]; ["\\"] / ["z"]]]',
  });
}
