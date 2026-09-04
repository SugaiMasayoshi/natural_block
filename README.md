# natural_block

A lightweight, intuitive markup language parser for Dart. `natural_block` allows you to effortlessly define complex text layouts, semantic styling, and inline typography adjustments using simple ASCII symbols.

It's perfect for chat applications, document editors, or anywhere you need a rich text structure without the heavy boilerplate of HTML or Markdown.

## Features

* **Vertical Layout (Column)**
  Use the `|` (pipe) symbol to create column blocks. Trims trailing spaces and newlines automatically.
* **Horizontal Layout (Row)**
  Use the `=` (equal) symbol to split text into horizontal row nodes.
  Layout symbols reset all decoration (size, color, emphasis, actionability) at the block boundary they create -- each block starts from a clean style.
* **Decoration clusters (`:`-led)**
  All decoration -- size, semantic color, emphasis, and actionability -- is triggered by a `:` immediately followed by one or more decoration characters, forming a *cluster*. Each character in the cluster applies in order:
  * `:+` one step larger, `:-` one step smaller -- repeat the character to stack without retyping the colon (`:+++` is +3).
  * `:!` Danger / Warning color, `:%` Success color, `:?` Info color -- each **toggles**: typing it again turns it back off.
  * `:*` Emphasis / Bold -- also toggles.
  * `:@` Actionable text -- also toggles. See below.
  * `::` resets color, emphasis, and actionability together (a cluster whose only character is `:`). It does **not** reset the size offset.
  * Multiple characters can share one cluster to apply together, e.g. `:!*` applies Danger color and Emphasis at the same time. Two clusters typed back-to-back are *not* the same as one combined cluster -- see [Combining decorations](#combining-decorations) below.
* **Actionable text (`:@`)**
  Text between `:@` and `:@` is marked actionable -- `TextSpanNode.isAction` is true for it. The parser records only *that* a run is actionable, never what acting on it should do; the run's own text is the entire payload, and interpreting it (a URL to open, a section to jump to, a mention to resolve, an image to draw) belongs to the consuming app.

  ```dart
  NaturalBlockParser.parse(':@https://example.com:@ を参照');
  ```

  Keeping the payload human-readable is the point: an implementation that does not recognise a payload still renders it as ordinary text, so nothing is lost that a person cannot read.
* **Block alignment (`<`, `^`, `>`)**
  An alignment marker written *immediately* after an unescaped `|`, `=`, or `~` sets how the block starting there is positioned: `<` start, `^` center, `>` end. `ColumnNode.align` carries it.

  ```dart
  NaturalBlockParser.parse('|<品名=^数量=>価格|');
  ```

  That position is the entire trigger -- anywhere else `<`, `^`, and `>` are ordinary text, which matters because `a > b`, `->`, `=>`, and `List<String>` are everywhere in normal prose. An escaped separator leaves a following marker alone too, so `a\=>b` is literally `a=>b`.
* **Size, color, emphasis, and actionability are independent axes**
  None of them resets another. A size change survives a following color/emphasis symbol and vice versa; only a layout symbol (`|`, `=`, or `~`) resets everything.
* **Bare punctuation is always literal -- no escaping needed**
  A `+`, `-`, `!`, `%`, `?`, `*`, or `@` with no `:` immediately before it is always ordinary text. This is the whole point of the `:` prefix: everyday prose like `C++`, `10-20`, `100%`, `well-known`, `Really?!`, or `you@example.com` renders completely unchanged, in both Japanese and English, with zero escaping.
* **A newline is a character, not a boundary**
  A block is one `TextNode` however many lines it has, and the newlines sit inside it as ordinary characters. A newline still does one thing: it resets decoration, so a cluster applies until the end of its line and cannot leak into the rest of the block. That is a rule the parser applies while reading, not a division the tree records. A single blank line at the start or end of a block is dropped, so a block's opening or closing symbol can sit on a line of its own. CRLF input is normalized first, so a document written on Windows parses identically.
* **An empty cell holds its place; an empty block does not**
  The two are treated differently on purpose. A Column block is *content*, so an empty one contributes no node at all -- `左||右` is two text nodes, not three, and an alignment marker does not change that. A Row cell is a *position*, so it survives even when blank: `左==右` is three cells with an empty middle, which is what pushes `右` to the far edge.
* **Wrap a row in `|`**
  A row is properly written `|A=B=C|`. Omitting the leading `|` works only when nothing precedes the row on its own line -- otherwise the preceding line is absorbed into the row's *first cell* rather than staying its own block, because a cell holds lines and nothing said the cell started at the row. `前の行\nA=B|` is one row whose first cell holds two lines; `前の行\n|A=B|` is a text node and a row. Nothing fails and nothing is lost, so this is only visible once it is rendered -- when in doubt, write the leading `|`.
* **Tables (`~`)**
  `~` is the third layout symbol, one level above `|`. Where `=` separates the cells of a row and `|` separates rows and blocks, `~` separates table regions from ordinary ones -- so a `~` both ends whatever preceded it and starts the table, exactly as `|` does one level down.

  ```
  ~
  |<Item  =>Price
  |apple  =   100
  |orange =    80
  ~
  ```

  Write one row per line with a leading `|`. The `|` on the first row opens an empty block, which contributes nothing -- it is there so that every line has the same shape, and so that every row's first cell has a marker slot of its own. (`|<Item` aligns that cell; with the `|` written at the *end* of each line instead, the marker would land after a newline and stay literal.)

  A table's columns are as wide as their content and line up across every row; plain rows, by contrast, split the available width evenly. That difference is why a table has to be *declared* rather than inferred -- `Left==Right` is three cells with an empty middle, written that way to push `Right` to the far edge, and it only does that because plain rows divide the width.

  **A table ends at `~` or at the end of the document, and nowhere else.** Everything in between belongs to it: a short row is padded with empty cells rather than thrown out, and a line with no `=` becomes a one-cell row. The table is as wide as its widest row.

  Alignment markers combine with it in the same cluster (`~^` is a centered table, meaningful because a table is sized to its content). A marker written straight after the opening `~` describes the *table*, not its first cell -- which is the other reason to write the leading `|` on every row: `~|<Item=...` aligns the Item column, where `~<Item=...` would align the table itself.

  A column takes its alignment from the first row that has that column, so `~|Item=>Price|apple=100~` right-aligns the price column for every row without repeating the marker; a marker on an individual cell overrides just that cell.
* **Verbatim regions (`` ` ``)**
  A pair of backticks opens and closes a region taken exactly as written. Nothing inside is a separator, a decoration, or an escape.

  ```text
  比較は`a == b`です

  `
  cat file.txt | grep foo | wc -l
  `
  ```

  This is what makes code writable at all. Without it, `final x = a == b ? 1 : 2;` becomes a four-cell row and `cat a | grep b` becomes three blocks -- `=` and `|` are exactly the characters code uses most, so the promise that ordinary prose survives untouched runs backwards for code.

  **A region can go anywhere**: inside a sentence, alone on a line, or in a table cell. It is one construct, and where you put it is what the tree records -- a region standing alone on its line is a `VerbatimNode`, a block sitting among the lines of its column, while one written inside a sentence is a `VerbatimSpanNode` beside the styled runs. That is what lets a renderer draw the first as a boxed code block and the second as a run of monospaced text. `` ` `` is the price: it is the fifth character that is always active, so a literal backtick in prose is written `` \` ``. A marker built on `|` could never have been inline, since `|` always breaks a block.

  The fence's run length sets the closing delimiter, so a region opened with ``` `` ``` ends at ``` `` ``` and may contain single backticks. That is how the language quotes its own syntax.

  The newline directly against each fence is treated as part of that fence, so a fence can sit on its own line. Written inline the content is exactly what was typed.

  **An unclosed fence is not a region** -- it stays ordinary text, and separators after it still work, so a stray backtick cannot swallow anything. CRLF is normalized before parsing, so line endings do not round-trip.
* **Escape characters**
  A backslash escapes whatever would otherwise be markup *at that point*, and nothing else. Which characters those are depends on where you are:

  * Anywhere: `\|`, `\=`, `\~`, `\:` and `` \` `` render as literal `|`, `=`, `~`, `:` and `` ` ``, and `\\` renders as a literal `\`.
  * **Inside a cluster**, every decoration character is live, so a backslash escapes those too. `:---\%off` gives `%off` at -3, with the backslash gone. The escape also ends the cluster, which is what lets one backslash cover a whole run: `:---\%%%` needs one, not three.
  * Everywhere else a backslash is just a backslash -- `\+`, `\!`, and `C:\Users` keep it, because nothing there needed escaping.

  Escaping the backslash is what makes it possible to put one immediately before a separator: `\\=` is a cell holding `\` followed by a real separator, where `\=` would just be a literal `=`.
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

Pass your markup text to `NaturalBlockParser.parse`. It will return a syntax tree (a `DocumentNode` holding `ColumnNode`, `RowNode`, `TableNode`, and the two kinds of line -- `TextNode` and `VerbatimNode` -- where a `TextNode` holds `TextSpanNode`s and `VerbatimSpanNode`s) that you can easily map to Flutter widgets like `Column`, `Row`, and `RichText`.

```dart
import 'package:natural_block/natural_block.dart';

void main() {

  // Example 1: Layout with semantic color clusters.
  // Layout symbols (| and =) reset styles at each boundary they create.
  const input1 = "|:!Danger Zone=:?Safe Zone|";
  final nodes1 = NaturalBlockParser.parse(input1);
  print(nodes1);

  // Example 2: Inline size adjustment, stacked without retyping the colon.
  // ":++" is +2, ":--" right after is -2 more, netting back to the base size.
  const input2 = ":++Huge Text:--Normal Text";
  final nodes2 = NaturalBlockParser.parse(input2);
  print(nodes2);

  // Example 3: Bare punctuation needs no escaping at all -- only `:`, `|`,
  // and `=` are ever active symbols, and even those can be escaped with `\`.
  const input3 = "It costs -100 and has 100% success rate.";
  final nodes3 = NaturalBlockParser.parse(input3);
  print(nodes3);
}
```

### Combining decorations

A single cluster can carry more than one decoration character, and each is applied in order -- `:!*` turns on Danger color *and* Emphasis together:

```dart
NaturalBlockParser.parse(":!*緊急対応"); // color: danger, emphasis: true, in one span
```

Writing two clusters back-to-back is *not* equivalent, because a `:` always continues extending the cluster it follows -- including a further `:`, which is read as a reset. `:!:*` opens Danger with `:!`, but the very next `:` is absorbed as a `::` reset before `*` opens Emphasis, so Danger is wiped out and only Emphasis survives:

```dart
NaturalBlockParser.parse(":!*結果");  // -> color: danger, emphasis: true
NaturalBlockParser.parse(":!:*結果"); // -> color: none,   emphasis: true  (danger was reset)
```

To combine symbols, always write them in one cluster.

For more comprehensive and advanced usage, please check the `/example` folder in the repository.

## Additional information

* **Source Code & Issues:** If you encounter any bugs, have feature requests, or want to contribute, please visit our [GitHub repository](https://github.com/SugaiMasayoshi/natural_block).
* **Contributions:** We welcome pull requests! Please ensure that all new features include unit tests covering edge cases (such as symbol escaping and boundary resets).
* **Support:** We aim to respond to issues within a few days. Feel free to open a discussion for any usage questions.
