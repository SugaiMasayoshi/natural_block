/// One position in the source, and the reading of escapes.
///
/// It holds no opinion about what any character means. Which ones are markup
/// arrives as an argument, because that is a fact about the grammar and the
/// grammar is in the nodes -- and because the answer is not even constant:
/// `%` is prose in a sentence and a symbol inside a decoration cluster, so
/// no list built in here could be right in both places.
///
/// What it does know is smaller and does not vary: a backslash cancels the
/// character after it, and a newline is never markup. Escapes are here and
/// not in the grammar because they are the one rule that changes what a
/// character *is* -- past a backslash there is no symbol left for a node to
/// see -- so nothing above this could read the source without them.
///
/// Verbatim regions used to be here too, cached against the position they
/// were read at. They are grammar -- they become nodes -- so they left with
/// the rest: `VerbatimSpanNode` says whether one opens at the cursor, and
/// drives this class from outside through the operations below, exactly as
/// every other node does.
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

  /// Moves the cursor to [index] without reading anything on the way.
  ///
  /// The one operation a node cannot express with [take]: a verbatim region
  /// is found by searching ahead for its closing fence, so its owner knows
  /// where it ends before it has read a character of it.
  void jumpTo(int index) => _position = index;

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
