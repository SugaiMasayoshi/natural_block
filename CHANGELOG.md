## 1.0.0

Initial release -- the version number and the `homepage` say publishable, but
this package has not been published to pub.dev. Nothing depends on it outside
this repository, which is why the entries below describe changes freely.

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

- `<`, `=`, `>` at the start of a block set its `HorizontalAlign`. A block
  starts after the `|` or `^` that opens it, after a table's opening `~`, and at
  the very start of the document, so the first block needs no leading `|` to be
  aligned. Anywhere else they are ordinary text, so `a > b`, `->`, and
  `List<String>` need no escaping. The cost is the first character of a
  document: `=>` there is a centered `>`, and since these three are markup
  nowhere else a backslash cannot keep it literal -- a leading newline can.
- One marker, not a run of them: `|<>a` is a start-aligned block whose text is
  `>a`. Alignment is a single value on a single axis, so a second marker could
  only contradict the first, and settling that would be a rule the language did
  not need. A decoration cluster reads a run because it has several axes --
  `:+!*` says three different things where `|<>` says one thing twice.
- `align` is `HorizontalAlign.unstated` when the source wrote no marker,
  which is not the same as `HorizontalAlign.start`. A theme is free to draw
  an unstated block differently, and a block that wrote `<` opts out of
  that. A value rather than `null`, because the tree records what the
  source said and "nothing was written here" is something it said --
  the same shape as `SemanticColor.none`.
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
  cells of a row and `|` separates rows and blocks, while `~` *delimits* --
  it wraps a table, and both of its `~` belong to that table, the way both
  fences belong to a verbatim region. Each symbol still ends everything
  below it, so a `~` ends whatever preceded it; it just opens no block of
  its own, which is why a marker after the closing one is ordinary text and
  aligning what follows a table takes a `|`.
- **A table ends at `~` or at the end of the document, and nowhere else.**
  Everything between belongs to it: a short row does not end it, and a line
  with no `^` becomes a one-cell row. The table is as wide as its widest row.
- `TableNode.columns` holds what each column declared, and by its length how
  wide the table is. Rows keep exactly the cells the author wrote, each
  carrying only its own marker, so `unstated` keeps meaning "the source
  said nothing" inside a table too. A consumer resolves the two -- take the
  column's when the cell stated nothing -- and squares short rows off
  itself.
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
  `:*` emphasis, `:@` actionable, `::` reset.
- Size, color, emphasis, and actionability are independent axes; only a
  layout symbol resets everything.
- A bare `+ - ! % ? * @` is always literal, so `C++`, `100%`, `Really?!`,
  and `you@example.com` need no escaping. This is what the `:` prefix buys.
- `:@...:@` marks a run actionable without saying what acting on it means.
  The run's own text is the whole payload.
- There are two semantic colors, not three. `:?` (info) was dropped. It named
  nothing a writer means -- every sentence is information -- and it rendered
  in the same colour as `:@`, so it was an action span without the underline.
  Three documents written against this spec by people seeing it for the first
  time used it once between them, and that once was to set an aside apart from
  the body, which is a block's job rather than a colour's. `danger` and
  `success` stay because "careful" and "done" are things a writer means; note
  that they are not opposites, which is a loose end rather than a design.
  Dropping it also frees `?`, one of the rarest characters left.

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

- `DocumentNode` (the root) holds `LayoutNode`s -- `ColumnNode` and
  `RowNode`, the two that say how what is inside them is arranged. A
  `ColumnNode` holds `ContentNode`s: `TextNode`, `VerbatimNode` and
  `TableNode`.
- **A table is content.** It is written between a pair of `~` and arrives
  already formatted, exactly like a verbatim region, so it sits *inside* a
  block rather than beside one. That is what lets one block hold text, a
  table, and more text -- and what makes `|=` reach all of it. A table can
  also go in a row's cell, which it could not when it was a block itself.
- A table has its own rows and cells: `TableRowNode` and `TableCellNode`.
  They are not `RowNode` and `ColumnNode`, which divide the width they are
  given -- a table's line up with the rows above and below instead. Their
  own types are also what keeps a table out of a table: a cell is read by
  the one content parse that has no branch for one, so a `~` met inside a
  table is the one that ends it and never one that opens another.
