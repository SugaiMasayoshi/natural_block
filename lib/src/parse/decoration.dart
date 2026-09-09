import '../decoration_action.dart';
import '../layout_symbols.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import '../verbatim_region.dart';

/// What a backslash can cancel inside a cluster: every decoration character
/// is live here, including the `:` that closes the cluster again, on top of
/// the symbols that are markup everywhere.
///
/// The difference from what a run of text reads outside a cluster is the
/// whole rule: `:---\%%%` needs one backslash, and a bare `%` in a sentence
/// needs none.
final Set<String> _markup = {
  ...layoutSymbols,
  verbatimFenceChar,
  ...DecorationAction.chars,
};

/// Reads the cluster the cursor has just entered and returns the state it
/// leaves behind, together with any character a backslash rescued from it.
///
/// That character is ordinary text belonging to the run that follows, and
/// handing it back is what lets one backslash cover a whole run.
(SpanDecoration, String) readCluster(
  SpanDecoration style,
  SourceCursor cursor,
) {
  var result = style;
  while (!cursor.isEnd) {
    final char = cursor.peek;

    // A backslash that cancels nothing is an ordinary character; the cluster
    // ends either way, and what the escape rescued opens the run that follows.
    if (char == r'\') {
      return (result, cursor.takeEscape(_markup) ?? '');
    }

    final action = DecorationAction.byChar[char];
    if (action == null) return (result, '');
    cursor.take();
    result = result.apply(action);
  }
  return (result, '');
}
