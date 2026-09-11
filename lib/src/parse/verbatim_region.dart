const String verbatimFenceChar = '`';

/// Where the region opening at [openIndex] ends, or -1 when none opens there.
///
/// A fence is however many backticks were written in a row, and it closes on
/// the same number. An opening fence with no closing one opens nothing: the
/// backticks are ordinary text.
///
/// Builds no string, deliberately: of the four levels that meet a fence,
/// three only ask *whether* a region is here and one consumes it.
int verbatimRegionEnd(String source, int openIndex) {
  if (openIndex >= source.length || source[openIndex] != verbatimFenceChar) {
    return -1;
  }

  var fence = 0;
  while (openIndex + fence < source.length &&
      source[openIndex + fence] == verbatimFenceChar) {
    fence += 1;
  }

  final closerStart = source.indexOf(
    verbatimFenceChar * fence,
    openIndex + fence,
  );
  return closerStart == -1 ? -1 : closerStart + fence;
}

/// The content of the region opening at [openIndex], and where it ends.
///
/// The newline written against either fence belongs to the fence rather than
/// to the content, so a region written on its own lines does not draw as a
/// blank line, its text, and another blank line.
///
/// Only the node that consumes the region calls this; the levels that stop in
/// front of one ask [verbatimRegionEnd] instead and allocate nothing.
(String text, int end) verbatimRegion(String source, int openIndex) {
  final end = verbatimRegionEnd(source, openIndex);

  var fence = 0;
  while (source[openIndex + fence] == verbatimFenceChar) {
    fence += 1;
  }

  var text = source.substring(openIndex + fence, end - fence);
  if (text.startsWith('\n')) text = text.substring(1);
  if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
  return (text, end);
}
