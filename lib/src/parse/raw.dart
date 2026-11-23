import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'decoration.dart';

const _blockFence = 3;

/// Whether a raw block opens at [index], the start of a line or a cell: a
/// fence of three or more backticks, after any decoration, that does not
/// close on its own line.
bool rawBlockAt(String source, int index) {
  final fenceStart = skipClusters(source, index);
  final fence = _fenceAt(source, fenceStart);
  if (fence < _blockFence) return false;
  final lineEnd = _lineEndFrom(source, fenceStart);
  return _closerIn(source, fenceStart + fence, lineEnd, fence) == null;
}

/// A block runs from the line of its fence to the next line that starts with
/// a fence as long, or to the end of the document. The line break right
/// after the opening fence and the one before the closing fence are left out.
RawNode? parseRawNode(SourceCursor cursor) {
  final start = cursor.position;
  cursor.jumpTo(skipClusters(cursor.source, start));
  final source = cursor.source;
  final fence = _fenceAt(source, cursor.position);
  final fenceEnd = cursor.position + fence;
  final openingLineEnd = _lineEndFrom(source, fenceEnd);
  final contentStart = openingLineEnd == fenceEnd ? fenceEnd + 1 : fenceEnd;

  var lineStart = openingLineEnd + 1;
  while (lineStart < source.length && _fenceAt(source, lineStart) != fence) {
    lineStart = _lineEndFrom(source, lineStart) + 1;
  }
  final closed = lineStart < source.length;
  final contentEnd = closed ? lineStart - 1 : source.length;
  cursor.jumpTo(closed ? lineStart + fence : source.length);

  if (contentEnd <= contentStart) return null;
  return RawNode(
    text: source.substring(contentStart, contentEnd),
    start: start,
    end: cursor.position,
  );
}

/// A region within one line, closed by a fence as long as the one that
/// opened it, or by the end of the line.
RawSpanNode? parseRawSpanNode(SourceCursor cursor, SpanDecoration style) {
  final start = cursor.position;
  final source = cursor.source;
  final fence = _fenceAt(source, start);
  final contentStart = start + fence;
  final lineEnd = _lineEndFrom(source, contentStart);
  final closer = _closerIn(source, contentStart, lineEnd, fence);
  cursor.jumpTo(closer == null ? lineEnd : closer + fence);

  final text = source.substring(contentStart, closer ?? lineEnd);
  if (text.isEmpty) return null;
  return RawSpanNode(
    text: text,
    decoration: style,
    start: start,
    end: cursor.position,
  );
}

int _fenceAt(String source, int index) {
  var end = index;
  while (end < source.length && source[end] == rawChar) {
    end += 1;
  }
  return end - index;
}

int _lineEndFrom(String source, int index) {
  final lineBreak = source.indexOf('\n', index);
  return lineBreak == -1 ? source.length : lineBreak;
}

/// Where a run of exactly [fence] backticks starts between [from] and [to].
int? _closerIn(String source, int from, int to, int fence) {
  var index = from;
  while (index < to) {
    final run = _fenceAt(source, index);
    if (run == fence) return index;
    index += run == 0 ? 1 : run;
  }
  return null;
}
