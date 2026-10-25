# Design notes

Why the language and the tree are the way they are, and what they used to
be. The README says what the syntax does; this says why.

## Layout

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
  The newline that ends a decorated line belongs to that line's run and
  carries its decoration: Flutter sizes a line by the newline that ends it
  too. It used to open the next, undecorated run instead, which made a line
  of small text as tall as the line after it.
- Whitespace is content and is never trimmed, at the document's edges or
  anywhere else. A space the author typed is one they can see and delete,
  and trimming the ends would make the first and last line behave unlike
  every other line. The one thing that does disappear is a single blank
  line at each end of a *block*, which is what lets a block's symbol sit on
  a line of its own.

## Alignment

- A marker is read only at the start of a block, so `a > b`, `->`, and
  `List<String>` need no escaping. The cost is the first character of a
  document: `=>` there is a centered `>`. A backslash keeps a marker literal
  wherever one would be read, and only there; in the middle of a sentence
  there is nothing for it to cancel, so `a\<b` keeps its backslash.
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
  the same shape as `Tone.none`.
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

## Tables

- A table has to be declared rather than inferred. Its columns are as wide
  as their content and line up across rows, while plain rows split the
  width evenly -- and `Left^^Right` relies on that even split to push
  `Right` to the far edge.
- Both of a table's `~` belong to it, the way both fences belong to a raw
  region. It opens no block of its own, which is why a marker after the
  closing one is ordinary text and aligning what follows a table takes a
  `|`.
- A table ends at `~` or at the end of the document, and nowhere else. Rows
  are separated by `|`, so a line break on its own stays inside the cell.
- The tree records what was written, not what will be drawn.
  `TableNode.columns` holds what each column declared, and rows keep exactly
  the cells the author wrote, each carrying only its own marker, so
  `unstated` keeps meaning "the source said nothing" inside a table too.
  Resolving the two and squaring short rows off is the consumer's step.
- Rows are written one per line with a leading `|`. That `|` opens an empty
  block, which contributes nothing -- it is there so every line has the same
  shape and every row's first cell has a marker slot of its own. With the
  `|` at the end of each line instead, a marker would land after a newline
  and stay literal.
- A table has no alignment of its own. The block that holds it positions
  it, the way it positions everything else it holds, and a marker straight
  after the opening `~` is the first cell's, as after any symbol that starts
  a block. An earlier version gave the table a marker there too, which put
  two readers on one position and needed a rule for which of them a
  backslash belonged to.

## Decoration

- A bare `+ - ! % ? * @` is always literal, so `C++`, `100%`, `Really?!`,
  and `you@example.com` need no escaping. This is what the `:` prefix buys.
- `:@...:@` marks a run custom without saying what it means. The run's own
  text is the whole payload, so an implementation that does not recognise
  it still shows something a person can read.
- There are two tones, not three. `:?` (info) was dropped. It named
  nothing a writer means -- every sentence is information -- and it rendered
  in the same colour as `:@`, so it was a custom span without the underline.
  Three documents written against this spec by people seeing it for the first
  time used it once between them, and that once was to set an aside apart from
  the body, which is a block's job rather than a colour's. The other two stay
  because "careful" and "done" are things a writer means. Dropping it also
  frees `?`, one of the rarest characters left.
- The two are the ends of one axis, and named that way: `Tone.negative` and
  `Tone.positive`, with `Tone.none` between. They were `SemanticColor.danger`
  and `.success`, which were not opposites -- a danger is a risk ahead, a
  success an outcome behind -- although the parser already kept them in one
  field, where writing one replaces the other. `Tone` rather than a colour,
  because what a writer says is good or bad; red or green is the renderer's
  choice.

## Raw regions

- Called raw rather than verbatim: nothing inside is a separator, a
  decoration or an escape -- the promise a Dart raw string makes too.
