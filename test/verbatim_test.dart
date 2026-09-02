import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  TextNode line(String text) =>
      TextNode(children: [TextSpanNode(text: text)]);

  VerbatimNode only(String source) =>
      NaturalBlockParser.parse(source).children.single as VerbatimNode;

  group('why this exists: code survives', () {
    test('a line of code is not split into cells', () {
      // Measured before verbatim existed: this became a four-cell row,
      // because `=` and `==` are what code is made of.
      const code = 'final x = a == b ? 1 : 2;';

      expect(NaturalBlockParser.parse(code).children.single, isA<RowNode>());
      expect(only('|`$code|`').text, code);
    });

    test('a shell pipeline is not split into blocks', () {
      const code = 'cat file.txt | grep foo | wc -l';

      expect(NaturalBlockParser.parse(code).children, hasLength(3));
      expect(only('|`$code|`').text, code);
    });

    test('nothing inside is markup: no decoration, no escapes', () {
      const raw = r':*bold:* and \| and :@action:@ and :---%%%';

      expect(only('|`$raw|`').text, raw);
    });
  });

  group('fences', () {
    test('the newline against each fence belongs to the fence', () {
      // So a fence can sit on its own line, the way a code block is
      // normally written.
      expect(only('|`\ncat a | grep b\n|`').text, 'cat a | grep b');
    });

    test('only one newline goes at each end', () {
      // Defined as "that newline is part of the marker" rather than "trim a
      // blank line", which is what makes this unambiguous.
      expect(only('|`\n\ncode\n\n|`').text, '\ncode\n');
    });

    test('written inline, the content is exactly what was typed', () {
      expect(only('|`code|`').text, 'code');
    });

    test('a longer fence lets the region quote the marker itself', () {
      // Without this the language could not document its own syntax --
      // the problem Markdown solves with variable-length fences.
      final node = only('|``\n|`not a close|`\n|``');

      expect(node.text, '|`not a close|`');
      expect(node.isTerminated, isTrue);
    });

    test('a short fence does not close a long one', () {
      expect(only('|```a|`b|``c|```').text, 'a|`b|``c');
    });
  });

  group('where it can appear', () {
    test('text before and after stays its own block', () {
      final document = NaturalBlockParser.parse('before|`raw|`after');

      expect(document.children, [
        line('before'),
        VerbatimNode(text: 'raw'),
        line('after'),
      ]);
    });

    test('a backtick after `=` is ordinary text, not a region', () {
      // Same restriction the table marker has, for the same reason: a cell
      // holds only lines, so a verbatim region could not be one.
      final row = NaturalBlockParser.parse('A=`B|').children.single as RowNode;

      expect(row.children[1].children.single, line('`B'));
    });

    test('an escaped separator leaves the marker as text', () {
      expect(
        NaturalBlockParser.parse(r'\|`still text'),
        DocumentNode(children: [line('|`still text')]),
      );
    });

    test('a bare backtick with no separator before it is ordinary text', () {
      expect(
        NaturalBlockParser.parse('a `quoted` word'),
        DocumentNode(children: [line('a `quoted` word')]),
      );
    });
  });

  group('interaction with the rest of the language', () {
    test('a region ends an open table, and the table comes first', () {
      // A verbatim region is not a row. Flushing has to happen before the
      // region is added, or the table would land after it.
      final document = NaturalBlockParser.parse('|~A=B|C=D||`code|`');

      expect(document.children.first, isA<TableNode>());
      expect(document.children.last, VerbatimNode(text: 'code'));
    });

    test('an empty region contributes no node', () {
      // Matching the rule that an empty block contributes nothing.
      expect(
        NaturalBlockParser.parse('A|`|`B'),
        DocumentNode(children: [line('A'), line('B')]),
      );
    });

    test('no alignment marker is read after the fence', () {
      // The character right after the marker is content, always. That is
      // why verbatim takes no alignment: reading a cluster first would make
      // content starting with `^` unwritable.
      expect(only('|`^centered?|`').text, '^centered?');
    });

    test('an alignment on a later block is not affected', () {
      final document = NaturalBlockParser.parse('|`raw|`|^after');

      expect(document.children.first, isA<VerbatimNode>());
      expect((document.children.last as ColumnNode).align, BlockAlign.center);
    });
  });

  group('an unclosed region', () {
    test('takes the rest of the document and says so', () {
      // The scanner cannot rewind, so there is nothing else to do with it.
      // Recording it is what keeps a mistyped marker from silently eating
      // the file with no way to tell.
      final document = NaturalBlockParser.parse('before|`rest of the document');
      final node = document.children.last as VerbatimNode;

      expect(document.children.first, line('before'));
      expect(node.text, 'rest of the document');
      expect(node.isTerminated, isFalse);
    });

    test('a closed region reports that it was closed', () {
      expect(only('|`x|`').isTerminated, isTrue);
    });

    test('the flag is part of equality', () {
      expect(
        VerbatimNode(text: 'x'),
        isNot(VerbatimNode(text: 'x', isTerminated: false)),
      );
    });
  });

  group('line endings', () {
    test('CRLF is normalized inside a region too', () {
      // Normalization happens before scanning, so line endings do not
      // round-trip through a verbatim region. Pinned so the limit is
      // stated rather than discovered.
      expect(only('|`a\r\nb|`').text, 'a\nb');
    });
  });
}
