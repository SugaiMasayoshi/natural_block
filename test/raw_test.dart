import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'support/show.dart';

/// One claim per line: the source, and the tree `show()` renders it as.
///
/// `Raw"..."` is a region standing on a line of its own, `raw"..."` one
/// written inside a sentence. What needs checking here is what a region
/// swallows and where it ends -- all of it longer than the two symbols the
/// grid reaches.
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
  // Why the construct exists: the characters a layout language wants are
  // what code is made of. `=` used to separate cells, which made
  // `final x = a == b ? 1 : 2;` a four-cell row; moving that to `^` took
  // the headline argument away, but `^` is not absent from code either.
  _table('code survives', {
    'final x = a == b ? 1 : 2;': 'Col["final x = a == b ? 1 : 2;"]',
    'assert(2^10 == 1024)': 'Row[Col["assert(2"], Col["10 == 1024)"]]',
    '`assert(2^10 == 1024)`': 'Col[Raw"assert(2^10 == 1024)"]',
    'cat file.txt | grep foo | wc -l':
        'Col["cat file.txt "], Col[" grep foo "], Col[" wc -l"]',
    '`cat file.txt | grep foo | wc -l`':
        'Col[Raw"cat file.txt | grep foo | wc -l"]',
    r'`:*bold:* and \| and :@action:@ and |a^b| and :---%%%`':
        r'Col[Raw":*bold:* and \\| and :@action:@ and |a^b| and :---%%%"]',
  });

  // One construct, and where it is written is what the tree records. A
  // marker built on `|` could never have been inline, since `|` always
  // breaks a block.
  _table('anywhere', {
    '`code`': 'Col[Raw"code"]',
    '比較は`a == b`です': 'Col["比較は" raw"a == b" "です"]',
    'before`\ncode\n`after': 'Col["before" raw"code" "after"]',
    ':*bold:*and`code`and plain': 'Col["bold"{*} "and" raw"code" "and plain"]',
    // Not possible with a `|`-based marker: a cell cannot hold a block.
    '~x^`a|b`|y^z~': 'Col[Table[["x"] / [raw"a|b"]; ["y"] / ["z"]]]',
  });

  // Every level that stops at a boundary has to know about regions, or a
  // multi-line one would be cut into a piece per line with nothing left to
  // rejoin it. `cursor.atLineStart` is the single answer they all ask for.
  _table('fences', {
    '`\nif (x) {\n  y();\n}\n`': r'Col[Raw"if (x) {\n  y();\n}"]',
    '`\ncat a | grep b\n`': 'Col[Raw"cat a | grep b"]',
    // The newline against each fence belongs to that fence -- one of them,
    // so a blank line inside the region survives.
    '`\n\ncode\n\n`': r'Col[Raw"\ncode\n"]',
    // The same rule from the outside: miss it and the text after a code
    // block opens with a blank line nobody wrote.
    '文章\n`code`\n続き': 'Col["文章", Raw"code", "続き"]',
    // How the language quotes its own syntax.
    '``a `b` c``': 'Col[Raw"a `b` c"]',
  });

  // The fence alone settles whether a region opens -- nothing searches ahead
  // for a closer -- so what has been read is always enough to know where you
  // are. The cost is that a stray backtick swallows the rest of the
  // document, separators included.
  _table('an unclosed fence runs to the end of the document', {
    'a `b': 'Col["a " raw"b"]',
    'a `b | c': 'Col["a " raw"b | c"]',
    '`\ncode\n': 'Col[Raw"code"]',
  });

  // If an escaped fence were read as opening a region, this `|` would be
  // swallowed instead of separating.
  _table('escaping the fence', {r'a \` b | c': 'Col["a ` b "], Col[" c"]'});

  // Normalization happens before scanning, so line endings do not
  // round-trip through a region. Pinned so the limit is stated.
  _table('line endings', {'`a\r\nb`': r'Col[Raw"a\nb"]'});
}
