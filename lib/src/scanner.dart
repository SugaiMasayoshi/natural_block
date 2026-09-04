import 'block_align.dart';
import 'parser/layout_symbol.dart';
import 'parser/verbatim_region.dart';

class Scanned {
  final String text;

  /// The symbol the scan stopped at, or null when nothing was left to take:
  /// the end of the source, or a verbatim region the caller must decide
  /// about. Which of those two it was is a question for the cursor, which
  /// has not moved.
  final String? symbol;

  const Scanned({required this.text, this.symbol});
}

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

  /// Consumes the markers written at the cursor and returns what they said.
  ///
  /// Null when none were written, which is not [BlockAlign.start]: markers
  /// describe the block a layout symbol opens, and a block that stated
  /// nothing is a different thing from one that asked for the start.
  ///
  /// A later marker overrides an earlier one, so `|<^>` is end-aligned.
  BlockAlign? takeMarkers() {
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

  /// Reads up to the next character of [symbols], resolving escapes and
  /// stopping in front of a verbatim region rather than reading through it.
  ///
  /// The region is left for the caller because whether it is a block or a
  /// run depends on where it was written, which the scanner does not judge.
  Scanned read(Set<String> symbols) {
    bool escapes(String next) =>
        next != '\n' && (escapesAlwaysActive(next) || symbols.contains(next));

    final start = _position;
    StringBuffer? buffer;
    var literalStart = start;

    String literal() {
      if (buffer == null) return source.substring(literalStart, _position);
      buffer.write(source.substring(literalStart, _position));
      return buffer.toString();
    }

    while (_position < source.length) {
      final char = source[_position];

      if (char == r'\' &&
          _position + 1 < source.length &&
          escapes(source[_position + 1])) {
        buffer ??= StringBuffer();
        buffer.write(source.substring(literalStart, _position));
        literalStart = _position + 1;
        _position += 2;
        continue;
      }

      if (char == verbatimFenceChar && _regionHere != null) {
        return Scanned(text: literal());
      }

      if (symbols.contains(char)) {
        final text = literal();
        _position += 1;
        return Scanned(text: text, symbol: char);
      }

      _position += 1;
    }

    return Scanned(text: literal());
  }
}
