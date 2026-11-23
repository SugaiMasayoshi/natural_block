# natural_block

[日本語](README.ja.md)

A lightweight markup language for Dart that leaves ordinary prose alone.
`natural_block` parses layout (blocks, rows, tables, alignment, spacers),
semantic decoration (size, tone, emphasis), and raw code regions into a
syntax tree you can map to widgets. `C++`, `100%`, `a > b`, `10~20`, and
`you@example.com` need no escaping.

To draw the tree in Flutter, use
[natural_block_flutter](https://github.com/SugaiMasayoshi/natural_block_flutter).

## Getting started

```
dart pub add natural_block
```

natural_block files use the extension `.nblk`. For syntax highlighting in
VS Code and Open VSX editors, see the
[natural_block extension](https://github.com/SugaiMasayoshi/natural_block_editors).

## Usage

```dart
import 'package:natural_block/natural_block.dart';

void main() {
  final document = NaturalBlockParser.parse('^:!Danger Zone^:%Safe Zone^');
  print(document);
}
```

`parse` never throws and returns a `DocumentNode`. The tree is immutable and
compares structurally:

- `DocumentNode` holds `ColumnNode`s, `RowNode`s and `SpacerNode`s; a
  `RowNode` holds `CellNode`s as its cells, and a `CellNode` holds
  `ColumnNode`s and `SpacerNode`s, as a document does.
- A `ColumnNode` holds content: `TextNode`, `RawNode`, and `TableNode`.
- A `TextNode` is one line, holding `TextSpanNode`s (text with a
  `SpanDecoration`) and `RawSpanNode`s. A blank line holds none.
- A `TableNode` holds `TableRowNode`s of `TableCellNode`s, and `columns`
  holds each column's alignment.

Every node records where it was read from in `start` and `end`. The offsets
count in the source with its line breaks written as `\n` and its final line
break dropped, which `normalizeSource` returns. Positions take no part in
equality. `descendants` returns every node below a node, in the order they
were written.

```dart
final source = ':@page:@';
final document = NaturalBlockParser.parse(source);
for (final node in document.descendants) {
  if (node case TextSpanNode(:final start?, :final end?)) {
    print(normalizeSource(source).substring(start, end));
  }
}
```

## Syntax

### Layout

| Symbol | Meaning | Example |
|---|---|---|
| `<` `=` `>` | At the start of a line: a new block, aligned start, center, end | `=Title` |
| `^` | At the start of a line: a row, cells split by `^`, closed by a `^` | `^Left^Right^` |
| `~` | At the start of a line or a cell: a table of `^...^` rows, closed by a `~` at the start of a line | below |
| `\|` | On a line of its own: a spacer, sharing out the height left over; `\|\|` takes twice as much | below |

- A block runs until a line that starts with `<`, `=`, `>` or `^`, or a
  line of `|` alone. Every other line stays in it, blank lines included, as
  a line of its text. Spaces are never trimmed.
- A blank line is a line with nothing on it: `上\n\n=下` is a text of `上`
  and a blank line, and `^A^\n\n=下` puts a text of one blank line between
  the row and `下`. A line that holds only decoration, such as `:+`, is
  blank too.
- A row ends at a `^` that ends a line, or at the end of the document. A cell
  can hold several lines (`^Left\nsecond line^Right^`). An empty cell keeps
  its place, so `^Left^^Right^` pushes `Right` to the far edge.
- A marker at the start of a line aligns the block it opens; one after a `^`
  aligns that cell. `=^A^B^>C^` centers every cell that does not say
  otherwise. Only one marker is read: `<>a` is a start-aligned `>a`.
- A table opens at a `~` at the start of a line or of a row's cell, and
  closes at a `~` at the start of a line inside it, or at the end of the
  document. Its rows are read like rows outside it, so a cell can hold
  several lines, and a row also ends at the line that closes the table. A
  row may leave out its opening `^`, but not its closing one. A table holds
  only rows, so a blank line between them only spaces out the source; write
  an empty row as `^^`. A column takes its alignment from the first row that has it; a
  marker on a cell overrides just that cell:

  ```
  ~
  <Item  ^>Price^
  apple  ^   100^
  orange ^    80^
  ~
  ```

- Spaces after a spacer are ignored. Where the height is not set, a spacer
  takes none.

  ```
  |
  =Title
  |
  ```

- A row's cell is as tall as its row, so a spacer at the head of a cell or
  of a line in it places the cell's content. A `|^` at the start of a line
  is a spacer that then closes the cell.

  ```
  ^Image^|
  Caption
  |^
  ```

- A `|` in a table's cell, or with text after it, is text.

- The last line break of the source, the one an editor adds when saving, is
  ignored.

### Decoration

A `:` followed by decoration characters forms a cluster. Each character
applies in order, and the decoration lasts until the end of the line or the
next block. The line break that ends a line is never decorated.

| Cluster | Meaning |
|---|---|
| `:+` `:-` | One size step larger or smaller; repeat to stack (`:+++`) |
| `:!` `:%` | Negative or positive tone; toggles, and one replaces the other |
| `:*` | Emphasis; toggles |
| `:@` | Custom run; toggles. The app decides what the text means |
| `::` | Resets tone, emphasis, and custom marking, but not size |

Combine characters in one cluster: `:!*` is negative and emphasized. Two
clusters back to back are different, because a following `:` is read as a
reset -- `:!:*` leaves only emphasis.

Without a `:` in front, `+ - ! % * @` are ordinary text.

A custom run's text is its whole payload, such as a URL or an image path:

```dart
NaturalBlockParser.parse(':@https://example.com:@ を参照');
```

A payload that takes an argument is written `name(<argument>)`, as
`image(<source>)` is. `payloadArgument(text, 'note')` gives what is inside
`note(...)`, or null when the text is not one.

### Raw regions

Text between `` ` `` fences is taken exactly as written: no separators,
decoration, or escapes.

````text
比較は`a == b`です

```
cat file.txt | grep foo | wc -l
```
````

- A fence of three or more backticks at the start of a line or a cell that
  does not close on its line opens a block (`RawNode`). Decoration written
  before the fence is the block's: ```` :+``` ```` draws the code a step
  larger. The block runs to the next line that starts with a fence as
  long, or to the end of the document, and anything after the closing fence
  continues as text. What follows the
  opening fence on its line is the block's first line: ```` ```dart ````
  starts with `dart`. The line breaks right against the fences are dropped.
- Any other region is inline (`RawSpanNode`) and stays on its line: it
  closes at a run of exactly as many backticks as opened it, so ``` `` ```
  can contain single backticks, or at the end of the line.
- An empty region produces nothing.

### Escaping

A backslash escapes only what would otherwise be markup at that point:

- Anywhere: `\:`, `` \` ``, and `\\`.
- Inside a row or a table: `\^`.
- Inside a cluster: any decoration character. The escape also ends the
  cluster, so `:---\%%%` is `%%%` at -3.
- At the start of a line or a cell: `\<`, `\=`, `\>`, `\^`, `\~`, and a `\|`
  that would be a spacer.

Everywhere else a backslash is kept, so `C:\Users\you` needs no escaping. A
doubled backslash still collapses to one: write `\\\\server` for
`\\server`.

## Additional information

- Bugs and feature requests:
  [GitHub issues](https://github.com/SugaiMasayoshi/natural_block/issues).
- Why the syntax is the way it is: [doc/design.md](doc/design.md)
  (in Japanese).
- Contributing: a change to the syntax shows up in the grid tests; see
  the tests section of [doc/design.md](doc/design.md#テスト).
