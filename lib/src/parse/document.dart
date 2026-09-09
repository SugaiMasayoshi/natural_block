/// The way in, and the contract every step of the reading keeps.
///
/// Every node reads itself. There is no separate pass that walks the source
/// and assembles nodes afterwards; each `parse…Node` takes the one
/// [SourceCursor] and returns that node. The tree they build is in
/// `nodes.dart`, which holds no reading at all -- one file per node here,
/// whose imports say which nodes and which symbols each step depends on.
///
/// **The one contract.** A node consumes only what is its own and stops in
/// front of the symbol that ends it. The owner of that symbol eats it. The
/// three layout symbols form one hierarchy, each ending everything below it:
///
/// | node | consumes | stops before |
/// |---|---|---|
/// | [TextSpanNode], [VerbatimSpanNode] | — | `^` `\|` `~` |
/// | [ColumnNode] | the `\|` that opened it | `^` `\|` |
/// | [TableCellNode] | the `\|` or `^` that opened it | `^` `\|` `~` |
/// | [RowNode] | the `^` between its cells | `\|` `~` |
/// | [TableRowNode] | the `^` between its cells | `\|` `~` |
/// | [TableNode] | its own `~` at each end | — |
/// | [DocumentNode] | — | — |
///
/// **Each block eats the separator that opened it**, and a delimiter belongs
/// to what it wraps. So a `|` is read by the block it opens, a `~` by the
/// table, a fence by the region -- and [DocumentNode] consumes nothing at
/// all: it has only to ask for blocks until the source runs out.
///
/// That is also why an alignment marker lands where it does. `|<a` opens a
/// cell and describes it; if a `^` turns up afterwards the block becomes a
/// row *around* that cell, and the marker is still the cell's. Read one level
/// up instead, the same marker would look like it described the row and then
/// quietly settle on its first cell.
///
/// The `^` is the exception, and it has to be: the first cell of a row has no
/// `^` in front of it, so only the row can tell the difference between
/// opening a cell and starting one.
///
/// So `|` is not "a new block starts here" -- it is the full stop on what
/// came before, and it means "next sibling" at whichever level is reading.
///
/// **The newline against a boundary.** One newline touching a structural
/// boundary belongs to the boundary rather than to the text. It is what makes
/// `|Item|Price` and
///
/// ```
/// |
/// Item
/// |
/// Price
/// ```
///
/// the same document: with no line-level structure in this language, the only
/// way to put a separator on its own line is to write newlines around it, and
/// those newlines must not become content. Two of them still do -- `a\n\n|b`
/// keeps one -- so a blank line is written by asking for it.
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
library;

import '../nodes.dart';
import '../source_cursor.dart';
import 'layout_node.dart';

/// The package's front door.
///
/// The tree is built by the nodes themselves -- each reads its own range and
/// stops in front of what is not its own -- so this is where the work starts.
/// It names that entry point without tying a caller to the root node's type,
/// and it is the only public way in: every other `parse…Node` lives in
/// `src/`, which the package does not export, so there is one door, not
/// fifteen.
abstract final class NaturalBlockParser {
  static DocumentNode parse(String source) {
    final cursor = SourceCursor(source);
    final children = <LayoutNode>[];

    // Nothing to arrange but the blocks themselves: each reads the `|` that
    // opened it, and a separator at the very end needs no special case
    // because the block it opens is empty and contributes no node.
    while (!cursor.isEnd) {
      final before = cursor.position;
      final block = parseLayoutNode(cursor);
      if (block != null) children.add(block);
      assert(
        cursor.position > before,
        'block parse made no progress at ${cursor.position}',
      );
    }

    return DocumentNode(children: children);
  }
}
