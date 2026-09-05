import 'parser/layout_symbol.dart';
import 'parser/verbatim_region.dart';

/// The cursor over the source, and the two things that must be resolved
/// before any node can read a character: escapes, and verbatim regions.
///
/// It knows this language's layout alphabet, and that is not a leak. What a
/// backslash cancels is *whatever is markup at that point*, so the escape
/// rule cannot be stated without naming the symbols -- and a run of text
/// ends where markup begins, which is the same list again. A scanner that
/// took the alphabet as an argument would be a general one, and there is
/// exactly one language to instantiate it with.
///
/// What it does *not* know is alignment. Its markers are neither
/// escapable nor terminators; they mean something only directly after a
/// separator, which is a rule about the grammar rather than about reading
/// characters. It lives with the enum, in `block_align.dart`.
class Scanner {
  final String source;

  int _position = 0;

  Scanner(this.source);

  int get position => _position;

  bool get isEnd => _position >= source.length;

  String get peek => _position < source.length ? source[_position] : '';

  /// The character [offset] ahead of the cursor, or `''` past the end.
  /// Asks what sits beyond the cursor without moving it.
  String peekAt(int offset) {
    final index = _position + offset;
    return index >= 0 && index < source.length ? source[index] : '';
  }

  /// The layout symbol at the cursor, or null when the cursor is not on one.
  ///
  /// Every level asks this: a cell stops at any of them, a row asks whether
  /// the next one is another cell, a table whether it is the `~` that ends
  /// it. Asked through the symbol rather than its character so those
  /// questions read as what they are.
  LayoutSymbol? get layoutSymbol => LayoutSymbol.byChar[peek];

  String take() => source[_position++];

  int _regionAt = -1;
  VerbatimRegion? _region;

  /// The region opening at the cursor, or null if none does.
  ///
  /// Remembered for the position it was read at. Five callers ask about the
  /// same fence before anyone consumes it -- the scan itself, the run's
  /// boundary check, the line's loop, the inline dispatch, and finally
  /// [takeVerbatim] -- because a child stops in front of what is not its own
  /// and its owner then asks. That protocol is right; answering it five
  /// times over an unchanging source is not.
  VerbatimRegion? get _regionHere {
    if (_regionAt != _position) {
      _regionAt = _position;
      _region = peek == verbatimFenceChar
          ? verbatimRegionAt(source, _position)
          : null;
    }
    return _region;
  }

  /// Whether a verbatim region opens here. Asks without consuming, so a node
  /// can decide whether the region belongs to it before touching it.
  bool get atVerbatimFence => _regionHere != null;

  /// Whether the region opening here was written on a line of its own, and
  /// so is a block rather than a run inside a line.
  ///
  /// Stated once, and asked by both sides: the line that must not take it
  /// and the block that must. If the two disagreed, neither would consume
  /// the fence and the caller's loop would never advance.
  bool get atBlockRegion =>
      atVerbatimFence && (_position == 0 || peekAt(-1) == '\n');

  /// Consumes the region opening at the cursor and returns its content.
  String takeVerbatim() {
    final region = _regionHere!;
    _position = region.end;
    return region.text;
  }

  /// Consumes the escape at the cursor and returns the character it cancels,
  /// or null -- **with the cursor unmoved** -- when the backslash cancels
  /// nothing and is therefore an ordinary character.
  ///
  /// [alsoEscapable] is what counts as markup at this point on top of what
  /// always does: the caller's own syntax, which this layer does not know.
  ///
  /// The one place both readers of escapes agree. A decoration cluster has
  /// its own alphabet and its own idea of what to do afterwards, but "did
  /// this backslash cancel anything, and how far do I move if it did" is one
  /// question with one answer.
  String? takeEscape(Set<String> alsoEscapable) {
    if (peek != r'\') return null;

    final next = peekAt(1);
    if (!_escapes(next, alsoEscapable)) return null;

    _position += 2;
    return next;
  }

  /// Reads text up to the next thing that could end it, resolving escapes,
  /// and **stops in front of it** -- the same rule every node follows.
  ///
  /// What could end it: a newline, a layout symbol, a verbatim region, one
  /// of [alsoStopAt], or the end of the source. Which of those it turned out
  /// to be is not returned, because the cursor has not moved past it and can
  /// be asked. Consuming the terminator here would make the caller put it
  /// back, which is what it used to do three times over.
  String read(Set<String> alsoStopAt) {
    final buffer = StringBuffer();
    var literalStart = _position;

    while (_position < source.length) {
      final char = source[_position];

      if (char == r'\' && _escapes(peekAt(1), alsoStopAt)) {
        buffer.write(source.substring(literalStart, _position));
        literalStart = _position + 1;
        _position += 2;
        continue;
      }

      if (char == '\n' ||
          LayoutSymbol.byChar.containsKey(char) ||
          alsoStopAt.contains(char) ||
          (char == verbatimFenceChar && _regionHere != null)) {
        break;
      }

      _position += 1;
    }

    buffer.write(source.substring(literalStart, _position));
    return buffer.toString();
  }

  /// Whether a backslash before [next] cancels it rather than standing as a
  /// literal backslash.
  ///
  /// A newline is never escapable -- a line break is not markup, so there is
  /// nothing for a backslash to cancel -- and neither is the end of the
  /// source, which [next] reports as `''`.
  bool _escapes(String next, Set<String> alsoEscapable) =>
      next.isNotEmpty &&
      next != '\n' &&
      (next == r'\' ||
          next == verbatimFenceChar ||
          LayoutSymbol.byChar.containsKey(next) ||
          alsoEscapable.contains(next));
}
