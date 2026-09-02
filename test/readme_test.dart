// Every claim README.md makes about how a document parses, executed.
//
// The README is written as prose, and prose does not run. It has been wrong
// before, precisely because it was written without running it. Each test
// here quotes one sentence of it and checks the input that sentence names --
// verbatim, never paraphrased, since a paraphrase stops checking the README
// the moment it drifts. If one of these fails after an edit, the README is
// what is wrong.
//
// The file follows README.md top to bottom so the two can be read side by
// side.

import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

/// The document's only line, for the many claims about a single line.
TextNode onlyLine(String source) =>
    NaturalBlockParser.parse(source).children.single as TextNode;

/// That line's runs, as the styled spans they are.
List<TextSpanNode> runs(String source) =>
    onlyLine(source).children.cast<TextSpanNode>();

/// Asserts [source] parses to exactly one run of unstyled text equal to it
/// -- the "needs no escaping" claim, which is about the text arriving whole
/// as much as about it arriving undecorated.
void survivesUntouched(String source) {
  expect(runs(source), [TextSpanNode(text: source)], reason: source);
}

void main() {
  group('Decoration clusters', () {
    test('`:+++` is +3 -- repeat to stack without retyping the colon', () {
      expect(runs(':+++Huge').single.sizeOffset, 3);
    });

    test('a color toggles: typing it again turns it back off', () {
      final spans = runs(':!on:!off');
      expect(spans[0].color, SemanticColor.danger);
      expect(spans[1].color, SemanticColor.none);
    });

    test('`::` resets color, emphasis and action but not the size', () {
      final spans = runs(':+!*@marked::plain');
      expect(spans[0].color, SemanticColor.danger);
      expect(spans[0].emphasis, isTrue);
      expect(spans[0].isAction, isTrue);
      expect(spans[1].color, SemanticColor.none);
      expect(spans[1].emphasis, isFalse);
      expect(spans[1].isAction, isFalse);
      // "It does **not** reset the size offset."
      expect(spans[1].sizeOffset, 1);
    });

    test('`:!*` applies Danger and Emphasis together in one span', () {
      // README: NaturalBlockParser.parse(":!*緊急対応");
      final span = runs(':!*緊急対応').single;
      expect(span.color, SemanticColor.danger);
      expect(span.emphasis, isTrue);
    });

    test('`:!:*` is not the same: the second `:` is absorbed as a reset', () {
      // README: ":!*結果"  -> color: danger, emphasis: true
      //         ":!:*結果" -> color: none,   emphasis: true
      expect(runs(':!*結果').single.color, SemanticColor.danger);
      expect(runs(':!*結果').single.emphasis, isTrue);

      final absorbed = runs(':!:*結果').single;
      expect(absorbed.color, SemanticColor.none);
      expect(absorbed.emphasis, isTrue);
    });
  });

  group('Actionable text', () {
    test('the run between `:@` and `:@` is actionable, and only it', () {
      // README: NaturalBlockParser.parse(':@https://example.com:@ を参照');
      final spans = runs(':@https://example.com:@ を参照');
      expect(spans[0].text, 'https://example.com');
      expect(spans[0].isAction, isTrue);
      expect(spans[1].text, ' を参照');
      expect(spans[1].isAction, isFalse);
    });
  });

  group('Block alignment', () {
    test('`|<品名=^数量=>価格|` sets start, center and end', () {
      final row =
          NaturalBlockParser.parse('|<品名=^数量=>価格|').children.single as RowNode;
      expect([
        for (final c in row.children) c.align,
      ], [BlockAlign.start, BlockAlign.center, BlockAlign.end]);
    });

    test(
      r'`a\=>b` is literally `a=>b` -- an escaped separator leaves the '
      'marker alone too',
      () {
        expect(runs(r'a\=>b'), [TextSpanNode(text: 'a=>b')]);
      },
    );

    test('anywhere else the markers are ordinary text', () {
      // "a > b, ->, =>, and List<String> are everywhere in normal prose"
      survivesUntouched('a > b');
      survivesUntouched('->');
      survivesUntouched('List<String>');
    });
  });

  group('Independent axes', () {
    test('a size change survives a following color symbol and vice versa', () {
      final span = runs(':++big:!red').last;
      expect(span.sizeOffset, 2);
      expect(span.color, SemanticColor.danger);
    });

    test('only a layout symbol resets everything', () {
      final row =
          NaturalBlockParser.parse(':++:!A=B').children.single as RowNode;
      final second =
          row.children[1].children.single.children.single as TextSpanNode;
      expect(second.sizeOffset, 0);
      expect(second.color, SemanticColor.none);
    });
  });

  group('Bare punctuation is always literal', () {
    test('everyday prose renders completely unchanged, with zero escaping', () {
      // The exact list the README names.
      survivesUntouched('C++');
      survivesUntouched('10-20');
      survivesUntouched('100%');
      survivesUntouched('well-known');
      survivesUntouched('Really?!');
      survivesUntouched('you@example.com');
    });

    test('the README usage example 3 is one plain run', () {
      survivesUntouched('It costs -100 and has 100% success rate.');
    });
  });

  group('One line is one node', () {
    test('each line of a block becomes its own TextNode', () {
      expect(NaturalBlockParser.parse('|one\ntwo|').children.length, 2);
    });

    test('decoration does not carry across a newline', () {
      final second = NaturalBlockParser.parse('|:!red\nplain|').children[1]
          as TextNode;
      expect((second.children.single as TextSpanNode).color, SemanticColor.none);
    });

    test(
      "a single blank line at each end of a block is dropped, so a block's "
      'symbol can sit on its own line',
      () {
        expect(NaturalBlockParser.parse('|\nonly\n|').children.length, 1);
      },
    );

    test('a genuine blank line in the middle is preserved', () {
      expect(NaturalBlockParser.parse('|a\n\nb|').children.length, 3);
    });

    test('CRLF input parses identically', () {
      expect(
        NaturalBlockParser.parse('|\r\nonly\r\n|'),
        NaturalBlockParser.parse('|\nonly\n|'),
      );
    });
  });

  group('An empty cell holds its place; an empty block does not', () {
    test('`左||右` is two text nodes, not three', () {
      expect(NaturalBlockParser.parse('左||右').children.length, 2);
    });

    test('an alignment marker does not change that', () {
      expect(NaturalBlockParser.parse('左|>|右').children.length, 2);
    });

    test('`左==右` is three cells with an empty middle', () {
      final row = NaturalBlockParser.parse('左==右').children.single as RowNode;
      expect(row.children.length, 3);
      expect(row.children[1].children, isEmpty);
    });

    test('which is what distinguishes it from `左=右`', () {
      final row = NaturalBlockParser.parse('左=右').children.single as RowNode;
      expect(row.children.length, 2);
    });

    test('a run of `=`-joined cells ends at a `|`, so `a=b|c=d` is two rows', () {
      expect(
        NaturalBlockParser.parse('a=b|c=d').children.map((c) => c.runtimeType),
        [RowNode, RowNode],
      );
    });
  });

  group('Wrap a row in `|`', () {
    test('a line before a row without a leading `|` is absorbed into the '
        "row's first cell", () {
      // The failure this rule warns about: nothing throws and nothing is
      // lost, so it is invisible until the document is drawn. It caught the
      // author out writing the renderer's own showcase.
      final row = NaturalBlockParser.parse('前の行\nA=B|').children.single
          as RowNode;
      expect(row.children.first.children, [
        TextNode(children: [TextSpanNode(text: '前の行')]),
        TextNode(children: [TextSpanNode(text: 'A')]),
      ]);
    });

    test('the leading `|` keeps the preceding line its own block', () {
      expect(
        NaturalBlockParser.parse('前の行\n|A=B|').children.map((c) => c.runtimeType),
        [TextNode, RowNode],
      );
    });

    test('omitting it is fine when nothing precedes the row', () {
      expect(NaturalBlockParser.parse('A=B|').children.single, isA<RowNode>());
    });
  });

  group('Tables', () {
    TableNode onlyTable(String source) =>
        NaturalBlockParser.parse(source).children.single as TableNode;

    test('`|~Item=>Price|` right-aligns the price column for every row', () {
      final table = onlyTable('|~Item=>Price|A=100|B=200|');
      expect(
        [
          for (final row in table.children)
            [for (final c in row.children) c.align],
        ],
        [
          [BlockAlign.start, BlockAlign.end],
          [BlockAlign.start, BlockAlign.end],
          [BlockAlign.start, BlockAlign.end],
        ],
      );
    });

    test('a marker on an individual cell overrides just that cell', () {
      expect(
        onlyTable('|~Item=>Price|A=^100|').children[1].children[1].align,
        BlockAlign.center,
      );
    });

    test('`|~^` is a centered table -- markers share one cluster', () {
      expect(onlyTable('|~^A=B|').align, BlockAlign.center);
    });

    test('a table ends at a row with a different number of cells', () {
      expect(
        NaturalBlockParser.parse('|~A=B|C=D=E|').children.map((c) => c.runtimeType),
        [TableNode, RowNode],
      );
    });

    test('a table ends at anything that is not a row', () {
      expect(
        NaturalBlockParser.parse('|~A=B|note|').children.map((c) => c.runtimeType),
        [TableNode, TextNode],
      );
    });

    test('a table ends at the end of the document', () {
      expect(NaturalBlockParser.parse('|~A=B').children.single, isA<TableNode>());
    });

    test('writing `|~` again closes it', () {
      expect(
        NaturalBlockParser.parse('|~A=B|~C=D|').children.map((c) => c.runtimeType),
        [TableNode, RowNode],
      );
    });

    test(
      'an empty block does not end a table, or `||` would be an invisible '
      'separator',
      () {
        expect(
          NaturalBlockParser.parse('|~A=B||C=D|').children.single,
          isA<TableNode>(),
        );
      },
    );
  });

  group('Verbatim regions', () {
    test('an inline region is one line of three runs, the middle verbatim', () {
      // README: 比較は`a == b`です
      final children = onlyLine('比較は`a == b`です').children;
      expect(children, [
        TextSpanNode(text: '比較は'),
        VerbatimNode(text: 'a == b'),
        TextSpanNode(text: 'です'),
      ]);
    });

    test('a fence on its own line gives one node, the command intact', () {
      // README's second example.
      final line =
          NaturalBlockParser.parse('`\ncat file.txt | grep foo | wc -l\n`')
                  .children
                  .single
              as TextNode;
      expect(line.children.single,
          VerbatimNode(text: 'cat file.txt | grep foo | wc -l'));
    });

    test('without a region that same command becomes three blocks', () {
      // The README's own argument for why regions exist.
      expect(
        NaturalBlockParser.parse('cat file.txt | grep foo | wc -l').children.length,
        3,
      );
    });

    test('and `final x = a == b ? 1 : 2;` becomes a four-cell row', () {
      final row = NaturalBlockParser.parse('final x = a == b ? 1 : 2;')
          .children
          .single as RowNode;
      expect(row.children.length, 4);
    });

    test('a region can go in a table cell', () {
      final table =
          NaturalBlockParser.parse('|~A=`x`|B=`y`|').children.single as TableNode;
      expect(
        table.children[0].children[1].children.single.children.single,
        VerbatimNode(text: 'x'),
      );
    });

    test('nothing inside is a separator, a decoration, or an escape', () {
      expect(
        onlyLine(r'`| = : \n :!`').children.single,
        VerbatimNode(text: r'| = : \n :!'),
      );
    });

    test('the fence run length sets the closer, so a doubled fence may '
        'contain a single backtick', () {
      expect(onlyLine('``a `b` c``').children.single,
          VerbatimNode(text: 'a `b` c'));
    });

    test('the newline directly against each fence belongs to that fence', () {
      expect(onlyLine('`\ncode\n`').children.single, VerbatimNode(text: 'code'));
    });

    test('written inline the content is exactly what was typed', () {
      expect(onlyLine('a`  b  `c').children[1], VerbatimNode(text: '  b  '));
    });

    test(
      'an unclosed fence is not a region: it stays ordinary text and '
      'separators after it still work',
      () {
        final doc = NaturalBlockParser.parse('a`b|c');
        expect(doc.children.length, 2);
        expect(
          (doc.children.first as TextNode).children.single,
          TextSpanNode(text: 'a`b'),
        );
      },
    );
  });

  group('Escape characters', () {
    test(r'`\|`, `\=`, `\:` and an escaped fence are literal characters', () {
      expect(runs(r'\|'), [TextSpanNode(text: '|')]);
      expect(runs(r'\='), [TextSpanNode(text: '=')]);
      expect(runs(r'\:'), [TextSpanNode(text: ':')]);
      expect(runs(r'\`'), [TextSpanNode(text: '`')]);
    });

    test(r'`\\` renders as a literal backslash', () {
      expect(runs(r'\\'), [TextSpanNode(text: '\\')]);
    });

    test(r'inside a cluster `:---\%off` gives `%off` at -3, backslash gone', () {
      final span = runs(r':---\%off').single;
      expect(span.text, '%off');
      expect(span.sizeOffset, -3);
    });

    test(r'the escape ends the cluster, so `:---\%%%` needs one backslash', () {
      final span = runs(r':---\%%%').single;
      expect(span.text, '%%%');
      expect(span.sizeOffset, -3);
    });

    test('everywhere else a backslash is just a backslash', () {
      survivesUntouched(r'\+');
      survivesUntouched(r'\!');
      survivesUntouched(r'C:\Users');
    });

    test(r'`\\=` is a cell holding a backslash followed by a real separator',
        () {
      final row = NaturalBlockParser.parse(r'\\=b').children.single as RowNode;
      expect(row.children.length, 2);
      expect(
        row.children[0].children.single.children.single,
        TextSpanNode(text: '\\'),
      );
    });

    test(r'where a lone `\=` would just be a literal `=`', () {
      expect(runs(r'\=b'), [TextSpanNode(text: '=b')]);
    });
  });

  group('Filesystem paths', () {
    test(r'`C:\Users\you\a.png` comes through untouched', () {
      survivesUntouched(r'C:\Users\you\a.png');
    });

    test('a doubled backslash collapses, so a UNC path is written with four',
        () {
      expect(runs(r'\\\\server'), [TextSpanNode(text: r'\\server')]);
    });

    test('forward slashes avoid the question entirely', () {
      survivesUntouched('C:/Users/you/a.png');
    });
  });

  group('README usage examples', () {
    test('example 1: layout symbols reset styles at each boundary', () {
      // const input1 = "|:!Danger Zone=:?Safe Zone|";
      final row = NaturalBlockParser.parse('|:!Danger Zone=:?Safe Zone|')
          .children
          .single as RowNode;
      TextSpanNode runOf(int i) =>
          row.children[i].children.single.children.single as TextSpanNode;
      expect(runOf(0).color, SemanticColor.danger);
      expect(runOf(0).text, 'Danger Zone');
      expect(runOf(1).color, SemanticColor.info);
      expect(runOf(1).text, 'Safe Zone');
    });

    test('example 2: ":++" is +2, ":--" right after nets back to base', () {
      // const input2 = ":++Huge Text:--Normal Text";
      final spans = runs(':++Huge Text:--Normal Text');
      expect(spans[0].sizeOffset, 2);
      expect(spans[0].text, 'Huge Text');
      expect(spans[1].sizeOffset, 0);
      expect(spans[1].text, 'Normal Text');
    });
  });

  group('Surrounding whitespace', () {
    test('ASCII whitespace around a document is removed', () {
      expect(NaturalBlockParser.parse('  a  '), NaturalBlockParser.parse('a'));
    });

    test('an ideographic space is not -- Japanese indentation survives', () {
      expect(runs('\u3000字下げ'), [TextSpanNode(text: '\u3000字下げ')]);
    });
  });
}
