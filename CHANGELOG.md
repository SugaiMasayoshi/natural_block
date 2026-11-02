## 0.1.0

- Initial release.
- Layout: `<` `=` `>` at the start of a line open an aligned block,
  `^...^` at the start of a line writes a row, and `~` wraps a table.
- Decoration: `:`-led clusters for size, tone, emphasis and custom runs.
- Raw regions between `` ` `` fences, inline or as a block.
- `NaturalBlockParser.parse` returns an immutable tree with structural
  equality.
