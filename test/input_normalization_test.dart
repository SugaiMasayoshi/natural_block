// 【解説】[テスト9/21] 入力の正規化。地味だが Windows で書くと直に効く。
// 【解説】
// 【解説】 CRLF を先に潰さないと「開き記号を単独行に置ける」規則が黙って
// 【解説】 効かなくなる。空行の判定が '' ではなく '\r' になるため。
// 【解説】 単独 CR と、2つの置換の順序も固定している。順序を逆にすると
// 【解説】 CRLF が \n\n になって全行が倍になるが、これは例外を出さずに
// 【解説】 「行間が広い文書」として描画されてしまうので、テストで縛る。
// 【解説】
// 【解説】 2つ目の group が今の方針そのもの。空白は一切削らない。
// 【解説】 以前は文書の前後から ASCII の空白を削っていたが、最初と最後の
// 【解説】 行だけ字下げが剥がれるという不整合になっていたのでやめた。
// 【解説】 「打った空白は見えて消せるのだから内容だ」という判断。
// 【解説】 最後の group は「スキャナが切ってはいけないもの」で、絵文字や
// 【解説】 結合文字が途中で割れないことの確認。
// 【解説】 次: test/node_equality_test.dart

import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  TextNode line(String text) =>
      TextNode(children: [TextSpanNode(text: text)]);

  group('line endings', () {
    test('a CRLF document parses exactly like the LF one', () {
      // Not cosmetic. `_parseBlock` splits on `\n` and then drops a line
      // equal to `''` at each end -- the rule that lets a block's opening
      // symbol sit on its own line. Under CRLF that line is `'\r'`, so the
      // rule silently stopped applying and every line kept a trailing `\r`.
      // Every document written by a Windows editor is affected.
      const lf = '|\nheading\n|body';
      final crlf = lf.replaceAll('\n', '\r\n');

      expect(NaturalBlockParser.parse(crlf), NaturalBlockParser.parse(lf));
    });

    test('no CR survives into the text of a CRLF document', () {
      final document = NaturalBlockParser.parse('one\r\ntwo\r\nthree');

      expect(document.children, [line('one'), line('two'), line('three')]);
    });

    test('a trailing CRLF leaves no empty line behind', () {
      expect(
        NaturalBlockParser.parse('text\r\n'),
        NaturalBlockParser.parse('text'),
      );
    });

    test('a lone CR is a line ending too', () {
      // Nothing else catches this. Until the source is trimmed of nothing
      // at all, the old `[ \t\r\n]` trim happened to sweep a stray CR off
      // each end, and no test ever passed a lone CR through the middle --
      // one sat in the text as an invisible control character, reaching the
      // AST, the renderer, and anything the reader copied out.
      expect(
        NaturalBlockParser.parse('one\rtwo'),
        NaturalBlockParser.parse('one\ntwo'),
      );
    });

    test('a lone CR does not double the lines of a CRLF document', () {
      // Pins the order of the two replacements. Doing `\r` first turns
      // every `\r\n` into `\n\n`, which is silent: the document still
      // renders, with a blank line inserted after every line.
      expect(
        NaturalBlockParser.parse('a\r\nb').children,
        [line('a'), line('b')],
      );
    });
  });

  group('surrounding whitespace is content', () {
    // Nothing is trimmed. A space the author typed is one they can see and
    // delete, so the parser keeps it -- and keeping it is what makes the
    // first and last line behave like every other line.
    test('a space at each end of the document survives', () {
      expect(
        NaturalBlockParser.parse('  text  '),
        DocumentNode(children: [line('  text  ')]),
      );
    });

    test('an indent is kept on the first line, not just the rest', () {
      // The reason this rule changed. Trimming the document's ends stripped
      // the indent of the *first* line only, so two paragraphs written the
      // same way came out different -- the one asymmetry in a language
      // whose whole shape is "one line is one node".
      expect(
        NaturalBlockParser.parse('    A\n    B'),
        DocumentNode(children: [line('    A'), line('    B')]),
      );
    });

    test("a block's own blank line at each end still goes", () {
      // The one thing that does disappear, and it belongs to `_parseBlock`
      // rather than to any trimming of the source: it is what lets a
      // block's symbol sit on a line of its own.
      expect(
        NaturalBlockParser.parse('|\ntext\n|'),
        DocumentNode(children: [line('text')]),
      );
    });

    test('a leading ideographic space is kept', () {
      // U+3000 is how Japanese prose indents. `String.trim` would eat it,
      // which is why trimming was never done with `trim` even back when the
      // parser trimmed at all.
      expect(
        NaturalBlockParser.parse('　indented'),
        DocumentNode(children: [line('　indented')]),
      );
    });

    test('a non-breaking space is kept too', () {
      expect(
        NaturalBlockParser.parse(' text '),
        DocumentNode(children: [line(' text ')]),
      );
    });
  });

  group('documents that are only markup', () {
    test('an empty document has no children', () {
      // A newline-only document is empty because `_parseBlock` drops one
      // blank line at each end of a block, not because anything trims the
      // source.
      for (final source in ['', '\n', '\r\n']) {
        expect(
          NaturalBlockParser.parse(source).children,
          isEmpty,
          reason: 'source ${source.codeUnits}',
        );
      }
    });

    test('a document of only whitespace is not empty -- it is whitespace', () {
      // The parser has no opinion about content. Spaces were typed, so
      // spaces come out; two newlines are one blank line, so one blank line
      // comes out. Both used to vanish, which was the parser deciding what
      // the author meant.
      expect(NaturalBlockParser.parse('   ').children, [line('   ')]);
      expect(
        NaturalBlockParser.parse('\n\n').children,
        [TextNode(children: [])],
      );
    });

    test('separators with nothing between them produce nothing', () {
      for (final source in ['|', '||||', '|~', '|~|~']) {
        expect(
          NaturalBlockParser.parse(source).children,
          isEmpty,
          reason: '"$source" has no content to place',
        );
      }
    });

    test('a bare `~` with no separator before it is ordinary text', () {
      expect(
        NaturalBlockParser.parse('~'),
        DocumentNode(children: [line('~')]),
      );
    });
  });

  group('text the scanner must not cut apart', () {
    // The scanner indexes UTF-16 code units, so this pins the fact that
    // multi-unit characters survive: every markup character is ASCII, and
    // the units between them are rejoined by `substring`, so a surrogate
    // pair is never split. Pinning it rather than fixing anything.
    test('an emoji outside the BMP survives intact', () {
      expect(
        NaturalBlockParser.parse('a\u{1F600}b'),
        DocumentNode(children: [line('a\u{1F600}b')]),
      );
    });

    test('a combining mark stays attached', () {
      expect(
        NaturalBlockParser.parse('é'),
        DocumentNode(children: [line('é')]),
      );
    });

    test('right-to-left text passes through', () {
      expect(
        NaturalBlockParser.parse('שלום=עולם').children.single,
        isA<RowNode>(),
      );
    });
  });
}
