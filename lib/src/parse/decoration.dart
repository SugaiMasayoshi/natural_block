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
      final escapedDecoration =
          DecorationAction.chars.contains(next) && next != clusterChar;
      if (escapedDecoration) cursor.take();
      return result;
    }

    final action = DecorationAction.byChar[char];
    if (action == null) return result;
    cursor.take();
    result = result.apply(action);
  }
  return result;
}

/// Where the clusters opening at [index] end, or [index] when none opens
/// there.
int skipClusters(String source, int index) {
  var end = index;
  while (end + 1 < source.length &&
      source[end] == clusterChar &&
      DecorationAction.chars.contains(source[end + 1])) {
    end += 1;
    while (end < source.length &&
        DecorationAction.chars.contains(source[end])) {
      end += 1;
    }
  }
  return end;
}
