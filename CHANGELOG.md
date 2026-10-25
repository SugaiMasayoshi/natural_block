## 0.1.0

- Initial release.
- Layout: `|` stacks blocks, `^` splits a block into a row, `~` wraps a
  table, and `<` `=` `>` at the start of a block align it.
- Decoration: `:`-led clusters for size, tone, emphasis and custom runs.
- Raw regions between `` ` `` fences, inline or as a block.
- `NaturalBlockParser.parse` returns an immutable tree with structural
  equality.
