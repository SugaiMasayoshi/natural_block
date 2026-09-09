import '../decoration_action.dart';
import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import '../verbatim_region.dart';
import 'decoration.dart';
import 'inline_node.dart';

/// What counts as markup while a run of text is being read: the three layout
/// symbols, the verbatim fence, and the `:` that opens a decoration cluster.
/// The cursor stops in front of each of them, and a backslash cancels each of
/// them.
///
/// Stated here because this is the level that decides it. `+`, `-`, `!`, `%`,
/// `*` and `@` are missing on purpose -- that absence is the rule that `C++`
/// and `100%` are prose and need no escaping. Inside a cluster the answer is
/// different, and `parse/decoration.dart` states its own.
final Set<String> _markup = {
  ...layoutSymbols,
  verbatimFenceChar,
  DecorationAction.reset.char,
};

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
      verbatimFenceChar => otherInlineStartsHere(cursor),
      // A layout symbol. Nothing else gets here.
      _ => true,
    };

/// Reads one run of styled text, and the decoration state it leaves.
///
/// Any cluster written at the cursor is applied first, so the run's style is
/// settled before a character of it is read. The run then ends at the next
/// thing that is not part of it -- a following cluster, a verbatim region, a
/// newline that resets an open decoration, or the block's own separator --
/// none of which it consumes.
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
  // this loop only has to say which of those actually do. A candidate that
  // does not -- a `:` that opens no cluster, a backtick that closes nowhere,
  // a newline with nothing to reset -- is taken as text and the read resumes.
  while (true) {
    pending.write(cursor.read(_markup));
    if (cursor.isEnd || _endsRun(cursor, style)) break;
    pending.write(cursor.take());
  }

  // Only the newline-reset exit leaves the cursor on a `'\n'`; every other one
  // leaves it on a layout symbol, a fence, a `:` or the end. So which exit was
  // taken need not be tracked either.
  final outgoing = cursor.peek == '\n' ? const SpanDecoration() : style;

  final run = pending.toString();
  return (
    run.isEmpty ? null : TextSpanNode(text: run, decoration: style),
    outgoing,
  );
}
