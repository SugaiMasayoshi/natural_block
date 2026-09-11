import '../decoration_action.dart';
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'decoration.dart';
import 'verbatim_region.dart';
import 'verbatim_span_node.dart';

bool _opensCluster(SourceCursor cursor) =>
    cursor.peek == ':' && DecorationAction.byChar.containsKey(cursor.peekAt(1));

/// Whether the character the cursor stopped in front of really ends the run.
/// Peeks only -- it never moves the cursor.
bool _endsRun(SourceCursor cursor, SpanDecoration style) =>
    switch (cursor.peek) {
      // A newline resets decoration, so it ends a run that has some. With
      // nothing to reset it is an ordinary character in the middle of one.
      '\n' => style != const SpanDecoration(),
      // A `:` with no decoration character after it is ordinary text; one
      // with is the next run's cluster, and not this run's to consume.
      ':' => _opensCluster(cursor),
      // A fence that never closes opens no region, so it is text too.
      verbatimFenceChar => verbatimRegionOpensAt(cursor),
      // A layout symbol. Nothing else gets here.
      _ => true,
    };

/// Reads one run of styled text, and the decoration state it leaves.
///
/// Any cluster written at the cursor is applied first, so the run's style is
/// settled before a character of it is read. The run then stops in front of
/// the next thing that is not part of it, consuming none of it.
(TextSpanNode?, SpanDecoration) parseTextSpanNode(
  SourceCursor cursor,
  SpanDecoration incoming,
) {
  final pending = StringBuffer();
  var style = incoming;

  while (_opensCluster(cursor)) {
    cursor.take();
    final (next, escaped) = readCluster(style, cursor);
    style = next;
    pending.write(escaped);
  }

  // The cursor stops in front of every character that could end the run, so
  // this loop only has to say which of those actually do; one that does not
  // is taken as text and the read resumes.
  while (true) {
    pending.write(cursor.read(textMarkup));
    if (cursor.isEnd || _endsRun(cursor, style)) break;
    pending.write(cursor.take());
  }

  final outgoing = cursor.peek == '\n' ? const SpanDecoration() : style;

  var run = pending.toString();
  if (run.endsWith('\n') && !_opensCluster(cursor)) {
    run = run.substring(0, run.length - 1);
  }

  return (
    run.isEmpty ? null : TextSpanNode(text: run, decoration: style),
    outgoing,
  );
}