- A `TextNode` holds `InlineNode`s: `TextSpanNode` and `VerbatimSpanNode`.
- A `TextSpanNode` holds its text and one `SpanDecoration` -- the size
  offset, the semantic color, and the two flags -- rather than four separate
  fields. It is one thing: the very object the parser carries while reading,
  so a run's decoration and the reader's current decoration are not two ideas
  that happen to match. The type is public because the rest of the tree's
  vocabulary (`HorizontalAlign`, `SemanticColor`) is, and a consumer writing its
  own builder should be able to name what it is handed.
  Neither is a `ContentNode` -- a styled run only exists inside a line --
  so misplacing one is a compile error.
- **Nothing in the tree corresponds to a line.** A newline is a character, so
  a `TextNode` runs across as many of them as the author wrote -- a block of
  three lines is one node holding two `\n`s. What divides a column's children
  is a verbatim region written on a line of its own, and nothing else. The
  type was called `LineNode` and is now `ContentNode`, because the old name
  suggested a per-line structure that has never existed and quietly shaped
  design discussions about headings and list items, both of which would need
  exactly that.
- Every node declares the exact child type it can hold.
- All nodes implement `==` / `hashCode` structurally.

### API

- `NaturalBlockParser.parse` is static; the class holds no state.

### Internals

- The tree and the reading of it are separate. `src/nodes.dart` holds every
  node class and no parsing at all -- one file, because `sealed` requires
  every subtype to live in the same library, which is the whole reason and
  not privacy. `src/parse/` holds one library per node, whose top-level
  `parseColumnNode`-style functions are ordinary public names inside `src/`
  and reach nobody outside it: `NaturalBlockParser.parse` is the only door.
  Being ordinary libraries, their imports say which nodes and which symbols
  each step of the reading depends on -- something a set of `part` files
  cannot say, because parts see everything.
- Each node reads itself. A `SourceCursor` holds the one position and
  everything that must be resolved before a node can read a character -- line endings,
  escapes, verbatim regions; every node's parse consumes only what belongs
  to it and stops in front of the symbol that ends it, which its owner eats.
  `RowNode` consumes the `^` between cells but not the `|` that ends the
  row; `TableNode` consumes the `|` between rows but not the `~` that ends
  the table. There is no assembly pass and no shared mutable state.
- One consequence of that protocol, worth naming: several levels ask about
  the same position before anyone consumes it. Four levels ask whether a
  verbatim region opens at a given fence, because a child stops in front of
  what is not its own and its owner then asks again. Asking is made cheap
  rather than remembered: finding the closing fence builds no string, and
  only the level that consumes the region cuts the text out. An earlier
  version cached the answer inside the cursor instead, which bought about
  1.15x on a document that is mostly code blocks and cost the cursor the one
  piece of this language's grammar it had no other reason to know.
  `benchmark/verbatim_cost.dart` is the measurement.
- What that cost and what it bought, measured rather than claimed. Counting
  code lines only, blanks and comments excluded: of the sixteen functions
  that do the parsing, fifteen are 22 lines or fewer, and the one outlier is
  `parseTextSpanNode` at 27 -- the run of styled text, which is where
  decoration, newlines and every layout symbol meet. The separated parser it
  replaced did that same reading in one function of 90 lines, and its entry
  point was 36. `lib` went from 581 code lines to 558.
- `SourceCursor` is one position in the source and the reading of escapes,
  and nothing else -- 43 lines, importing none of the syntax. Which
  characters are markup is passed in, because it is a fact about the grammar
  and because it is not even constant: `%` is prose in a sentence and a
  symbol inside a decoration cluster. Escapes are the exception that stays,
  being the one rule that changes what a character *is*: past a backslash
  there is no symbol left for a node to see.
- Everything else that reads the source is a node saying what it is. Only
  the node library imports `SourceCursor` at all, and nothing extends it:
  `VerbatimNode._opensAt` and `VerbatimSpanNode._opensAt` answer whether one
  of those starts here (the same fence, told apart by whether it was written
  on a line of its own), and `HorizontalAlign._takeSeparator` eats the layout
  symbol that opens something along with the markers describing it. It
  lives on the alignment rather than on any node because the nodes an
  alignment lands on -- a column, a table, a table's cell -- share no
  ancestor closer than the root, and that alignment is the one thing they
  do have in common.
- What counts as markup is likewise stated by the level that decides it, not
  centrally. `TextSpanNode` names the symbols that end a run of text and can
  be escaped in one; `SpanDecoration` names the wider set that is live
  inside a cluster. The difference between the two *is* the rule that `C++`
  and `100%` are prose: `+` and `%` are absent from the first list.
- `README.md`'s claims are executed as tests (`test/readme_test.dart`), so a
  statement in it that stops being true fails the suite.