- They are what makes code writable: without them `cat a | grep b` parses
  as three blocks. It used to reach further: while `=` separated cells,
  `final x = a == b ? 1 : 2;` was a four-cell row. Moving the separator to
  `^` retired that example. A marker built on `|` could never have been
  inline, since `|` always breaks a block, so the price is a fifth
  always-active character, `` ` ``.
- The fence's run length sets the closer: a region ends at the next run of
  exactly as many backticks -- how the language quotes its own syntax. A
  longer run used to close it and leave its extra backticks to open a region
  of their own.
- A region with nothing inside contributes no node, wherever it was written.
  An empty region quotes nothing, so there is nothing for the tree to
  record -- the same reading that drops an empty block and an empty run. A
  block-level one used to keep an empty `RawNode`, which made the block case
  an exception to the run case for no gain.
- A fence with nothing to close it opens a region all the same, running to
  the end of the document -- as a table with no closing `~` does. Whether a
  region opens is settled by the fence alone. The cost is that a stray
  backtick swallows the rest of the document.
- A region with a line break inside is a `RawNode`; one without is a
  `RawSpanNode`. Where it was written does not decide it, so a region in a
  row's cell or after a `|` is a block as soon as it spans lines, and an
  inline region never carries a line break that would have to end the
  line's decoration.

## The tree

- **A table is content.** It is written between a pair of `~` and arrives
  already formatted, exactly like a raw region, so it sits *inside* a
  block rather than beside one. That is what lets one block hold text, a
  table, and more text -- and what makes `|=` reach all of it. A table can
  also go in a row's cell, which it could not when it was a block itself.
- A table has its own rows and cells: `TableRowNode` and `TableCellNode`.
  They are not `RowNode` and `ColumnNode`, which divide the width they are
  given -- a table's line up with the rows above and below instead. Their
  own types are also what keeps a table out of a table: a cell holds only
  `FlatContentNode`s, so a table in a cell does not compile, and a cell is
  read by the one content parse that has no branch for one. A `~` met
  inside a table is therefore the one that ends it and never one that
  opens another.
- A `TextSpanNode` holds its text and one `SpanDecoration` rather than four
  separate fields. It is the very object the parser carries while reading,
  so a run's decoration and the reader's current decoration are not two
  ideas that happen to match. Neither inline node is a `ContentNode` -- a
  styled run only exists inside a line -- so misplacing one is a compile
  error.
- **Nothing in the tree corresponds to a line.** A block of three lines is
  one `TextNode` holding two `\n`s; what divides a column's children is a raw
  block or a table, and nothing else. The type was called `LineNode` and is
  now `ContentNode`, because the old name suggested a per-line structure
  that has never existed and quietly shaped design discussions about
  headings and list items, both of which would need exactly that.
- A node's constructor asserts the shape the parser promises, so a shape
  the parser never makes cannot be built by hand either. An empty
  `ColumnNode` stays legal -- it is how a row keeps an empty cell -- and so
  does an empty `TableCellNode`.
- A node keeps its children in an unmodifiable copy, so a tree cannot change
  after it is built: its equality and hash stay fixed, and a table's
  `columns`, worked out once, stay true to its rows.

## Code layout

- The tree and the reading of it are separate. `src/nodes.dart` holds every
  node class and no parsing at all -- one file, because `sealed` requires
  every subtype to live in the same library, which is the whole reason and
  not privacy. `src/parse/` holds one library per node, plus the readings
  several nodes share -- alignment markers, decoration clusters, raw
  regions. Their top-level `parseColumnNode`-style functions are ordinary
  public names inside `src/` and reach nobody outside it:
  `NaturalBlockParser.parse` is the only door. Being ordinary libraries,
  their imports say which nodes and which symbols each step of the reading
  depends on -- something a set of `part` files cannot say, because parts
  see everything.
- Each node reads itself. Every node's parse consumes only what belongs to
  it and stops in front of anything that is not its own. A separator belongs
  to the parent of the things it separates: the document and a table eat the
  `|` between their children, a row eats the `^` between its cells. A
  delimiter belongs to what it wraps: a table eats both of its `~`, a raw
  region both of its fences. There is no assembly pass and no shared mutable
  state.
- Whether something opens is settled by what has been read and at most the
  character after it: a fence opens a region on sight, and a `:` opens a
  cluster when a decoration character follows. The one read further is a
  region's content, to its closer, which decides whether it is a block.
- `SourceCursor` is one position in the source, the normalizing of line
  endings and the reading of escapes, and nothing else, importing none of
  the syntax. Which characters are markup is passed in, because it is a
  fact about the grammar and because it is not even constant: `%` is prose
  in a sentence and a symbol inside a decoration cluster. Escapes are the
  exception that stays, being the one rule that changes what a character
  *is*: past a backslash there is no symbol left for a node to see.
- What counts as markup is stated in one place, `src/markup.dart`, grouped
  by the node each symbol belongs to -- which is what decides who eats it.
  A layout character (`|`, `^`, in `layoutChars`) sits between nodes and
  belongs to none of them, so the parent that arranges them eats it. A
  content character (`~`, `` ` ``, in `contentChars`) is part of its node,
  which eats both ends -- it is sized to its own content, so it has to know
  where it stops. Coming in a pair is the consequence, not the reason.
- The characters are named for the construct each belongs to -- `columnChar`,
  `rowChar`, `tableChar` -- rather than for what it does, which varies: `|`
  begins a block as well as ending one, and `:` opens a cluster but resets
  inside one. A construct name also survives swapping the character, as `=`
  and `^` once were.
- A run of text is read against `textMarkup`, and `+` and `%` are absent
  from it -- which *is* the rule that `C++` and `100%` are prose. Inside a
  cluster they are live, so a backslash in front of one there is the
  cluster's to eat. Whoever alone would have read a character as markup
  eats the backslash that cancels it.
