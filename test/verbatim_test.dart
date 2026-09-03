// 【解説】[テスト4/21] verbatim 区間。この言語で最後に足した構文。
// 【解説】
// 【解説】 冒頭の group 名が「なぜ存在するか」になっているのが読みどころ。
// 【解説】 final x = a == b ? 1 : 2; は区間が無ければ4セルの行になる。
// 【解説】 = と | はコードが最も多用する文字なので、「散文は無傷」という約束が
// 【解説】 コードに対しては真逆に働く。それを直すためだけの構文。
// 【解説】
// 【解説】 2つ目の group が設計そのもの。文中・単独行・表のセル、どこでも
// 【解説】 同じ1つの構文で書ける。ブロック用とインライン用を分けなかった理由で、
// 【解説】 分けると同じ概念が2つになる。どう見えるかは置かれ方で描画側が決める。
// 【解説】
// 【解説】 閉じ忘れが区間にならないことも固定している。飲み込む失敗より、
// 【解説】 何も起きない失敗のほうが良い、という判断。
// 【解説】 次: test/table_test.dart

import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  const bs = r'\';

  TextNode line(String text) => TextNode(children: [TextSpanNode(text: text)]);

  /// The one line a source parses to.
  TextNode onlyLine(String source) =>
      NaturalBlockParser.parse(source).children.single as TextNode;

  /// The one verbatim region a source parses to.
  VerbatimNode onlyRegion(String source) =>
      NaturalBlockParser.parse(source).children.single as VerbatimNode;

  group('why this exists: code survives', () {
    test('a line of code is not split into cells', () {
      // Measured before verbatim existed: this became a four-cell row,
      // because `=` and `==` are what code is made of.
      const code = 'final x = a == b ? 1 : 2;';

      expect(NaturalBlockParser.parse(code).children.single, isA<RowNode>());
      expect(onlyRegion('`$code`').text, code);
    });

    test('a shell pipeline is not split into blocks', () {
      const code = 'cat file.txt | grep foo | wc -l';

      expect(NaturalBlockParser.parse(code).children, hasLength(3));
      expect(onlyRegion('`$code`').text, code);
    });

    test('nothing inside is markup: no separators, decoration or escapes', () {
      const raw = r':*bold:* and \| and :@action:@ and |a=b| and :---%%%';

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
            VerbatimSpanNode(text: 'a == b'),
            TextSpanNode(text: 'です'),
          ],
        ),
      );
    });

    test('a region standing alone is the whole line', () {
      // Same node, different placement -- which is what lets a renderer
      // draw this one as a block and the one above as a run of text.
      expect(NaturalBlockParser.parse('`code`').children, [
        VerbatimNode(text: 'code'),
      ]);
    });

    test('a multi-line region stays one node', () {
      // The block-splitting pass has to know about regions too, or this
      // would be cut into a line each and no later pass could rejoin it.
      expect(
        onlyRegion('`\nif (x) {\n  y();\n}\n`').text,
        'if (x) {\n  y();\n}',
      );
    });

    test('a multi-line region keeps the text around it in the same line', () {
      final children = onlyLine('before`\ncode\n`after').children;

      expect(children, [
        TextSpanNode(text: 'before'),
        VerbatimSpanNode(text: 'code'),
        TextSpanNode(text: 'after'),
      ]);
    });

    test('a region works inside a table cell', () {
      // Not possible with a `|`-based marker: a cell cannot hold a block.
      //
      // It is a run rather than a block. A region is a block because it was
      // opened on a line of its own, and this one sits beside `x` on the
      // same line -- the separator before it divides cells, not lines.
      final table =
          NaturalBlockParser.parse('|~x=`a|b`|y=z|').children.single
              as TableNode;
      final cell = table.children.first.children.last.children.single;

      expect(
        (cell as TextNode).children.single,
        VerbatimSpanNode(text: 'a|b'),
        reason: 'the pipe inside the region did not split the cell',
      );
    });

    test('a region sits alongside decoration on the same line', () {
      final children = onlyLine(':*bold:*and`code`and plain').children;

      expect(children[0], TextSpanNode(text: 'bold', emphasis: true));
      expect(children[1], TextSpanNode(text: 'and'));
      expect(children[2], VerbatimSpanNode(text: 'code'));
    });

    test('a region opening right after a cluster is still a region', () {
      // Inside a cluster a `:` is the reset action and is applied on sight,
      // so the region check has to come first or this would be swallowed.
      //
      // It is a run rather than a block: whether a region stands alone is
      // read from the source, and the cluster is there even though it
      // produces no text of its own.
      final children = onlyLine(':!`code`').children;
      expect(children, [VerbatimSpanNode(text: 'code')]);
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
      final document = NaturalBlockParser.parse('文章\n`code`\n続き');

      expect(document.children, [
        line('文章'),
        VerbatimNode(text: 'code'),
        line('続き'),
      ]);
    });

    test('a longer fence lets a region contain the fence character', () {
      // Without this the language could not quote its own syntax.
      expect(onlyRegion('``a `b` c``').text, 'a `b` c');
    });

    test('an empty region contributes no node', () {
      expect(
        NaturalBlockParser.parse('a``b'),
        DocumentNode(children: [line('a``b')]),
      );
    });
  });

  group('an unclosed fence is not a region', () {
    test('it stays ordinary text', () {
      // Nothing is swallowed: a stray backtick cannot eat a document, which
      // is what makes three separate passes agree by construction -- each
      // looks ahead and only then commits.
      expect(
        NaturalBlockParser.parse('a `b'),
        DocumentNode(children: [line('a `b')]),
      );
    });

    test('separators after it still work', () {
      expect(
        NaturalBlockParser.parse('a `b | c'),
        DocumentNode(children: [line('a `b '), line(' c')]),
      );
    });
  });

  group('escaping the fence', () {
    test('an escaped fence is a literal backtick and opens nothing', () {
      expect(
        NaturalBlockParser.parse('a $bs` b'),
        DocumentNode(children: [line('a ` b')]),
      );
    });

    test('a separator after an escaped fence still separates', () {
      // The check that all three passes agree: if any one of them read the
      // escaped fence as opening a region, this `|` would be swallowed.
      expect(
        NaturalBlockParser.parse('a $bs` b | c'),
        DocumentNode(children: [line('a ` b '), line(' c')]),
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
