/// [source] as the parser reads it: line breaks written as `\n`, and the
/// final line break, the one an editor adds when saving, dropped. Node
/// offsets count in this text.
String normalizeSource(String source) =>
    switch (source.replaceAll('\r\n', '\n').replaceAll('\r', '\n')) {
      final s when s.endsWith('\n') => s.substring(0, s.length - 1),
      final s => s,
    };
