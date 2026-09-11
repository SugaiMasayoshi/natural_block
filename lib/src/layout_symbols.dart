/// The three symbols that lay a document out, named for the arrangement
/// each one creates.
///
/// That is the only axis all three share, and it is the same axis the node
/// classes are named on. Naming them for what they *separate* instead --
/// blocks, cells, tables -- would put them on three levels of one hierarchy,
/// because a cell is a block.
///
/// They form one hierarchy of their own, and each ends everything below it:
/// [rowSymbol] is innermost, then [columnSymbol], then [tableSymbol].
///
/// Characters rather than an enum, because nothing ever asks *which* one it
/// has in a way an enum would help with -- there is no `switch` over them and
/// none is ever stored in the tree. It also keeps them the same shape as the
/// verbatim fence, which is the same kind of thing: markup.
///
/// Named here one by one and grouped nowhere. Being markup is a different
/// fact from arranging a document, and `markup.dart` groups them for that --
/// by who eats them, which is what a reader of markup has to know. `~` is
/// grouped there with the verbatim fence rather than with these two.
library;

/// Separates blocks stacked one above another. Inside a table it separates
/// rows, which stack the same way.
///
/// Read by the block it opens, which is why it is tested for by name: the
/// level about to decide what that block turns out to be is the one that
/// takes it.
const String columnSymbol = '|';

/// Separates the blocks laid out across one row -- its cells.
///
/// The one separator a block never reads for itself. A row's first cell has
/// no `^` in front of it, so only the row can tell opening a cell apart
/// from starting one.
const String rowSymbol = '^';

/// Wraps rows into a grid.
///
/// The only one that delimits rather than separates: it comes in a pair, and
/// both belong to the table, the way both fences belong to a verbatim region.
/// A table needs that, being the one block sized to its own content rather
/// than to the width it is given -- it has to know where it stops.
const String tableSymbol = '~';
