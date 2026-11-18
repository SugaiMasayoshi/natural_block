import '../markup.dart';
import 'spacer_node.dart';

/// Whether the line starting at [position] begins with markup of its own in
/// [place]: in a block, a marker, a row or a spacer; in a row's cell, a
/// spacer.
bool opensLine(String source, int position, TextPlace place) {
  if (spacerAt(source, position, place) != null) return true;
  if (place != TextPlace.block || position >= source.length) return false;
  final first = source[position];
  return alignMarkers.containsKey(first) || first == rowChar;
}
