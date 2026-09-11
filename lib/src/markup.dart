/// Which characters are not ordinary text, and therefore which a backslash
/// can cancel.
///
/// One place, because it is a fact about the language rather than about any
/// node. A run of text stops in front of every character named here; it does
/// not ask what any of them opens, or whose it is. Adding a construct to the
/// language means putting its character in one of the groups below and giving
/// it a parse -- nothing that reads text has to hear about it.
///
/// The two groups are "does it come in a pair", which is the question that
/// settles who eats it. They are not "layout" and "content": a `~` arranges
/// rows *and* is a piece of content, so that axis would put one character in
/// both groups for one reason. Counting halves does not.
library;

import 'decoration_action.dart';
import 'layout_symbols.dart';
import 'parse/verbatim_region.dart';

/// Markup with no closing half. It stands between two siblings, so it is
/// eaten by their parent: the document or a table eats a `|`, a row eats a
/// `^`.
///
/// The README calls these the *separators*.
const Set<String> unpairedMarkup = {columnSymbol, rowSymbol};

/// Markup that comes in a pair, where both halves belong to what they wrap.
///
/// A `~` and a fence each mark out something sized to its own content, so it
/// has to know where it stops -- which is why it owns its ending as well as
/// its beginning.
///
/// The README calls these the *delimiters*.
final Set<String> pairedMarkup = {tableSymbol, verbatimFenceChar};

/// The markup a run of text is read against.
///
/// `+`, `-`, `!`, `%`, `*` and `@` are missing on purpose -- that absence is
/// the rule that `C++` and `100%` are prose and need no escaping. Only the
/// `:` that opens a decoration cluster is live out here.
final Set<String> textMarkup = {
  ...unpairedMarkup,
  ...pairedMarkup,
  DecorationAction.reset.char,
};

/// The markup a decoration cluster is read against: every decoration
/// character is live inside one, including the `:` that closes it again.
///
/// The difference between the two sets is the whole escaping rule of this
/// language: `:---\%%%` needs one backslash, and a bare `%` in a sentence
/// needs none.
final Set<String> clusterMarkup = {
  ...unpairedMarkup,
  ...pairedMarkup,
  ...DecorationAction.chars,
};
