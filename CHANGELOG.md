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
