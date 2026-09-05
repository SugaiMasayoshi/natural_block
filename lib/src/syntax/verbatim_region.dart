const String verbatimFenceChar = '`';

class VerbatimRegion {
  final String text;

  final int end;

  const VerbatimRegion({required this.text, required this.end});
}

VerbatimRegion? verbatimRegionAt(String source, int openIndex) {
  if (openIndex >= source.length || source[openIndex] != verbatimFenceChar) {
    return null;
  }

  var fence = 0;
  while (openIndex + fence < source.length &&
      source[openIndex + fence] == verbatimFenceChar) {
    fence += 1;
  }

  final contentStart = openIndex + fence;
  final closer = verbatimFenceChar * fence;
  final closerStart = source.indexOf(closer, contentStart);
  if (closerStart == -1) return null;

  return VerbatimRegion(
    text: _trimFenceNewlines(source.substring(contentStart, closerStart)),
    end: closerStart + fence,
  );
}

String _trimFenceNewlines(String raw) {
  var text = raw;
  if (text.startsWith('\n')) text = text.substring(1);
  if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
  return text;
}
