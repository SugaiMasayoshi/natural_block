/// The three symbols that lay a document out, named for the arrangement
/// each one creates.
///
/// That is the only axis all three share, and it is the same axis the node
/// classes are named on: `|` stacks what it separates, `^` lays it out
/// across, `~` wraps it into a grid, and the results are the node types
/// named the same way. Naming them for what they *separate* instead
/// -- blocks, cells, tables -- puts them on three different levels of one
/// hierarchy, because a cell is a block and so is a table; every one of the
/// three node types extends `BlockNode`.
///
/// They form one hierarchy of their own, and each ends everything below it:
/// [rowSymbol] is innermost, then [columnSymbol], then [tableSymbol].
///
/// Characters rather than an enum, because nothing here ever asks *which*
/// one it has in a way an enum would help with -- there is no `switch` over
/// them and none is ever stored in the tree. Wrapping them turned every
/// question into a round trip: look the character up in a map to get a
/// token, then compare that token, to learn what the character already
/// said. It also put them in a different shape from the verbatim fence,
/// which is a plain character and the same kind of thing: markup.
library;

/// Separates blocks stacked one above another. Inside a table it separates
/// rows, which stack the same way.
///
/// Never tested for on its own, and that is the hierarchy showing: a level
/// asks whether the symbol above it is here, or whether its own is, and
/// this one is what is left over. It is named so that the set below reads
/// as three things rather than two and a character.
const String columnSymbol = '|';

/// Separates the blocks laid out across one row -- its cells.
const String rowSymbol = '^';

/// Wraps blocks into a grid. The only one that opens and closes rather than
/// separating, which is why a document has to remember whether it is inside
/// one.
const String tableSymbol = '~';

/// All three, for the levels that stop at any of them without caring which.
const Set<String> layoutSymbols = {columnSymbol, rowSymbol, tableSymbol};
