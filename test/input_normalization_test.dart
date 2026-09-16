import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'support/show.dart';

/// One claim per line: the source, and the tree `show()` renders it as.
///
/// That a CRLF document parses exactly like the LF one is checked over every
/// short source by `property_test.dart`; what is left here is the lone CR,
/// the whitespace the parser must keep, and the characters the scanner must
/// not cut apart -- none of which the grid's alphabet contains.
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
  // A lone CR is a line ending too. Nothing else catches this: back when the
  // parser trimmed `[ \t\r\n]` off each end, a stray CR was swept off the
  // ends by accident and one in the middle sat in the text as an invisible
  // control character, reaching the AST, the renderer, and anything the
  // reader copied out.
  _table('line endings', {
    'one\rtwo': r'Col["one\ntwo"]',
    // Pins the order of the two replacements. Doing `\r` first turns every
    // `\r\n` into `\n\n`, which is silent: the document still renders, with
    // a blank line inserted after every line.
    'a\r\nb': r'Col["a\nb"]',
    'text\r\n': 'Col["text"]',
  });

  // Nothing is trimmed. A space the author typed is one they can see and
  // delete, and keeping it is what makes the first and last line behave like
  // every other line -- trimming the document's ends stripped the indent of
  // the first line only.
  _table('whitespace is content', {
    '  text  ': 'Col["  text  "]',
    '    A\n    B': r'Col["    A\n    B"]',
    // U+3000 is how Japanese prose indents; `String.trim` would eat it.
    '　indented': 'Col["　indented"]',
    ' text ': 'Col[" text "]',
    '   ': 'Col["   "]',
    // The one thing that does disappear belongs to the block rather than to
    // any trimming of the source, so a document of only newlines is empty.
    '\n\n': '(empty)',
  });

  // "Against a boundary" means nothing was written in between. A decoration
  // cluster is inline -- it puts nothing on a line of its own -- so a
  // newline followed by one is ordinary content.
  _table('the newline has to touch the boundary to go', {
    'text\n': 'Col["text"]',
    'text\n:*': r'Col["text\n"]',
    'text\n:*|b': r'Col["text\n"], Col["b"]',
  });

  // The scanner indexes UTF-16 code units, so this pins the fact that
  // multi-unit characters survive: every markup character is ASCII, and the
  // units between them are rejoined by `substring`, so a surrogate pair is
  // never split.
  _table('text the scanner must not cut apart', {
    'a\u{1F600}b': 'Col["a\u{1F600}b"]',
    'é': 'Col["é"]',
    'שלום^עולם': 'Row[Col["שלום"], Col["עולם"]]',
  });
}
