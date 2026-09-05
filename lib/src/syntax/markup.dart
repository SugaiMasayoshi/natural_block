/// Which characters are markup, and therefore both what ends a run of text
/// and what a backslash can cancel.
///
/// There are two answers because the question is positional, and stating
/// them side by side is the point: the difference between them *is* the rule
/// that `+`, `-`, `!`, `%`, `*` and `@` are ordinary prose until a `:` has
/// opened a cluster. `C++` and `100%` need no escaping; `:---\%%%` does.
///
/// Passed to the cursor rather than known by it. Which characters carry
/// meaning is a fact about this grammar, and the grammar is in the nodes; a
/// cursor that had the list built in would be answering a question nobody
/// asked it.
///
/// A backslash is not listed. It cancels itself wherever it appears, because
/// otherwise there would be no way to write one in front of a symbol.
library;

import 'decoration_action.dart';
import 'layout_symbol.dart';
import 'verbatim_region.dart';

/// Markup in ordinary text: the three layout symbols, the verbatim fence,
/// and the `:` that opens a decoration cluster.
final Set<String> markup = {
  ...LayoutSymbol.chars,
  verbatimFenceChar,
  DecorationAction.reset.char,
};

/// Markup inside a decoration cluster, where every decoration character is
/// live -- including the `:` that closes the cluster again.
final Set<String> clusterMarkup = {
  ...LayoutSymbol.chars,
  verbatimFenceChar,
  ...DecorationAction.chars,
};
