import '../markup.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'span_decoration.dart';

SpanDecoration parseCluster(SourceCursor cursor, SpanDecoration style) {
  cursor.take();

  var result = style;
  while (!cursor.isEnd) {
    final char = cursor.peek;

    if (char == escapeChar) {
      final next = cursor.peekAt(1);
      if (DecorationAction.chars.contains(next) && next != clusterChar) {
        cursor.take();
      }
      return result;
    }

    final action = DecorationAction.byChar[char];
    if (action == null) return result;
    cursor.take();
    result = result.apply(action);
  }
  return result;
}
