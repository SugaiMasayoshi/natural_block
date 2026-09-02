// 【解説】[テスト9/21] 入力の正規化。地味だが Windows で書くと直に効く。
// 【解説】
// 【解説】 CRLF を先に潰さないと「開き記号を単独行に置ける」規則が黙って
// 【解説】 効かなくなる。空行の判定が '' ではなく '\r' になるため。
// 【解説】
// 【解説】 前後の空白削りに trim() を使っていないことも見ている。trim() は
// 【解説】 全角スペースまで消すので、日本語の字下げが壊れる。
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

    test('a lone CR at the end is trimmed like any trailing whitespace', () {
      expect(NaturalBlockParser.parse('text\r\n'), NaturalBlockParser.parse('text'));
    });
  });

  group('surrounding whitespace', () {
    test('ASCII whitespace around the document is dropped', () {
      expect(
        NaturalBlockParser.parse('  \n text \n  '),
        DocumentNode(children: [line('text')]),
      );
    });

    test('a leading ideographic space is kept', () {
      // `String.trim` would eat this. U+3000 is how Japanese prose indents,
      // and this language explicitly means to carry ordinary Japanese text
      // through unharmed -- so only the ASCII whitespace that surrounds a
      // document by accident is removed.
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
    test('an empty or blank document has no children', () {
      for (final source in ['', '   ', '\n\n', '\r\n']) {
        expect(
          NaturalBlockParser.parse(source).children,
          isEmpty,
          reason: 'source ${source.codeUnits}',
        );
      }
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
