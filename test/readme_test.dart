// 【解説】[テスト1/21] ここから読むのが一番早い。README の主張をそのまま実行する。
// 【解説】
// 【解説】 この言語の契約が散文で書いてあるのが README で、散文は動かない。
// 【解説】 実際に一度、実行されずに書かれた README が間違っていたことがある。
// 【解説】 このファイルは README を上から順になぞり、そこに現れる文字列を
// 【解説】 そのまま入力にする。言い換えた時点で README を検証しなくなるので、
// 【解説】 わざと言い換えていない。ここが落ちたら直すのは README のほう。
// 【解説】
// 【解説】 書いた直後に58個全部が通ったので疑い、パーサに5種類の変異を入れて
// 【解説】 全部が捕まることを確認してある(サイズの加算・フェンスのエスケープ・
// 【解説】 全角スペースの扱い・表の列寄せ継承・空ブロックの扱い)。
// 【解説】 「通った」は「効いている」ではない、という手順。
// 【解説】 次: test/layout_test.dart

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

import 'dart:io';

import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'nodes.dart';

/// A single-line block, which is what a bare paragraph parses to.
ColumnNode block(String text) => ColumnNode(
  children: [
    TextNode(children: [TextSpanNode(text: text)]),
  ],
);

/// Asserts [source] parses to exactly one run of unstyled text equal to it
/// -- the "needs no escaping" claim, which is about the text arriving whole
/// as much as about it arriving undecorated.
void survivesUntouched(String source) {
  expect(runs(source), [TextSpanNode(text: source)], reason: source);
}

final _readme = File('README.md').readAsStringSync();

/// [source], having first checked that the README really contains it.
///
/// Quoting the README in a comment is not enough: the two drift. A symbol
/// swap once updated every test in this file and left one README example
/// behind, and nothing failed -- the test proved that its own string parsed
/// correctly, which had stopped being a statement about the README at all.
String fromReadme(String source, [String? fragment]) {
  expect(
    _readme,
    contains(fragment ?? source),
    reason:
        'README.md no longer contains this, so the test below has stopped '
        'checking the README. Fix whichever one is wrong.',
  );
  return source;
}

