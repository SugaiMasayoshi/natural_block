import 'scanner.dart';

enum BlockAlign {
  start('<'),
  center('='),
  end('>');

  final String char;
  const BlockAlign(this.char);

  static final Map<String, BlockAlign> byChar = Map.unmodifiable({
    for (final align in BlockAlign.values) align.char: align,
  });
}

extension AlignmentMarkers on Scanner {
  /// Consumes the layout symbol at the cursor together with the markers
  /// written after it, and returns what they said.
  ///
  /// The two are read as one because that is the only place markers mean
  /// anything: `<`, `=` and `>` are ordinary text everywhere except directly
  /// after an unescaped separator. What they describe is whatever that
  /// separator opens -- a block at the document's level, a row inside a
  /// table, a cell inside a row -- which is the caller's business, not this
  /// one's.
  ///
  /// It lives here rather than on the scanner because that guard is the
  /// whole rule, and it is about the grammar rather than about reading
  /// characters: markers are neither escapable nor terminators, so nothing
  /// else in the scanner has any reason to know them.
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
      take();
    }
    return align;
  }
}
