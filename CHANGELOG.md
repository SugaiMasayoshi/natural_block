## Unreleased

- Breaking: a `~` opens a table only alone on its line, and closes one only
  alone on its line, so `~/.bashrc` and `~ 約100円` at the start of a line
  are text where they opened a table that took in the rest of the document.
  A table's first row goes on the line after its `~`, and in a row's cell
  the closing `~` takes its own line before the `^` that ends the cell. A
  `\~` that would open nothing keeps its backslash, as `10\~20` does.
- Breaking: a `TextNode` is one line, holding the runs written on it, where
  it held the runs of several lines with the line breaks in their text.
  Lines written one after another are `TextNode`s side by side in their
  block or cell, and a blank line is a `TextNode` with no runs. A run's text
  never holds a line break, and is never empty.
- Breaking: a blank line at the end of the document is dropped, as it was
  after a table or a raw block, so a slide does not grow by the line left
  before the next one.
- A `\` at the start of a line or a cell keeps the markup after it as text
  wherever that markup could open something, after an alignment marker
  too: `=\|` is a centred `|`, where it kept the backslash.
- Breaking: a blank line after a table, a row or a spacer is a text of one
  blank line, where it was dropped, so `^A^\n\n=B` has one empty line
  between, as `A\n\n=B` has. Blank lines between a table's rows are still
  nothing.
- A line that holds only decoration, or only an empty raw region, is a blank
  line, where it could disappear: `:+\n` before a raw block, or at the end
  of the document.
- Breaking: a raw block opens only at the start of a line or a cell, at a
  fence of three or more backticks that does not close on its line, and
  closes at the next line that starts with a fence as long. An inline
  region stays on its line, closing at the end of the line when nothing
  closes it, so a forgotten backtick no longer turns the rest of the
  document into code. A block opened partway through a line, as
  `` a ```\nx\n``` `` was, or fenced with fewer than three backticks, is
  now inline.
- Breaking: a `RawNode` carries the `decoration` written before its fence,
  as a `RawSpanNode` carries the one around it, and is equal only to one
  with the same decoration. ```` :+``` ```` draws its code a step larger,
  where the decoration was dropped.

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
