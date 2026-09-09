/// The syntax tree, and the parser -- they are the same thing here.
///
/// Every node reads itself. There is no separate pass that walks the source
/// and assembles nodes afterwards; a node's `_parse` takes the one [SourceCursor]
/// and returns that node. Which is why this is one library made of parts:
/// `_parse` is private, so "who may call this" and "who owns this" are the
/// same question, and a concern that has drifted into the wrong file shows
/// up as a node type named where it does not belong.
///
/// **The one contract.** A node consumes only what is its own and stops in
/// front of the symbol that ends it. The owner of that symbol eats it. The
/// three layout symbols form one hierarchy, each ending everything below it:
///
/// | node | consumes | stops before |
/// |---|---|---|
/// | `TextSpanNode`, `VerbatimSpanNode` | — | `^` `\|` `~` |
/// | `ColumnNode` | the `\|` that opened it | `^` `\|` |
/// | `TableCellNode` | the `\|` or `^` that opened it | `^` `\|` `~` |
/// | `RowNode` | the `^` between its cells | `\|` `~` |
/// | `TableRowNode` | the `^` between its cells | `\|` `~` |
/// | `TableNode` | its own `~` at each end | — |
/// | `DocumentNode` | — | — |
///
/// **Each block eats the separator that opened it**, and a delimiter belongs
/// to what it wraps. So a `|` is read by the block it opens, a `~` by the
/// table, a fence by the region -- and `DocumentNode` consumes nothing at
/// all: it has only to ask for blocks until the source runs out.
///
/// That is also why an alignment marker lands where it does. `|<a` opens a
/// cell and describes it; if a `^` turns up afterwards the block becomes a
/// row *around* that cell, and the marker is still the cell's. Read one
/// level up instead, the same marker would look like it described the row
/// and then quietly settle on its first cell.
///
/// The `^` is the exception, and it has to be: the first cell of a row has
/// no `^` in front of it, so only the row can tell the difference between
/// opening a cell and starting one.
///
/// So `|` is not "a new block starts here" -- it is the full stop on what
/// came before, and it means "next sibling" at whichever level is reading.
///
/// **The newline against a boundary.** One newline touching a structural
/// boundary belongs to the boundary rather than to the text. It is what
/// makes `|Item|Price` and
///
/// ```
/// |
/// Item
/// |
/// Price
/// ```
///
/// the same document: with no line-level structure in this language, the
/// only way to put a separator on its own line is to write newlines around
/// it, and those newlines must not become content. Two of them still do --
/// `a\n\n|b` keeps one -- so a blank line is written by asking for it.
///
/// Three boundaries, and each is dropped by the only node that can see it:
///
/// | boundary | who drops it |
/// |---|---|
/// | the start of a block | [ColumnNode], before it reads anything |
/// | the end of a run of content | [TextNode], from the last span it read |
/// | after a region's closing fence | [VerbatimNode], having just eaten it |
///
/// It cannot be one place, and in particular it cannot be [SourceCursor].
/// Whether the newline sits against a boundary is not a question about the
/// next character: `` a\n`c` `` ends the text, `` a\n`b `` does not, and
/// `a\n:b` does not -- same character after the newline, opposite answers,
/// because a fence that never closes and a `:` that opens no cluster are
/// text. Only the node that has resolved which candidates are real can say.
///
/// **What the tree records.** What the source said, never what a renderer
/// needs. `align` is `unstated` when nothing was written, which is not
/// [HorizontalAlign.start]; a table keeps its columns rather than stamping them
/// onto every cell; short rows are not padded. Resolving those for drawing
/// is the consumer's step.
///
/// **Where to start reading.** [NaturalBlockParser.parse] is the way in and
/// [DocumentNode] is where the work starts. The parts below are listed in
/// the order they are reached from there: the spans a run of text is made
/// of, then that content, then the blocks, then the document.
///
/// Note there is no line in that list. A newline is a character, so nothing
/// in the tree corresponds to one -- see [ContentNode].
library;

import 'package:collection/collection.dart';

import 'decoration_action.dart';
import 'layout_symbols.dart';
import 'source_cursor.dart';
import 'verbatim_region.dart';

part 'node/natural_block_node.dart';
part 'node/horizontal_align.dart';
part 'node/semantic_color.dart';

part 'node/inline_node.dart';
part 'node/span_decoration.dart';
part 'node/text_span_node.dart';
part 'node/verbatim_span_node.dart';

part 'node/layout_node.dart';
part 'node/content_node.dart';
part 'node/verbatim_node.dart';
part 'node/text_node.dart';
part 'node/column_node.dart';
part 'node/row_node.dart';
part 'node/table_node.dart';
part 'node/table_row_node.dart';
part 'node/table_cell_node.dart';

part 'node/document_node.dart';
part 'node/parser.dart';
