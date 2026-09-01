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
  An alignment marker written *immediately* after an unescaped `|` or `=` sets how the block starting there is positioned: `<` start, `^` center, `>` end. `ColumnNode.align` carries it.

  ```dart
  NaturalBlockParser.parse('|<品名=^数量=>価格|');
  ```

  That position is the entire trigger -- anywhere else `<`, `^`, and `>` are ordinary text, which matters because `a > b`, `->`, `=>`, and `List<String>` are everywhere in normal prose. An escaped separator leaves a following marker alone too, so `a\=>b` is literally `a=>b`.
* **Size, color, emphasis, and actionability are independent axes**
  None of them resets another. A size change survives a following color/emphasis symbol and vice versa; only a layout symbol (`|` or `=`) resets everything.
* **Bare punctuation is always literal -- no escaping needed**
  A `+`, `-`, `!`, `%`, `?`, `*`, or `@` with no `:` immediately before it is always ordinary text. This is the whole point of the `:` prefix: everyday prose like `C++`, `10-20`, `100%`, `well-known`, `Really?!`, or `you@example.com` renders completely unchanged, in both Japanese and English, with zero escaping.
* **One line is one node**
  A block is split into lines on `\n`, and each line becomes its own `TextNode`. Decoration therefore does not carry across a newline -- a cluster applies until the end of its line. A single blank line at the start or end of a block is dropped, so a block's opening or closing symbol can sit on a line of its own without producing an empty node. CRLF input is normalized first, so a document written on Windows parses identically.
* **An empty cell holds its place; an empty block does not**
  The two are treated differently on purpose. A Column block is *content*, so an empty one contributes no node at all -- `左||右` is two text nodes, not three, and an alignment marker does not change that. A Row cell is a *position*, so it survives even when blank: `左==右` is three cells with an empty middle, which is what pushes `右` to the far edge.
* **Tables (`|~`)**
  Writing `~` immediately after a `|` declares that the rows which follow are a table, and writing `|~` again closes it. A table's columns are as wide as their content and line up across every row; plain rows, by contrast, split the available width evenly. That difference is why a table has to be *declared* rather than inferred -- `Left==Right` is three cells with an empty middle, written that way to push `Right` to the far edge, and it only does that because plain rows divide the width.

  A table also ends on its own at the first thing that cannot belong to it: a row with a different number of cells, anything that is not a row, or the end of the document. The explicit `|~` is for the one case those cannot cover -- more rows of the same shape that are not part of the table.

  Alignment markers combine with it in the same cluster (`|~^` is a centered table, meaningful because a table is sized to its content). Inside a table, each column takes its alignment from the first row, so `|~Item=>Price|` right-aligns the price column for every row without repeating the marker; a marker on an individual cell overrides just that cell.
* **Escape characters**
  A backslash escapes whatever would otherwise be markup *at that point*, and nothing else. Which characters those are depends on where you are:

  * Anywhere: `\|`, `\=`, `\:` render as literal `|`, `=`, `:`, and `\\` renders as a literal `\`.
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

Pass your markup text to `NaturalBlockParser.parse`. It will return a syntax tree (a `DocumentNode` holding `ColumnNode`, `RowNode`, `TableNode`, `TextNode`, and `TextSpanNode`) that you can easily map to Flutter widgets like `Column`, `Row`, and `RichText`.

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
