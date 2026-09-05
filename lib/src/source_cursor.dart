import 'syntax/verbatim_region.dart';

/// One position in the source, and the two things that must be resolved
/// before a node can read the character under it: escapes, and verbatim
/// regions.
///
/// It holds no opinion about what any character means. Which ones are markup
/// arrives as an argument, because that is a fact about the grammar and the
/// grammar is in the nodes -- and because the answer is not even constant:
/// `%` is prose in a sentence and a symbol inside a decoration cluster, so
/// no list built in here could be right in both places.
///
/// What it does know is smaller and does not vary: a backslash cancels the
/// character after it, a newline is never markup, and a run of backticks
/// opens a region that is taken literally. The region is the one piece of
/// syntax it cannot be handed, because finding the closing fence means
/// scanning ahead, and the cursor is what scanning ahead is done with.
class SourceCursor {
  final String source;

  int _position = 0;

  /// Every line break arrives as `\n`, whatever the author's editor wrote.
  ///
  /// Done here rather than by the caller because a newline is a character
  /// in this language -- it sits inside a run of text and is compared like
  /// any other -- so a stray `\r` would reach the tree and make a Windows
  /// document unequal to the same document written on a Mac. Nothing above
  /// this line ever sees the original bytes.
  SourceCursor(String source)
    : source = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  int get position => _position;

  bool get isEnd => _position >= source.length;

  String get peek => _position < source.length ? source[_position] : '';

  /// The character [offset] ahead of the cursor, or `''` past either end.
  /// Asks what sits beyond the cursor without moving it.
  String peekAt(int offset) {
    final index = _position + offset;
    return index >= 0 && index < source.length ? source[index] : '';
  }

  String take() => source[_position++];

  int _regionAt = -1;
  VerbatimRegion? _region;

  /// The region opening at the cursor, or null if none does.
  ///
  /// Remembered for the position it was read at. Four callers ask about the
  /// same fence before anyone consumes it -- the run's boundary check, the
  /// line's loop, the inline dispatch, and finally [takeVerbatim] -- because
  /// a child stops in front of what is not its own and its owner then asks.
  /// That protocol is right; answering it four times over an unchanging
  /// source is not.
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
  ///
  /// Not the same as "the cursor is on a backtick": an opening fence with no
  /// closing one opens nothing, and is ordinary text.
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
  /// The one place both readers of escapes agree. A decoration cluster has
  /// its own [markup] and its own idea of what to do afterwards, but "did
  /// this backslash cancel anything, and how far do I move if it did" is one
  /// question with one answer.
  String? takeEscape(Set<String> markup) {
    if (peek != r'\') return null;

    final next = peekAt(1);
    if (!_escapes(next, markup)) return null;

    _position += 2;
    return next;
  }

  /// Reads text up to the next thing that could end it, resolving escapes,
  /// and **stops in front of it** -- the same rule every node follows.
  ///
  /// What could end it: a newline, one of [markup], or the end of the
  /// source. Which of those it turned out to be is not returned, because the
  /// cursor has not moved past it and can be asked. Consuming the terminator
  /// here would make the caller put it back.
  ///
  /// It stops in front of every character in [markup], not only the ones
  /// that turn out to mean something. A `:` that opens no cluster and a
  /// backtick that closes nowhere are ordinary text, and deciding that is
  /// the caller's job -- it takes the character and reads on.
  String read(Set<String> markup) {
    final buffer = StringBuffer();
    var literalStart = _position;

    while (_position < source.length) {
      final char = source[_position];

      if (char == r'\' && _escapes(peekAt(1), markup)) {
        buffer.write(source.substring(literalStart, _position));
        literalStart = _position + 1;
        _position += 2;
        continue;
      }

      if (char == '\n' || markup.contains(char)) break;

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
  /// source, which [next] reports as `''`. A backslash always is, or a
  /// literal one could never be written in front of a symbol.
  bool _escapes(String next, Set<String> markup) =>
      next.isNotEmpty &&
      next != '\n' &&
      (next == r'\' || markup.contains(next));
}