void main() {
  group('Decoration clusters', () {
    test('`:+++` is +3 -- repeat to stack without retyping the colon', () {
      expect(
        runs(fromReadme(':+++Huge', ':+++')).single.decoration.sizeOffset,
        3,
      );
    });

    test('a color toggles: typing it again turns it back off', () {
      final spans = runs(fromReadme(':!on:!off', ':!'));
      expect(spans[0].decoration.color, SemanticColor.danger);
      expect(spans[1].decoration.color, SemanticColor.none);
    });

    test('`::` resets color, emphasis and action but not the size', () {
      final spans = runs(fromReadme(':+!*@marked::plain', '::'));
      expect(spans[0].decoration.color, SemanticColor.danger);
      expect(spans[0].decoration.emphasis, isTrue);
      expect(spans[0].decoration.isAction, isTrue);
      expect(spans[1].decoration.color, SemanticColor.none);
      expect(spans[1].decoration.emphasis, isFalse);
      expect(spans[1].decoration.isAction, isFalse);
      // "It does **not** reset the size offset."
      expect(spans[1].decoration.sizeOffset, 1);
    });

    test('`:!*` applies Danger and Emphasis together in one span', () {
      // README: NaturalBlockParser.parse(":!*緊急対応");
      final span = runs(':!*緊急対応').single;
      expect(span.decoration.color, SemanticColor.danger);
      expect(span.decoration.emphasis, isTrue);
    });

    test('`:!:*` is not the same: the second `:` is absorbed as a reset', () {
      // README: ":!*結果"  -> color: danger, emphasis: true
      //         ":!:*結果" -> color: none,   emphasis: true
      expect(runs(':!*結果').single.decoration.color, SemanticColor.danger);
      expect(runs(':!*結果').single.decoration.emphasis, isTrue);

      final absorbed = runs(':!:*結果').single;
      expect(absorbed.decoration.color, SemanticColor.none);
      expect(absorbed.decoration.emphasis, isTrue);
    });
  });

  group('Actionable text', () {
    test('the run between `:@` and `:@` is actionable, and only it', () {
      // README: NaturalBlockParser.parse(':@https://example.com:@ を参照');
      final spans = runs(fromReadme(':@https://example.com:@ を参照'));
      expect(spans[0].text, 'https://example.com');
      expect(spans[0].decoration.isAction, isTrue);
      expect(spans[1].text, ' を参照');
      expect(spans[1].decoration.isAction, isFalse);
    });
  });

  group('Block alignment', () {
    test('`|<品名^=数量^>価格|` sets start, center and end', () {
      final row =
          NaturalBlockParser.parse(fromReadme('|<品名^=数量^>価格|')).children.single
              as RowNode;
      expect(
        [for (final c in row.children) c.align],
        [BlockAlign.start, BlockAlign.center, BlockAlign.end],
      );
    });

    test(r'`a\^>b` is literally `a^>b` -- an escaped separator leaves the '
        'marker alone too', () {
      expect(runs(r'a\^>b'), [TextSpanNode(text: 'a^>b')]);
    });

    test('anywhere else the markers are ordinary text', () {
      // "a > b, ->, =>, and List<String> are everywhere in normal prose"
      survivesUntouched('a > b');
      survivesUntouched('->');
      survivesUntouched('List<String>');
    });
  });

  group('Independent axes', () {
    test('a size change survives a following color symbol and vice versa', () {
      final span = runs(fromReadme(':++big:!red', ':+')).last;
      expect(span.decoration.sizeOffset, 2);
      expect(span.decoration.color, SemanticColor.danger);
    });

    test('only a layout symbol resets everything', () {
      final row =
          NaturalBlockParser.parse(fromReadme(':++:!A^B', ':!')).children.single
              as RowNode;
      final second =
          (row.children[1].children.single as TextNode).children.single
              as TextSpanNode;
      expect(second.decoration.sizeOffset, 0);
      expect(second.decoration.color, SemanticColor.none);
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
      survivesUntouched(fromReadme('It costs -100 and has 100% success rate.'));
    });
  });

  group('A newline is a character, not a boundary', () {
    test('a block is one node however many lines it has', () {
      expect(
        NaturalBlockParser.parse(
          fromReadme('|one\ntwo|', 'however many lines it has'),
        ).children,
        [block('one\ntwo')],
      );
    });

    test('decoration does not carry across a newline', () {
      // The one thing a newline still does. It is a rule the parser applies
      // while reading, not a division the tree records -- so the runs on
      // either side end up in the same node, styled differently.
      expect(
        onlyLine(fromReadme('|:!red\nplain|', 'it resets decoration')).children,
        [
          TextSpanNode(
            text: 'red',
            decoration: SpanDecoration(color: SemanticColor.danger),
          ),
          TextSpanNode(text: '\nplain'),
        ],
      );
    });

    test("a single blank line at each end of a block is dropped, so a block's "
        'symbol can sit on its own line', () {
      expect(
        NaturalBlockParser.parse(
          fromReadme('|\nonly\n|', 'can sit on a line of its own'),
        ).children,
        [block('only')],
      );
    });

    test('a genuine blank line in the middle is preserved, as characters', () {
      expect(
        NaturalBlockParser.parse(
          fromReadme('|a\n\nb|', 'A single blank line at the start or end'),
        ).children,
        [block('a\n\nb')],
      );
    });

    test('CRLF input parses identically', () {
      expect(
        NaturalBlockParser.parse('|\r\nonly\r\n|'),
        NaturalBlockParser.parse(
          fromReadme('|\nonly\n|', 'can sit on a line of its own'),
        ),
      );
    });
  });

  group('An empty cell holds its place; an empty block does not', () {
    test('`左||右` is two text nodes, not three', () {
      expect(NaturalBlockParser.parse('左||右').children.length, 2);
    });

    test('an alignment marker does not change that', () {
      expect(
        NaturalBlockParser.parse(
          fromReadme('左|>|右', 'contributes no node at all'),
        ).children.length,
        2,
      );
    });

    test('`左^^右` is three cells with an empty middle', () {
      final row = NaturalBlockParser.parse('左^^右').children.single as RowNode;
      expect(row.children.length, 3);
      expect(row.children[1].children, isEmpty);
    });

    test('which is what distinguishes it from `左^右`', () {
      final row = NaturalBlockParser.parse('左^右').children.single as RowNode;
      expect(row.children.length, 2);
    });

    // "a run of `^`-joined cells ends at a `|`" lived here and should not
    // have: the README never states it, so the test had nothing to check
    // against -- the exact mistake this file's closing comment records
    // having made once before. `layout_test.dart` owns it now.
  });

  group('A `|` ends the block before it', () {
    test('`^` cannot do the job: it separates cells within a block and has '
        'no business ending one', () {
      // Why the leading separator has to be `|`. `=` sits below `|` in the
      // hierarchy, so it cannot end what `|` ends -- the preceding line
      // just becomes the first cell, one cell later than without it.
      final row =
          NaturalBlockParser.parse(fromReadme('前の行\n^A^B', r'`前の行\n^A^B`'))
                  .children
                  .single
              as RowNode;

      expect(
        [for (final c in row.children) c.children.length],
        [1, 1, 1],
        reason: 'three cells, not a block and a row',
      );
      expect(row.children.first.children, [line('前の行')]);
    });

    test('a line before a row without a leading `|` is absorbed into the '
        "row's first cell", () {
      // The failure this rule warns about: nothing throws and nothing is
      // lost, so it is invisible until the document is drawn. It caught the
      // author out writing the renderer's own showcase.
      final row =
          NaturalBlockParser.parse(fromReadme('前の行\nA^B|', r'`前の行\nA^B|`'))
                  .children
                  .single
              as RowNode;
      expect(row.children.first.children, [line('前の行\nA')]);
    });

    test('the leading `|` keeps the preceding line its own block', () {
      expect(
        NaturalBlockParser.parse(fromReadme('前の行\n|A^B|', r'`前の行\n|A^B|`'))
            .children
            .map((c) => c.runtimeType),
        [ColumnNode, RowNode],
      );
    });

    test('omitting it is fine when nothing precedes the row', () {
      expect(NaturalBlockParser.parse('A^B|').children.single, isA<RowNode>());
    });
  });

  group('Tables', () {
    TableNode onlyTable(String source) =>
        NaturalBlockParser.parse(source).children.single as TableNode;

    /// The alignment each cell is drawn with: what it stated, else what its
    /// column stated. The resolution the README documents for consumers.
    List<List<BlockAlign?>> effective(TableNode table) => [
      for (final row in table.children)
        [
          for (var i = 0; i < table.columns.length; i++)
            (i < row.children.length ? row.children[i].align : null) ??
                table.columns[i],
        ],
    ];

    test('the README\'s worked example parses as the table it shows', () {
      final table = onlyTable(
        '~\n'
        '|<Item  ^>Price\n'
        '|apple  ^   100\n'
        '|orange ^    80\n'
        '~',
      );

      expect(table.children, hasLength(3));
      expect(table.columns, [
        BlockAlign.start,
        BlockAlign.end,
      ], reason: 'the leading `|` gives the first column a marker slot');
      expect(effective(table), [
        [BlockAlign.start, BlockAlign.end],
        [BlockAlign.start, BlockAlign.end],
        [BlockAlign.start, BlockAlign.end],
      ]);
    });

    test('a marker after the opening `~` describes the table, not the '
        'first cell', () {
      expect(onlyTable('~<Item^>Price|apple^100~').align, BlockAlign.start);
      expect(
        onlyTable('~|<Item^>Price|apple^100~')
            .children
            .first
            .children
            .first
            .align,
        BlockAlign.start,
      );
      expect(onlyTable('~|<Item^>Price|apple^100~').align, isNull);
    });

    test('with the `|` written at the end of each line instead, a marker '
        'lands after a newline and stays literal', () {
      // The reason the README recommends the leading `|`.
      final table = onlyTable('~Item^Price|\n<apple^100\n~');
      final firstCell = table.children[1].children.first;

      expect(firstCell.align, isNull);
      expect(
        (firstCell.children.single as TextNode).children.single,
        TextSpanNode(text: '<apple'),
      );
    });

    test('a line with no `^` becomes a one-cell row', () {
      expect(
        onlyTable(
          fromReadme('~A^B|note~', 'a line with no `^` becomes a one-cell row'),
        ).children[1].children,
        hasLength(1),
      );
      expect(
        onlyTable(
          fromReadme('~A|B~', 'a line with no `^` becomes a one-cell row'),
        ).children,
        hasLength(2),
      );
    });

    test(
      '`~|Item^>Price|...~` right-aligns the price column for every row',
      () {
        final table = onlyTable(
          fromReadme('~|Item^>Price|A^100|B^200~', '~|Item^>Price|apple^100~'),
        );

        expect(table.columns, [null, BlockAlign.end]);
        expect(effective(table), [
          [null, BlockAlign.end],
          [null, BlockAlign.end],
          [null, BlockAlign.end],
        ]);
      },
    );

    test('a marker on an individual cell overrides just that cell', () {
      expect(
        onlyTable(
          fromReadme(
            '~|Item^>Price|A^=100~',
            'a marker on an individual cell overrides',
          ),
        ).children[1].children[1].align,
        BlockAlign.center,
      );
    });

    test('`~=` is a centered table -- markers share one cluster', () {
      expect(
        onlyTable(fromReadme('~=A^B~', '`~=` is a centered table')).align,
        BlockAlign.center,
      );
    });

    test('a table ends only at `~` or the end of the document', () {
      expect(
        NaturalBlockParser.parse(
          fromReadme('~A^B|C^D^E|note~after', 'A table ends at `~`'),
        ).children.map((c) => c.runtimeType),
        [TableNode, ColumnNode],
      );
    });

    test(
      'a short row does not end the table -- the table records the width',
      () {
        final table = onlyTable('~A^B|C^D^E~');

        expect([for (final r in table.children) r.children.length], [2, 3]);
        expect(table.columns, hasLength(3), reason: 'the table is 3 wide');
      },
    );

    test('a table ends at the end of the document', () {
      expect(
        NaturalBlockParser.parse('~A^B').children.single,
        isA<TableNode>(),
      );
    });

    test('writing `~` again closes it', () {
      expect(
        NaturalBlockParser.parse(fromReadme('~A^B~C^D', 'A table ends at `~`'))
            .children
            .map((c) => c.runtimeType),
        [TableNode, RowNode],
      );
    });

    test('an empty block does not end a table, or `||` would be an invisible '
        'separator', () {
      expect(
        NaturalBlockParser.parse(
          fromReadme('~A^B||C^D~', 'contributes no node at all'),
        ).children.single,
        isA<TableNode>(),
      );
    });
  });

  group('Verbatim regions', () {
    test('an inline region is one line of three runs, the middle verbatim', () {
      // README: 比較は`a == b`です
      final children = onlyLine('比較は`a == b`です').children;
      expect(children, [
        TextSpanNode(text: '比較は'),
        VerbatimSpanNode(text: 'a == b'),
        TextSpanNode(text: 'です'),
      ]);
    });

    test('a fence on its own line gives one node, the command intact', () {
      // README's second example.
      expect(
        onlyBlock('`\ncat file.txt | grep foo | wc -l\n`').children.single,
        VerbatimNode(text: 'cat file.txt | grep foo | wc -l'),
      );
    });

    test('without a region that same command becomes three blocks', () {
      // The README's own argument for why regions exist.
      expect(
        NaturalBlockParser.parse('cat file.txt | grep foo | wc -l')
            .children
            .length,
        3,
      );
    });

    test('while `final x = a == b ? 1 : 2;` needs no region at all', () {
      // It used to be the README's headline example of prose that breaks --
      // four cells, back when `=` separated them. Moving the separator to
      // `^` retired the example, and this pins that it stays retired.
      expect(NaturalBlockParser.parse('final x = a == b ? 1 : 2;').children, [
        block('final x = a == b ? 1 : 2;'),
      ]);
    });

    test('a region can go in a table cell', () {
      final table =
          NaturalBlockParser.parse('~A^`x`|B^`y`~').children.single
              as TableNode;
      // A run, not a block: the cell sits on the same line as `A`, and a
      // region is a block only when it opens on a line of its own.
      expect(
        (table.children[0].children[1].children.single as TextNode)
            .children
            .single,
        VerbatimSpanNode(text: 'x'),
      );
    });

    test('nothing inside is a separator, a decoration, or an escape', () {
      expect(
        onlyBlock(r'`| ^ : \n :!`').children.single,
        VerbatimNode(text: r'| ^ : \n :!'),
      );
    });

    test('the fence run length sets the closer, so a doubled fence may '
        'contain a single backtick', () {
      expect(
        onlyBlock(fromReadme('``a `b` c``', 'may contain single backticks'))
            .children
            .single,
        VerbatimNode(text: 'a `b` c'),
      );
    });

    test('the newline directly against each fence belongs to that fence', () {
      expect(
        onlyBlock('`\ncode\n`').children.single,
        VerbatimNode(text: 'code'),
      );
    });

    test('written inline the content is exactly what was typed', () {
      expect(
        onlyLine('a`  b  `c').children[1],
        VerbatimSpanNode(text: '  b  '),
      );
    });

    test('an unclosed fence is not a region: it stays ordinary text and '
        'separators after it still work', () {
      final doc = NaturalBlockParser.parse(
        fromReadme('a`b|c', 'separators after it still work'),
      );
      expect(doc.children.length, 2);
      expect(doc.children.first, block('a`b'));
    });
  });

  group('Escape characters', () {
    test(r'`\|`, `\^`, `\:` and an escaped fence are literal characters', () {
      expect(runs(r'\|'), [TextSpanNode(text: '|')]);
      expect(runs(r'\^'), [TextSpanNode(text: '^')]);
      expect(runs(r'\:'), [TextSpanNode(text: ':')]);
      expect(runs(r'\`'), [TextSpanNode(text: '`')]);
    });

    test(r'`\\` renders as a literal backslash', () {
      expect(runs(r'\\'), [TextSpanNode(text: '\\')]);
    });

    test(
      r'inside a cluster `:---\%off` gives `%off` at -3, backslash gone',
      () {
        final span = runs(r':---\%off').single;
        expect(span.text, '%off');
        expect(span.decoration.sizeOffset, -3);
      },
    );

    test(r'the escape ends the cluster, so `:---\%%%` needs one backslash', () {
      final span = runs(r':---\%%%').single;
      expect(span.text, '%%%');
      expect(span.decoration.sizeOffset, -3);
    });

    test('everywhere else a backslash is just a backslash', () {
      survivesUntouched(r'\+');
      survivesUntouched(r'\!');
      survivesUntouched(r'C:\Users');
    });

    test(
      r'`\\^` is a cell holding a backslash followed by a real separator',
      () {
        final row =
            NaturalBlockParser.parse(r'\\^b').children.single as RowNode;
        expect(row.children.length, 2);
        expect(
          (row.children[0].children.single as TextNode).children.single,
          TextSpanNode(text: '\\'),
        );
      },
    );

    test(r'where a lone `\^` would just be a literal `^`', () {
      expect(runs(r'\^b'), [TextSpanNode(text: '^b')]);
    });
  });

  group('Filesystem paths', () {
    test(r'`C:\Users\you\a.png` comes through untouched', () {
      survivesUntouched(r'C:\Users\you\a.png');
    });

    test(
      'a doubled backslash collapses, so a UNC path is written with four',
      () {
        expect(runs(r'\\\\server'), [TextSpanNode(text: r'\\server')]);
      },
    );

    test('forward slashes avoid the question entirely', () {
      survivesUntouched('C:/Users/you/a.png');
    });
  });

  group('README usage examples', () {
    test('example 1: layout symbols reset styles at each boundary', () {
      // const input1 = "|:!Danger Zone^:%Safe Zone|";
      final row =
          NaturalBlockParser.parse(fromReadme('|:!Danger Zone^:%Safe Zone|'))
                  .children
                  .single
              as RowNode;
      TextSpanNode runOf(int i) =>
          (row.children[i].children.single as TextNode).children.single
              as TextSpanNode;
      expect(runOf(0).decoration.color, SemanticColor.danger);
      expect(runOf(0).text, 'Danger Zone');
      expect(runOf(1).decoration.color, SemanticColor.success);
      expect(runOf(1).text, 'Safe Zone');
    });

    test('example 2: ":++" is +2, ":--" right after nets back to base', () {
      // const input2 = ":++Huge Text:--Normal Text";
      final spans = runs(fromReadme(':++Huge Text:--Normal Text'));
      expect(spans[0].decoration.sizeOffset, 2);
      expect(spans[0].text, 'Huge Text');
      expect(spans[1].decoration.sizeOffset, 0);
      expect(spans[1].text, 'Normal Text');
    });
  });

  // Whitespace handling lives in `input_normalization_test.dart`, not here.
  // It was in this file once, which was a mistake: the README makes no claim
  // about it, so these tests had nothing to check against and quietly became
  // tests of the CHANGELOG instead. Every test in this file must be able to
  // name the README sentence it executes.
}
