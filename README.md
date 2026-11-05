# natural_block

[日本語](README.ja.md)

A lightweight markup language for Dart that leaves ordinary prose alone.
`natural_block` parses layout (blocks, rows, tables, alignment), semantic
decoration (size, tone, emphasis), and raw code regions into a syntax tree
you can map to widgets. `C++`, `100%`, `a > b`, `10~20`, and
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

- `DocumentNode` holds `ColumnNode`s and `RowNode`s; a `RowNode` holds
  `ColumnNode` cells.
- A `ColumnNode` holds content: `TextNode`, `RawNode`, and `TableNode`.
- A `TextNode` holds `TextSpanNode`s (text with a `SpanDecoration`) and
  `RawSpanNode`s.
- A `TableNode` holds `TableRowNode`s of `TableCellNode`s, and `columns`
  holds each column's alignment.

## Syntax

### Layout

| Symbol | Meaning | Example |
|---|---|---|
| `<` `=` `>` | At the start of a line: a new block, aligned start, center, end | `=Title` |
| `^` | At the start of a line: a row, cells split by `^`, closed by a `^` | `^Left^Right^` |
| `~` | At the start of a line or a cell: a table of `^...^` rows, closed by a `~` at the start of a line | below |

- A block runs until a line that starts with `<`, `=`, `>` or `^`. Every
  other line stays in it, blank lines included. A newline is part of the
  text, and spaces are never trimmed.
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
  row may leave out its opening `^`, but not its closing one. A blank line between rows is nothing; write an empty row as
  `^^`. A column takes its alignment from the first row that has it; a
  marker on a cell overrides just that cell:

  ```
  ~
  <Item  ^>Price^
  apple  ^   100^
  orange ^    80^
  ~
  ```

- The last line break of the source, the one an editor adds when saving, is
  ignored.

### Decoration

A `:` followed by decoration characters forms a cluster. Each character
applies in order, and the decoration lasts until the end of the line or the
next block.

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

### Raw regions

Text between `` ` `` fences is taken exactly as written: no separators,
decoration, or escapes.

```text
比較は`a == b`です

`
cat file.txt | grep foo | wc -l
`
```

- A region with a line break inside is a block (`RawNode`); one without is
  inline (`RawSpanNode`). The newline right against each fence is dropped.
- A region closes at a run of exactly as many backticks as opened it, so
  ``` `` ``` can contain single backticks.
- An empty region produces nothing. An unclosed one runs to the end of the
  document.

### Escaping

A backslash escapes only what would otherwise be markup at that point:

- Anywhere: `\:`, `` \` ``, and `\\`.
- Inside a row or a table: `\^`.
- Inside a cluster: any decoration character. The escape also ends the
  cluster, so `:---\%%%` is `%%%` at -3.
- At the start of a line or a cell: `\<`, `\=`, `\>`, `\^`, `\~`.

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
