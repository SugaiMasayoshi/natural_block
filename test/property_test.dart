import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'support/grid.dart';

/// What holds for every source, checked over every string of up to five of
/// the grid's characters. None of it says which tree is right -- that is the
/// grid's job.
final _alphabet = gridTokens.values.toList();

/// A newline cannot be escaped, so the escape property leaves it out.
final _escapableAlphabet = _alphabet.where((c) => c != '\n').toList();

Iterable<String> _strings(List<String> alphabet, int maxLength) sync* {
  var previous = [''];
  for (var length = 1; length <= maxLength; length++) {
    final current = <String>[];
    for (final head in previous) {
      for (final c in alphabet) {
        current.add('$head$c');
      }
    }
    yield* current;
    previous = current;
  }
}

/// What is wrong with the shape of [node], or null.
String? _brokenShape(NaturalBlockNode node) {
  switch (node) {
    case DocumentNode(:final children):
      for (final child in children) {
        if (child is ColumnNode && child.children.isEmpty) {
          return 'the document holds an empty column';
        }
      }
      return _firstBroken(children);
    case RowNode(:final children):
      if (children.length < 2) return 'a row holds ${children.length} cells';
      return _firstBroken(children);
    case ColumnNode(:final children):
      return _firstBroken(children);
    case TextNode(:final children):
      if (children.isEmpty) return 'an empty text node';
      return _firstBroken(children);
    case TableNode(:final children):
      if (children.isEmpty) return 'an empty table';
      return _firstBroken(children);
    case TableRowNode(:final children):
      if (children.isEmpty) return 'an empty table row';
      return _firstBroken(children);
    case TableCellNode(:final children):
      return _firstBroken(children);
    case TextSpanNode(:final text):
      if (text.isEmpty) return 'an empty run';
      return _noCarriageReturn(text);
    case RawSpanNode(:final text):
      if (text.isEmpty) return 'an empty raw run';
      return _noCarriageReturn(text);
    case RawNode(:final text):
      if (text.isEmpty) return 'an empty raw block';
      return _noCarriageReturn(text);
  }
}

String? _firstBroken(List<NaturalBlockNode> nodes) {
  for (final node in nodes) {
    final broken = _brokenShape(node);
    if (broken != null) return broken;
  }
  return null;
}

String? _noCarriageReturn(String text) =>
    text.contains('\r') ? 'a \\r survived into the tree' : null;

/// [source] with a `\` before every character that is markup where it
/// stands: `\` and the always-active characters everywhere, `<` only where a
/// block begins. A bare `!` is not markup, so escaping it would leave the
/// backslash in the text.
String _escapeAll(String source) {
  final out = StringBuffer();
  for (var i = 0; i < source.length; i++) {
    final c = source[i];
    final needsEscape =
        c == r'\' ||
        const ['|', '^', '~', '`', ':'].contains(c) ||
        (c == '<' && i == 0);
    if (needsEscape) out.write(r'\');
    out.write(c);
  }
  return out.toString();
}

void main() {
  final sources = _strings(_alphabet, 5).toList();

  test('${sources.length} sources parse without throwing', () {
    // A loop that stops advancing trips an assert, so it fails here too.
    for (final source in sources) {
      expect(
        () => NaturalBlockParser.parse(source),
        returnsNormally,
        reason: source,
      );
    }
  });

  test('every tree keeps its shape', () {
    for (final source in sources) {
      final broken = _brokenShape(NaturalBlockParser.parse(source));
      expect(broken, isNull, reason: '$broken for: $source');
    }
  });

  test('CRLF parses the same as LF', () {
    for (final source in sources) {
      expect(
        NaturalBlockParser.parse(source.replaceAll('\n', '\r\n')),
        NaturalBlockParser.parse(source),
        reason: source,
      );
    }
  });

  test('escaping every symbol gives one plain run of the source', () {
    for (final source in _strings(_escapableAlphabet, 5)) {
      final document = NaturalBlockParser.parse(_escapeAll(source));
      final column = document.children.single as ColumnNode;
      final text = column.children.single as TextNode;
      expect(
        text.children.single,
        TextSpanNode(text: source),
        reason: '${_escapeAll(source)} should be the text $source',
      );
    }
  });
}
