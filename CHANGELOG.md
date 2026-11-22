## Unreleased

- Breaking: a `TextNode` holds its lines as `LineNode`s, each holding the
  runs written on it, where it held runs with the line breaks in their text.
  A blank line is a `LineNode` with no runs. A run's text never holds a line
  break, and is never empty.
- Breaking: a blank line after a table, a row or a spacer is a text of one
  blank line, where it was dropped, so `^A^\n\n=B` has one empty line
  between, as `A\n\n=B` has. Blank lines between a table's rows are still
  nothing.
- A line that holds only decoration, or only an empty raw region, is a blank
  line, where it could disappear: `:+\n` before a raw block, or at the end
  of the document.

## 0.4.0

- Breaking: a `RawSpanNode` carries the `decoration` in effect around it,
  which its text does not change, and is equal only to one with the same
  decoration. In ``:++a `x` b``, `x` is two steps larger, as `a` and `b` are.
  Every `InlineNode` has `text` and `decoration`, so a renderer reads them
  without telling the two kinds apart.

## 0.3.0

- Breaking: a line of `|` alone is a `SpacerNode`, space that shares out the
  height left over where the height is set; `||` takes twice the share. It
  stands between a document's blocks, and in a row's cell, where `|^` at
  the start of a line counts too. `\|` writes the line as text.
- Breaking: a row's cells are `CellNode`s, which stack blocks and spacers
  as a document does, where they were `ColumnNode`s. A spacer cuts a cell
  into blocks, each with the cell's alignment; an empty cell holds none.
- Breaking: the line break that ends a decorated line belongs to the
  undecorated run after it, where it was the last character of the
  decorated one. `:!red\nblack` is `"red"` (negative) then `"\nblack"`.
- `normalizeSource` returns the source as the parser reads it, with `\r\n`
  as `\n` and a final line break dropped.
- Every node records the span it was read from in `start` and `end`,
  counted in the source as `normalizeSource` returns it. Positions take no
  part in equality.
- `descendants` returns every node below a node, in the order they were
  written.
- `payloadArgument(payload, name)` reads a `name(<argument>)` payload, the
  shape `image(<source>)` has, from a custom run's text.

## 0.2.0

- Breaking: `~` opens a table only at the start of a line or of a row's
  cell, and closes it only at the start of a line. Elsewhere `~` is text, so
  `10~20` needs no escaping, and `\~` escapes only where a `~` would open or
  close a table.

## 0.1.0

- Initial release.
- Layout: `<` `=` `>` at the start of a line open an aligned block,
  `^...^` at the start of a line writes a row, and `~` wraps a table of
  such rows.
- Decoration: `:`-led clusters for size, tone, emphasis and custom runs.
- Raw regions between `` ` `` fences, inline or as a block.
- `NaturalBlockParser.parse` returns an immutable tree with structural
  equality.
