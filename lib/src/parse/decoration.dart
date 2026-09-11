import '../decoration_action.dart';
import '../markup.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'span_decoration.dart';

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
      return (result, cursor.takeEscape(clusterMarkup) ?? '');
    }

    final action = DecorationAction.byChar[char];
    if (action == null) return (result, '');
    cursor.take();
    result = result.apply(action);
  }
  return (result, '');
}
