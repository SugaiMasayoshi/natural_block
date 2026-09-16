/// One character for each kind of thing the parser tells apart, keyed by the
/// name the grid files show it under.
///
/// The parser decides from the character it is on and the one after it, so
/// every pair of these, in every context, passes through every decision it
/// makes. `b` stands for any ordinary character, `!` for all decoration
/// characters and `<` for all alignment markers;
/// `representative_test.dart` checks that standing in is sound.
///
/// A name in capitals is one for a character that cannot be shown as itself:
/// `N` is the newline, and the grid adds `E` for the end of the document.
const Map<String, String> gridTokens = {
  'b': 'b',
  '|': '|',
  '^': '^',
  '~': '~',
  '`': '`',
  ':': ':',
  '!': '!',
  r'\': r'\',
  'N': '\n',
  '<': '<',
};

/// Where a pair is written, keyed by the name of its grid file.
///
/// A prefix leaves at most the letter `a` in the tree, so the placeholder
/// substitution in the grid cannot mistake a prefix character for the pair's.
/// The line start is written `|\n` rather than `a\n` for that reason: the `|`
/// ends the block before it and the newline is the one a block drops at its
/// start, so nothing of the prefix reaches the tree. `cluster_escape` is the
/// one exception -- its backslash can survive as text. A `\` in its shapes is
/// the prefix's; where the pair's first character is a backslash too, the
/// two collapse into one and it is shown as `X`.
///
/// A prefix also puts the pair where a decision reads it as its *next*
/// character: in `cluster_escape` the cluster is sitting on the backslash, so
/// the pair's first character is what it escapes.
const Map<String, String> gridContexts = {
  'document': '',
  'text': 'a',
  'row_cell': 'a^',
  'table_cell': '~',
  'decorated': ':!a',
  'cluster': ':!',
  'cluster_escape': r':!\',
  'table_row': '~a|',
  'line_start': '|\n',
};
