# natural_block

A lightweight, intuitive markup language parser for Dart. `natural_block` allows you to effortlessly define complex text layouts, semantic styling, and inline typography adjustments using simple ASCII symbols.

It's perfect for chat applications, document editors, or anywhere you need a rich text structure without the heavy boilerplate of HTML or Markdown.

## Features

* **Vertical Layout (Column)**
  Use the `|` (pipe) symbol to create column blocks. Spaces are content and are never trimmed; the one thing that disappears is a single blank line at each end of a block, so a block's symbol can sit on a line of its own.
* **Horizontal Layout (Row)**
  Use the `^` (caret) symbol to split text into horizontal row nodes.
  Layout symbols reset all decoration (size, tone, emphasis, custom marking) at the block boundary they create -- each block starts from a clean style.
* **Decoration clusters (`:`-led)**
  All decoration -- size, tone, emphasis, and custom marking -- is triggered by a `:` immediately followed by one or more decoration characters, forming a *cluster*. Each character in the cluster applies in order:
  * `:+` one step larger, `:-` one step smaller -- repeat the character to stack without retyping the colon (`:+++` is +3).
  * `:!` negative, `:%` positive -- the two ends of one tone, so writing one replaces the other. Each **toggles**: typing it again turns it back off.
  * `:*` Emphasis / Bold -- also toggles.
  * `:@` Custom text -- also toggles. See below.
  * `::` resets tone, emphasis, and custom marking together (a cluster whose only character is `:`). It does **not** reset the size offset.
  * Multiple characters can share one cluster to apply together, e.g. `:!*` applies the negative tone and Emphasis at the same time. Two clusters typed back-to-back are *not* the same as one combined cluster -- see [Combining decorations](#combining-decorations) below.
* **Custom text (`:@`)**
  Text between `:@` and `:@` is marked custom -- `TextSpanNode.decoration.isCustom` is true for it. The parser records only *that* a run is custom, never what it should do; the run's own text is the entire payload, and interpreting it (a URL to open, a section to jump to, a mention to resolve, an image to draw) belongs to the consuming app.

  ```dart
  NaturalBlockParser.parse(':@https://example.com:@ を参照');
  ```

  Keeping the payload human-readable is the point: an implementation that does not recognise a payload still renders it as ordinary text, so nothing is lost that a person cannot read.
* **Block alignment (`<`, `=`, `>`)**
  An alignment marker written *at the start of a block* sets how that block is positioned: `<` start, `=` center, `>` end. A block starts directly after the unescaped `|` or `^` that opens it, directly after the `~` that opens a table, and at the very start of the document -- so `<見出し` aligns the first block without a leading `|`. `ColumnNode.align` carries it. The `~` that *closes* a table opens nothing and the block goes on past it, so a marker after it is ordinary text -- align what follows a table by writing `|` first.

  ```dart
  NaturalBlockParser.parse('|<品名^=数量^>価格|');
  ```

  That position is the entire trigger -- anywhere else `<`, `=`, and `>` are ordinary text, which matters because `a > b`, `->`, `=>`, and `List<String>` are everywhere in normal prose. An escaped separator leaves a following marker alone too, so `a\^>b` is literally `a^>b`.

  **A document that begins with `<`, `=`, or `>` reads it as a marker**, so `=> x` at the very top is a centered `> x`. A backslash keeps it literal: `\=> x` is the text `=> x`. That works at the start of every block -- `|\<tag>` is a block whose text is `<tag>` -- and only there. In the middle of a sentence a marker means nothing, so there is nothing to cancel and `a\<b` keeps its backslash.

  **One character, and only the first.** Alignment is a single value, so a second marker could only contradict the first: `|<>a` is a start-aligned block whose text is `>a`. That is what separates this from a decoration cluster, which reads a run of characters because it has several axes to set -- `:+!*` says three different things, where `|<>` says one thing twice.
* **Why the cell separator is `^` and the center marker is `=`**
  They used to be the other way round. Three things argued for the swap, in this order.

  First, `<` `=` `>` is a set that reads itself: `<` leans left, `>` leans right, `=` is balanced. `^` means *up*, which is not *center* -- it was the one member of a triple that had to be memorised rather than seen.

  Second, `=` is too common a character to spend on a symbol that is active everywhere. Measured over 207,217 lines of real documentation, `=` appears on 3.17% of lines and `^` on 0.40%. As the cell separator, `=` turned 5,016 lines of ordinary prose into rows -- `x = 1`, `--flag=value`, and the query string of every URL. A separator has to be a character prose does not reach for, and `=` is one prose reaches for constantly.

  Third, and noticed only after the first two had settled it: on a Japanese flick keyboard `<` `=` `>` share a single key, and the flick directions match the meanings -- left for left, right for right. `^` and `|` share a key too, so both layout separators are one key apart.

* **Size, tone, emphasis, and custom marking are independent axes**
  None of them resets another. A size change survives a following tone/emphasis symbol and vice versa; only `|`, `^`, or `~` resets everything.
* **Bare punctuation is always literal -- no escaping needed**
  A `+`, `-`, `!`, `%`, `?`, `*`, or `@` with no `:` immediately before it is always ordinary text. This is the whole point of the `:` prefix: everyday prose like `C++`, `10-20`, `100%`, `well-known`, `Really?!`, or `you@example.com` renders completely unchanged, in both Japanese and English, with zero escaping.
* **A newline is a character, not a boundary**
  A block is one `TextNode` however many lines it has, and the newlines sit inside it as ordinary characters. A newline still does one thing: it resets decoration, so a cluster applies until the end of its line and cannot leak into the rest of the block. The newline that ends a decorated line is part of that line's run and carries its decoration, because a renderer sizes a line by the newline that ends it as well -- a line of small text would otherwise be as tall as the text after it. That is a rule the parser applies while reading, not a division the tree records. A single blank line at the start or end of a block is dropped, so a block's opening or closing symbol can sit on a line of its own. CRLF input is normalized first, so a document written on Windows parses identically.
* **An empty cell holds its place; an empty block does not**
  The two are treated differently on purpose. A Column block is *content*, so an empty one contributes no node at all -- `左||右` is two text nodes, not three, and an alignment marker does not change that. A Row cell is a *position*, so it survives even when blank: `左^^右` is three cells with an empty middle, which is what pushes `右` to the far edge. A `^` at the very end opens a cell too -- `左^右^` is three cells wherever the row ends, so appending a character never changes the width of the row before it.
* **A `|` ends the block before it**
  Reading `|` as "a new block starts here" gives the right answer everywhere but one place, and this is that place.

  A row is properly written `|A^B^C|`. The leading `|` is not part of the row -- it is the full stop on whatever came before. Leave it out and nothing ends the preceding line, so that line joins the row's *first cell*: a cell holds lines, and nothing said this cell began at the row. `前の行\nA^B|` is one row whose first cell holds two lines; `前の行\n|A^B|` is a text node and a row.

  This is also why the row's own symbol cannot do the job. `前の行\n^A^B` does not split anything -- `^` separates cells within a block and has no business ending one, so `前の行` simply becomes the first cell.

  Nothing throws and nothing is lost, so the difference only shows once it is rendered. When in doubt, write the leading `|`.
* **Tables (`~`)**
  `~` wraps a table, and both `~` belong to that table the way both fences belong to a raw region -- it *delimits* where `^` and `|` *separate*. And like a raw region, **a table is content**: it sits inside a block rather than beside one, so a block can hold text, a table, and more text, and an alignment written on that block reaches all of it. It can also go in a cell of a row. A table of one cell, `~注意~`, is also how to set a single thing apart in a frame. A table cannot go inside another table: a `~` met inside one is the closer, never an opener.

  ```
  ~
  |<Item  ^>Price
  |apple  ^   100
  |orange ^    80
  ~
  ```

  Write one row per line with a leading `|`. The `|` on the first row opens an empty block, which contributes nothing -- it is there so that every line has the same shape, and so that every row's first cell has a marker slot of its own. (`|<Item` aligns that cell; with the `|` written at the *end* of each line instead, the marker would land after a newline and stay literal.)

  A table's columns are as wide as their content and line up across every row; plain rows, by contrast, split the available width evenly. That difference is why a table has to be *declared* rather than inferred -- `Left^^Right` is three cells with an empty middle, written that way to push `Right` to the far edge, and it only does that because plain rows divide the width.

  **A table ends at `~` or at the end of the document, and nowhere else.** Everything in between belongs to it: a short row does not end it, and a line with no `^` becomes a one-cell row. The table is as wide as its widest row.

  A table has no alignment of its own. The block that holds it positions it, the way it positions everything else it holds: `|=~A^B~` centers the table. To center a table while the text around it stays put, give it a block of its own: `前文|=~A^B~|後文`. A marker written straight after the opening `~` is therefore the first cell's, as after any other symbol that starts a block: `~<Item^...` aligns the Item column, the same as `~|<Item^...`.

  A column takes its alignment from the first row that has that column, so `~|Item^>Price|apple^100~` right-aligns the price column for every row without repeating the marker; a marker on an individual cell overrides just that cell.

  **The tree records what was written, not what will be drawn.** `TableNode.columns` holds what each column declared (and, by its length, how wide the table is); every row keeps exactly the cells the author wrote, each carrying only the marker that cell itself had. Resolving the two is the consumer's step:

  ```dart
  final stated = row.children[i].align;
  final effective =
      stated == HorizontalAlign.unstated ? table.columns[i] : stated;
  ```

  This is what keeps `HorizontalAlign.unstated` meaning "the source said nothing" inside a table as well as outside. Squaring short rows off into a rectangle is likewise the renderer's job -- `natural_block_flutter` does both.
* **Raw regions (`` ` ``)**
  A pair of backticks opens and closes a region taken exactly as written. Nothing inside is a separator, a decoration, or an escape.

  ```text
  比較は`a == b`です

  `
  cat file.txt | grep foo | wc -l
  `
  ```

  This is what makes code writable at all. `cat a | grep b` is three blocks without it, and `assert(2^10 == 1024)` is a two-cell row -- the promise that ordinary prose survives untouched runs backwards for code, which is made of exactly the characters a layout language wants.

  It used to run much further backwards: while `=` separated cells, `final x = a == b ? 1 : 2;` was a four-cell row. Moving the separator to `^` retired that example -- assignments and comparisons now survive in prose on their own.

  **A region can go anywhere**: inside a sentence, alone on a line, or in a table cell. It is one construct, and what it holds is what the tree records -- a region with a line break inside is a `RawNode`, a block sitting among the lines of its column, while one without is a `RawSpanNode` beside the styled runs. To quote a single line as a block, put its fences on their own lines. That is what lets a renderer draw the first as a boxed code block and the second as a run of monospaced text. `` ` `` is the price: it is the fifth character that is always active, so a literal backtick in prose is written `` \` ``. A marker built on `|` could never have been inline, since `|` always breaks a block.

  The fence's run length sets the closing delimiter, so a region opened with ``` `` ``` ends at the next run of exactly two backticks and may contain runs of any other length. That is how the language quotes its own syntax.

  The newline directly against each fence is treated as part of that fence, so a fence can sit on its own line. Written inline the content is exactly what was typed.

  A region with nothing inside contributes no node, wherever it was written. An empty region quotes nothing, so there is nothing for the tree to record -- the same reading that drops an empty block and an empty run.

  **An unclosed fence runs to the end of the document**, the same as a table with no closing `~`. Whether a region opens is settled by the fence alone -- nothing searches ahead for a closer -- so what has been read is always enough to know where you are. The cost is that a stray backtick swallows everything after it, separators included; write a literal one as `` \` ``. CRLF is normalized before parsing, so line endings do not round-trip.
* **Escape characters**
  A backslash escapes whatever would otherwise be markup *at that point*, and nothing else. Which characters those are depends on where you are:

  * Anywhere: `\|`, `\^`, `\~`, `\:` and `` \` `` render as literal `|`, `^`, `~`, `:` and `` ` ``, and `\\` renders as a literal `\`.
  * **Inside a cluster**, every decoration character is live, so a backslash escapes those too. `:---\%off` gives `%off` at -3, with the backslash gone. The escape also ends the cluster, which is what lets one backslash cover a whole run: `:---\%%%` needs one, not three.
  * **At the start of a block**, an alignment marker is live, so `\<`, `\=` and `\>` give a literal `<`, `=` and `>`: `\=> x` at the top of a document is the text `=> x`. After a table's opening `~` the escape belongs to the first cell, whose text it precedes.
  * Everywhere else a backslash is just a backslash -- `\+`, `\!`, and `C:\Users` keep it, because nothing there needed escaping.

  Escaping the backslash is what makes it possible to put one immediately before a separator: `\\^` is a cell holding `\` followed by a real separator, where `\^` would just be a literal `^`.
* **Filesystem paths need no escaping**
  Because a backslash only escapes what would otherwise be markup, `C:\Users\you\a.png` comes through untouched. The one thing to know is that a doubled backslash collapses to one, so a UNC path has to be written `\\\\server` to come out as `\\server`.

  Forward slashes avoid the question entirely and work on Windows too, so prefer `C:/Users/you/a.png`.

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  natural_block: ^1.0.0
```

Or install it via the Dart CLI:

```bash
dart pub add natural_block
```

## Usage

Pass your markup text to `NaturalBlockParser.parse`. It will return a syntax tree (a `DocumentNode` holding `ColumnNode`, `RowNode`, `TableNode`, and the two kinds of line -- `TextNode` and `RawNode` -- where a `TextNode` holds `TextSpanNode`s and `RawSpanNode`s) that you can easily map to Flutter widgets like `Column`, `Row`, and `RichText`.

```dart
import 'package:natural_block/natural_block.dart';

void main() {

  // Example 1: Layout with tone clusters.
  // Layout symbols (| and ^) reset styles at each boundary they create.
  const input1 = "|:!Danger Zone^:%Safe Zone|";
  final nodes1 = NaturalBlockParser.parse(input1);
  print(nodes1);

  // Example 2: Inline size adjustment, stacked without retyping the colon.
  // ":++" is +2, ":--" right after is -2 more, netting back to the base size.
  const input2 = ":++Huge Text:--Normal Text";
  final nodes2 = NaturalBlockParser.parse(input2);
  print(nodes2);

  // Example 3: Bare punctuation needs no escaping at all -- only `:`, `|`,
  // `^`, `~` and `` ` `` are ever active, and even those take a `\`.
  const input3 = "It costs -100 and has 100% success rate.";
  final nodes3 = NaturalBlockParser.parse(input3);
  print(nodes3);
}
```

### Combining decorations

A single cluster can carry more than one decoration character, and each is applied in order -- `:!*` turns on the negative tone *and* Emphasis together:

```dart
NaturalBlockParser.parse(":!*緊急対応"); // tone: negative, emphasis: true, in one span
```

Writing two clusters back-to-back is *not* equivalent, because a `:` always continues extending the cluster it follows -- including a further `:`, which is read as a reset. `:!:*` opens the negative tone with `:!`, but the very next `:` is absorbed as a `::` reset before `*` opens Emphasis, so the tone is wiped out and only Emphasis survives:

```dart
NaturalBlockParser.parse(":!*結果");  // -> tone: negative, emphasis: true
NaturalBlockParser.parse(":!:*結果"); // -> tone: none,     emphasis: true  (negative was reset)
```

To combine symbols, always write them in one cluster.

For more comprehensive and advanced usage, please check the `/example` folder in the repository.

## Additional information

* **Source Code & Issues:** If you encounter any bugs, have feature requests, or want to contribute, please visit our [GitHub repository](https://github.com/SugaiMasayoshi/natural_block).
* **Contributions:** We welcome pull requests! Please ensure that all new features include unit tests covering edge cases (such as symbol escaping and boundary resets).
* **The grid.** `test/grid_test.dart` writes every pair of markup characters in every place a pair can be written -- nine contexts, 990 pairs -- and pins the shape of each resulting tree against `test/grid/<context>.txt`, listing the pairs that come out the same under one shape. The parser decides from the character it is on, the one after it, whether it stands at the start of a line, and a finite context, so pairs-in-context reach every decision it makes. When a change is meant to alter the output, read the diff, confirm only the intended pairs moved, and then regenerate:

  ```
  dart run tool/update_grid.dart
  ```

  Regenerating without reading the diff makes it stop being a net.

  The shapes leave out alignment and decoration *values*, and `!` stands for every decoration character and `<` for every alignment marker. `test/representative_test.dart` is what makes that sound: it swaps each representative for the rest of its kind over the same 990 inputs and checks no shape changes.
* **The syntax.** `test/syntax_test.dart` holds the published syntax: a few representative sources per construct, each with its whole tree, values included. It is the one place a value is checked -- which symbol sets which alignment or decoration -- and the rules no pair of characters can show, such as a column taking its alignment from the first row.
* **The property tests.** `test/property_test.dart` parses all 111,110 sources of up to five markup characters and checks only what must hold for any input at all: nothing throws, no node survives that should not exist (an empty run, a one-cell row), CRLF parses as LF, and escaping every symbol gives back exactly the text. It never says which tree is right, which is why the grid exists.
* **Support:** We aim to respond to issues within a few days. Feel free to open a discussion for any usage questions.
