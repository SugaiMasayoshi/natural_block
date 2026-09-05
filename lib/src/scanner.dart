import 'block_align.dart';
import 'parser/layout_symbol.dart';
import 'parser/verbatim_region.dart';

class Scanner {
  final String source;

  int _position = 0;

  Scanner(this.source);

  int get position => _position;

  bool get isEnd => _position >= source.length;

  String get peek => _position < source.length ? source[_position] : '';

  /// The character at [index], or `''` outside the source. Used to ask what
  /// sits against a position without moving.
  String at(int index) =>
      index >= 0 && index < source.length ? source[index] : '';

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
      atVerbatimFence && (_position == 0 || at(_position - 1) == '\n');

  /// Consumes the layout symbol at the cursor together with the markers
  /// written after it, and returns what they said.
  ///
  /// The two are read as one because that is the only place markers mean
  /// anything: `<`, `^` and `>` are ordinary text everywhere except directly
  /// after an unescaped separator. What they describe is whatever that
  /// separator opens -- a block at the document's level, a row inside a
  /// table, a cell inside a row -- which is the caller's business, not this
  /// one's.
  ///
  /// Null when no marker was written, which is not [BlockAlign.start]: a
  /// block that stated nothing is a different thing from one that asked for
  /// the start. A later marker overrides an earlier one, so `|<^>` ends up
  /// end-aligned.
  BlockAlign? takeSeparator() {
    take();

    BlockAlign? align;
    while (!isEnd) {
      final marker = BlockAlign.byChar[peek];
      if (marker == null) break;
      align = marker;
      _position += 1;
    }
    return align;
  }

  String take() => source[_position++];

  void skipTo(int index) => _position = index;

  /// Consumes the region opening at the cursor and returns its content.
  String takeVerbatim() {
    final region = _regionHere!;
    _position = region.end;
    return region.text;
  }

  static bool escapesAlwaysActive(String next) =>
      next == r'\' ||
      next == verbatimFenceChar ||
      LayoutSymbol.byChar.containsKey(next);

  /// Reads text up to the next thing that could end it, resolving escapes,
  /// and **stops in front of it** -- the same rule every node follows.
  ///
  /// What could end it: a newline, a layout symbol, a verbatim region, one
  /// of [symbols], or the end of the source. Which of those it turned out to
  /// be is not returned, because the cursor has not moved past it and can be
  /// asked. Consuming the terminator here would make the caller put it back,
  /// which is what it used to do three times over.
  String read(Set<String> symbols) {
    final buffer = StringBuffer();
    var literalStart = _position;

    while (_position < source.length) {
      final char = source[_position];

      if (char == r'\' &&
          _position + 1 < source.length &&
          _escapes(source[_position + 1], symbols)) {
        buffer.write(source.substring(literalStart, _position));
        literalStart = _position + 1;
        _position += 2;
        continue;
      }

      if (char == '\n' ||
          LayoutSymbol.byChar.containsKey(char) ||
          symbols.contains(char) ||
          (char == verbatimFenceChar && _regionHere != null)) {
        break;
      }

      _position += 1;
    }

    buffer.write(source.substring(literalStart, _position));
    return buffer.toString();
  }

  /// Whether a backslash before [next] escapes it rather than standing as a
  /// literal backslash.
  ///
  /// A newline is never escapable -- a line break is not markup, so there is
  /// nothing for a backslash to cancel.
  bool _escapes(String next, Set<String> symbols) =>
      next != '\n' && (escapesAlwaysActive(next) || symbols.contains(next));
}
