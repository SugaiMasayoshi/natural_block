/// The three symbols that lay a document out, and the one fact about them
/// that holds everywhere: they form a hierarchy, and each ends everything
/// below it.
///
/// Characters rather than an enum, because nothing here ever asks *which*
/// one it has in a way an enum would help with -- there is no `switch` over
/// them and none is ever stored in the tree. Wrapping them turned every
/// question into a round trip: look the character up in a map to get a
/// token, then compare that token, to learn what the character already
/// said. It also put them in a different shape from the verbatim fence,
/// which is a plain character and the same kind of thing: markup.
///
/// Named for what the symbol separates, which is what the code asks about:
/// `cursor.peek == cellSymbol` is "does another cell start here".
library;

/// Separates blocks stacked vertically. Inside a table it separates rows,
/// which are blocks too.
const String blockSymbol = '|';

/// Separates the cells laid out across one row.
const String cellSymbol = '^';

/// Delimits a table. The only symbol that opens and closes rather than
/// separating.
const String tableSymbol = '~';

/// All three, for the levels that stop at any of them without caring which.
const Set<String> layoutSymbols = {blockSymbol, cellSymbol, tableSymbol};
