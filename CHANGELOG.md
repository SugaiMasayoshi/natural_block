## 1.0.0

Initial release.

### Layout

- `|` separates vertical blocks, `^` separates the cells of a horizontal row,
  and `~` delimits a table (see Tables). The three form one hierarchy: each
  ends everything below it.
- A run of `^`-joined cells becomes one `RowNode`, so `a^b|c^d` is two rows
  rather than one four-cell row.
- An empty Column block contributes no node; an empty Row cell keeps its
  position, which is what makes `左^^右` push `右` to the far edge. A `^` at
  the very end of the source opens a cell like any other, so `左^右^` is
  three cells wherever the row ends and appending a character never changes
  the width of the row before it.
- A `|` ends the block before it. Reading it as "a new block starts here"
  agrees everywhere but one place: a row is properly written wrapped in
  `|`, and the leading one is not part of the row -- it is the full stop on
  whatever came before. Without it nothing ends the preceding line, so that
  line joins the row's first cell, since a cell holds lines and nothing said
  the cell began at the row. `^` cannot stand in for it: it separates cells
  within a block and has no authority to end one.
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

- `<`, `=`, `>` immediately after an unescaped `|`, `^`, or `~` set the block's
  `BlockAlign`. Anywhere else they are ordinary text, so `a > b`, `->`, and
  `List<String>` need no escaping.
- `align` is null when the source stated none, which is not the same as
  `BlockAlign.start`. A theme is free to draw an unstated block differently,
  and a block that wrote `<` opts out of that.
- The cell separator is `^` and the center marker is `=`; they were once the
  other way round. Three things argued for the swap. `<` `=` `>` is a set
  that reads itself -- `<` leans left, `>` leans right, `=` is balanced --
  where `^` means *up*, and had to be memorised. `=` is also too common to
  spend on a symbol that is active everywhere: over 207,217 lines of real
  documentation it appears on 3.17% of lines against `^`'s 0.40%, and as the
  cell separator it turned 5,016 lines of ordinary prose into rows (`x = 1`,
  `--flag=value`, every URL query string). Third, and noticed only after the
  first two had settled it: on a Japanese flick keyboard `<` `=` `>` sit on
  one key with the flick directions matching the meanings, and `^` shares a
  key with `|`.

### Tables

- `~` is the third layout symbol, one level above `|`: `^` separates the
  cells of a row, `|` separates rows and blocks, and `~` separates table
  regions from ordinary ones. Each ends everything below it, so a `~` ends
  whatever preceded it and starts the table in one stroke.
- **A table ends at `~` or at the end of the document, and nowhere else.**
  Everything between belongs to it: a short row does not end it, and a line
  with no `^` becomes a one-cell row. The table is as wide as its widest row.
- `TableNode.columns` holds what each column declared, and by its length how
  wide the table is. Rows keep exactly the cells the author wrote, each
  carrying only its own marker, so `align == null` keeps meaning "the source
  said nothing" inside a table too. A consumer resolves the two with
  `cell.align ?? table.columns[i]`, and squares short rows off itself.
- Write one row per line with a leading `|`. The `|` opens an empty block,
  which contributes nothing -- it is there so every line has the same shape
  and every row's first cell has a marker slot of its own. With the `|` at
  the end of each line instead, a marker would land after a newline and stay
  literal.
- Markers combine in one cluster: `~=` is a centered table. A marker written
  straight after the opening `~` describes the table, not its first cell.
- A column takes its alignment from the first row that has that column; a
  marker on an individual cell overrides just that cell.

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
  without it `cat a | grep b` parses as three blocks. It used to reach
  further: while `=` separated cells, `final x = a == b ? 1 : 2;` was a
  four-cell row. Moving the separator to `^` retired that example.
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
- `` ` `` is therefore an always-active character; a literal one in prose is
  written `` \` ``.

### Escaping

- `\` escapes what would otherwise be markup at that point: `\|`, `\^`,
  `\~`, `\:`, `` \` ``, `\\`, and any decoration character inside a cluster.
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

- Each node reads itself. A `Scanner` holds the one cursor and the escape
  and verbatim rules; every node's parse consumes only what belongs to it
  and stops in front of the symbol that ends it, which its owner then eats.
  `RowNode` consumes the `^` between cells but not the `|` that ends the
  row; `TableNode` consumes the `|` between rows but not the `~` that ends
  the table. There is no assembly pass and no shared mutable state.
- One consequence of that protocol, worth naming: several levels ask about
  the same position before anyone consumes it. Five callers ask whether a
  verbatim region opens at a given fence. The `Scanner` remembers the answer
  for the position it was read at, which is what makes asking repeatedly
  free -- roughly 2.5x on a document that is mostly code blocks.
- What that cost and what it bought, measured rather than claimed: the
  median function got much smaller, and the longest one got *bigger*. Of the
  nine functions that do the parsing, seven are 22 lines or fewer; the two
  that read a run of styled text -- `TextSpanNode._parse` (47) and
  `Scanner.read` (36) -- are the outliers. The separated parser it replaced
  had four functions over 20 lines, all of them part of one reading, and its
  longest was 36.
- `README.md`'s claims are executed as tests (`test/readme_test.dart`), so a
  statement in it that stops being true fails the suite.
