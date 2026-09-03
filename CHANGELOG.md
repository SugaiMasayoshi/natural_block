## 1.0.0

Initial release.

### Layout

- `|` separates vertical blocks, `=` separates the cells of a horizontal row.
- A run of `=`-joined cells becomes one `RowNode`, so `a=b|c=d` is two rows
  rather than one four-cell row.
- An empty Column block contributes no node; an empty Row cell keeps its
  position, which is what makes `左==右` push `右` to the far edge.
- A row is properly written wrapped in `|`. Omitting the leading one works
  only when nothing precedes the row on its own line; otherwise the
  preceding line is absorbed into the row's first cell, since a cell holds
  lines and nothing said the cell began at the row.
- A newline is a character, not a boundary: a block is one `TextNode`
  however many lines it has. The one thing a newline does is reset
  decoration, so a cluster cannot leak past the end of its line -- a rule
  the parser applies while reading rather than a division the tree records.
  A single blank line at the start or end of a block is dropped, so a
  block's symbol can sit on its own line. CRLF input is normalized, so a
  document written on Windows parses identically.
- Whitespace is content and is never trimmed, at the document's edges or
  anywhere else. A space the author typed is one they can see and delete,
  and trimming the ends would make the first and last line behave unlike
  every other line. The one thing that does disappear is a single blank
  line at each end of a *block*, which is what lets a block's symbol sit on
  a line of its own.
- Line endings are normalized to `\n` on the way in: CRLF and a lone CR
  both become one, and no `\r` survives into the text.

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

### Verbatim regions

- A pair of `` ` `` fences marks text taken exactly as written -- no
  separators, no decoration, no escapes. This is what makes code writable:
  without it `final x = a == b ? 1 : 2;` parses as a four-cell row.
- One construct, usable anywhere: inside a sentence, alone on a line, or in
  a table cell. Where it is written is what decides how a renderer draws it.
- The fence's run length sets the closer, so ``` `` ``` may contain single
  backticks -- how the language quotes its own syntax.
- The newline directly against each fence belongs to that fence, so a fence
  can sit on its own line.
- An unclosed fence is **not** a region: it stays ordinary text and later
  separators still work, so a stray backtick cannot swallow anything.
- A region that stands alone on its line is a `VerbatimNode`, a block that
  sits among the lines of its column; one written inside a sentence is a
  `VerbatimSpanNode` beside the styled runs. One syntax, and the tree
  records which of the two places it was written in.
- `` ` `` is therefore the fifth always-active character; a literal one in
  prose is written `` \` ``.

### Escaping

- `\` escapes what would otherwise be markup at that point: `\|`, `\=`,
  `\:`, `` \` ``, `\\`, and any decoration character inside a cluster.
  Elsewhere the backslash is kept, so `C:\Users\you` needs no escaping.

### AST

- `DocumentNode` (the root) holds `BlockNode`s: `RowNode`, `TableNode`,
  `ColumnNode`, and the two `LineNode`s -- `TextNode` and `VerbatimNode`.
  A `ColumnNode` holds only `LineNode`s, so a cell cannot contain a row or
  a table; stating that in the type keeps a later decision to allow it a
  visible change rather than something that silently always worked.
- A `TextNode` holds `InlineNode`s: `TextSpanNode` and `VerbatimSpanNode`.
  Neither is a `BlockNode` -- a styled run only exists inside a line -- so
  misplacing one is a compile error.
- Every node declares the exact child type it can hold.
- All nodes implement `==` / `hashCode` structurally.

### API

- `NaturalBlockParser.parse` is static; the class holds no state.

### Internals

- The scan and the assembly are separate: `NaturalBlockParser` decides where
  the source is cut, `DocumentBuilder` (private) turns the resulting blocks
  into a tree. `parse` went from 229 lines with nine mutable locals to 124,
  and an alignment is now passed as an argument rather than read out of a
  variable the scan writes. Behaviour is unchanged.
- `README.md`'s claims are executed as tests (`test/readme_test.dart`), so a
  statement in it that stops being true fails the suite.
