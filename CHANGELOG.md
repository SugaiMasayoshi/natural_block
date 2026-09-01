## 1.0.0

Initial release.

### Layout

- `|` separates vertical blocks, `=` separates the cells of a horizontal row.
- A run of `=`-joined cells becomes one `RowNode`, so `a=b|c=d` is two rows
  rather than one four-cell row.
- An empty Column block contributes no node; an empty Row cell keeps its
  position, which is what makes `左==右` push `右` to the far edge.
- One line is one `TextNode`. A single blank line at the start or end of a
  block is dropped, so a block's symbol can sit on its own line. CRLF input
  is normalized, so a document written on Windows parses identically.
- Surrounding ASCII whitespace is trimmed, but not Unicode whitespace --
  a leading ideographic space (U+3000) survives.

### Alignment

- `<`, `^`, `>` immediately after an unescaped `|` or `=` set the block's
  `BlockAlign`. Anywhere else they are ordinary text, so `a > b`, `->`, and
  `List<String>` need no escaping.

### Tables

- `|~` declares that the rows which follow are a table, and `|~` again
  closes it. A table also ends at a row of a different cell count, at
  anything that is not a row, or at the end of the document.
- Markers combine in one cluster: `|~^` is a centered table.
- Inside a table, a cell with no marker of its own inherits its column's
  alignment from the first row.

### Decoration

- `:`-led clusters: `:+` / `:-` size steps, `:!` danger, `:%` success,
  `:?` info, `:*` emphasis, `:@` actionable, `::` reset.
- Size, color, emphasis, and actionability are independent axes; only a
  layout symbol resets everything.
- A bare `+ - ! % ? * @` is always literal, so `C++`, `100%`, `Really?!`,
  and `you@example.com` need no escaping. This is what the `:` prefix buys.
- `:@...:@` marks a run actionable without saying what acting on it means.
  The run's own text is the whole payload.

### Escaping

- `\` escapes what would otherwise be markup at that point: `\|`, `\=`,
  `\:`, `\\`, and any decoration character inside a cluster. Elsewhere the
  backslash is kept, so `C:\Users\you` needs no escaping.

### AST

- `DocumentNode` (the root) holds `BlockNode`s: `TextNode`, `RowNode`,
  `ColumnNode`, `TableNode`. `TextSpanNode` is not a `BlockNode` -- a styled
  run only exists inside a line -- so misplacing one is a compile error.
- Every node declares the exact child type it can hold.
- All nodes implement `==` / `hashCode` structurally.

### API

- `NaturalBlockParser.parse` is static; the class holds no state.
