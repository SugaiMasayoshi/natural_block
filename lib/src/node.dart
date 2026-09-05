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
/// | `ColumnNode` | — | `^` `\|` `~` |
/// | `RowNode` | `^` | `\|` `~` |
/// | `TableNode` | `\|` | `~` |
/// | `DocumentNode` | `\|` `~` | — |
///
/// So `|` is not "a new block starts here" -- it is the full stop on what
/// came before, and it means "next sibling" at whichever level is reading.
///
/// **What the tree records.** What the source said, never what a renderer
/// needs. `align == null` means "nothing was written", which is not
/// [BlockAlign.start]; a table keeps its columns rather than stamping them
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

import 'block_align.dart';
import 'decoration_action.dart';
import 'layout_symbols.dart';
import 'semantic_color.dart';
import 'source_cursor.dart';
import 'verbatim_region.dart';

part 'node/natural_block_node.dart';
part 'node/children_equality.dart';

part 'node/inline_node.dart';
part 'node/span_decoration.dart';
part 'node/text_span_node.dart';
part 'node/verbatim_span_node.dart';

part 'node/block_node.dart';
part 'node/content_node.dart';
part 'node/verbatim_node.dart';
part 'node/text_node.dart';
part 'node/column_node.dart';
part 'node/row_node.dart';
part 'node/table_node.dart';

part 'node/document_node.dart';
part 'node/parser.dart';
