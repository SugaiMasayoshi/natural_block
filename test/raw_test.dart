import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'nodes.dart';

void main() {
  const bs = r'\';

  /// The one raw region a source parses to.
  RawNode onlyRegion(String source) =>
      onlyBlock(source).children.single as RawNode;

  group('why this exists: code survives', () {
    test('a line of code full of `=` now needs no region at all', () {
      // This used to be the headline argument for raw regions: while `=`
      // separated cells, `final x = a == b ? 1 : 2;` parsed as a four-cell
      // row, and `=` is what code is made of. Moving the separator to `^`
      // took the argument away, which is the point -- code in prose survives
      // on its own now.
      const code = 'final x = a == b ? 1 : 2;';

      expect(
        NaturalBlockParser.parse(code).children,
        [line(code)].map((l) => ColumnNode(children: [l])),
      );
      expect(onlyRegion('`$code`').text, code, reason: 'still quotable');
    });

    test('a line of code containing `^` does need one', () {
      // What is left of the argument. `^` is rarer in code than `=` was, but
      // it is not absent: exponents, regexes, and version constraints.
      const code = 'assert(2^10 == 1024)';

      expect(NaturalBlockParser.parse(code).children.single, isA<RowNode>());
      expect(onlyRegion('`$code`').text, code);
    });

    test('a shell pipeline is not split into blocks', () {
      const code = 'cat file.txt | grep foo | wc -l';

      expect(NaturalBlockParser.parse(code).children, hasLength(3));
      expect(onlyRegion('`$code`').text, code);
    });

    test('nothing inside is markup: no separators, decoration or escapes', () {
      const raw = r':*bold:* and \| and :@action:@ and |a^b| and :---%%%';

      expect(onlyRegion('`$raw`').text, raw);
    });
  });

  group('the point of one concept: it goes anywhere', () {
    test('a region inside a sentence stays inside that line', () {
      // The reason the delimiter cannot involve `|`: a `|`-based marker
      // always breaks the block, so it could never be written mid-sentence.
      expect(
        onlyLine('比較は`a == b`です'),
        TextNode(
          children: [
            TextSpanNode(text: '比較は'),
            RawSpanNode(text: 'a == b'),
            TextSpanNode(text: 'です'),
          ],
        ),
      );
    });

    test('a region standing alone is the whole line', () {
      // Same node, different placement -- which is what lets a renderer
      // draw this one as a block and the one above as a run of text.
      expect(onlyBlock('`code`').children, [RawNode(text: 'code')]);
    });

    test('a multi-line region stays one node', () {
      // Every level that stops at a boundary has to know about regions
      // too, or this would be cut into a piece per line with nothing left
      // to rejoin it. `cursor.atLineStart` is the single answer they all
      // ask for.
      expect(
        onlyRegion('`\nif (x) {\n  y();\n}\n`').text,
        'if (x) {\n  y();\n}',
      );
    });

    test('a multi-line region keeps the text around it in the same line', () {
      final children = onlyLine('before`\ncode\n`after').children;

      expect(children, [
        TextSpanNode(text: 'before'),
        RawSpanNode(text: 'code'),
        TextSpanNode(text: 'after'),
      ]);
    });

    test('a region works inside a table cell', () {
      // Not possible with a `|`-based marker: a cell cannot hold a block.
      //
      // It is a run rather than a block. A region is a block because it was
      // opened on a line of its own, and this one sits beside `x` on the
      // same line -- the separator before it divides cells, not lines.
      final table = onlyTable('~x^`a|b`|y^z~');
      final cell = table.children.first.children.last.children.single;

      expect(
        (cell as TextNode).children.single,
        RawSpanNode(text: 'a|b'),
        reason: 'the pipe inside the region did not split the cell',
      );
    });

    test('a region sits alongside decoration on the same line', () {
      final children = onlyLine(':*bold:*and`code`and plain').children;

      expect(
        children[0],
        TextSpanNode(text: 'bold', decoration: SpanDecoration(emphasis: true)),
      );
      expect(children[1], TextSpanNode(text: 'and'));
      expect(children[2], RawSpanNode(text: 'code'));
    });

    test('a region opening right after a cluster is still a region', () {
      // Inside a cluster a `:` is the reset action and is applied on sight,
      // so the region check has to come first or this would be swallowed.
      //
      // It is a run rather than a block: whether a region stands alone is
      // read from the source, and the cluster is there even though it
      // produces no text of its own.
      final children = onlyLine(':!`code`').children;
      expect(children, [RawSpanNode(text: 'code')]);
    });
  });

  group('fences', () {
    test('the newline against each fence belongs to the fence', () {
      expect(onlyRegion('`\ncat a | grep b\n`').text, 'cat a | grep b');
    });

    test('only one newline goes at each end', () {
      expect(onlyRegion('`\n\ncode\n\n`').text, '\ncode\n');
    });

    test('a block region also swallows the newline written after it', () {
      // The same boundary rule from the outside: a region on a line of its
      // own is a boundary, so the newline against it is the boundary's. Miss
      // this and the text after a code block opens with a blank line that
      // nobody wrote.
      expect(onlyBlock('文章\n`code`\n続き').children, [
        line('文章'),
        RawNode(text: 'code'),
        line('続き'),
      ]);
    });

    test('a longer fence lets a region contain the fence character', () {
      // Without this the language could not quote its own syntax.
      expect(onlyRegion('``a `b` c``').text, 'a `b` c');
    });

    test('an empty region contributes no node', () {
      expect(
        NaturalBlockParser.parse('a`\n`'),
        DocumentNode(children: [block('a')]),
      );
    });
  });

  group('an unclosed fence runs to the end of the document', () {
    test('it opens a region all the same', () {
      // The fence alone settles it, the same as a table's `~`: nothing
      // searches ahead for a closer.
      expect(onlyLine('a `b').children, [
        TextSpanNode(text: 'a '),
        RawSpanNode(text: 'b'),
      ]);
    });

    test('separators after it are inside the region', () {
      expect(onlyLine('a `b | c').children, [
        TextSpanNode(text: 'a '),
        RawSpanNode(text: 'b | c'),
      ]);
    });

    test('on a line of its own it is a block region', () {
      expect(onlyRegion('`\ncode\n').text, 'code');
    });
  });

  group('escaping the fence', () {
    test('an escaped fence is a literal backtick and opens nothing', () {
      expect(
        NaturalBlockParser.parse('a $bs` b'),
        DocumentNode(children: [block('a ` b')]),
      );
    });

    test('a separator after an escaped fence still separates', () {
      // The check that escaping and region-opening agree: if the escaped
      // fence were read as opening a region, this `|` would be swallowed.
      expect(
        NaturalBlockParser.parse('a $bs` b | c'),
        DocumentNode(children: [block('a ` b '), block(' c')]),
      );
    });
  });

  group('line endings', () {
    test('CRLF is normalized inside a region too', () {
      // Normalization happens before scanning, so line endings do not
      // round-trip through a region. Pinned so the limit is stated.
      expect(onlyRegion('`a\r\nb`').text, 'a\nb');
    });
  });
}
