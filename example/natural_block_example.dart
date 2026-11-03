import 'package:natural_block/natural_block.dart';

/// Every construct the language has, parsed and printed.
///
/// `natural_block` only produces the tree -- rendering it is a separate
/// concern, and `natural_block_flutter` is one renderer for it.
void main() {
  _show('Decoration', r'''
:!Negative:! and :%Positive:% and :*Emphasis:*
:!*Negative and bold at once::back to plain
:+++Three steps larger:--- back to base
Bare punctuation is literal: C++, 10-20, 100%, Really?!, you@example.com
''');

  _show('Custom runs', r'''
:@https://example.com:@ is a URL, :@#getting-started:@ names a section.
The parser records only that a run is custom -- what it
means is the app's decision. :@image(https://example.com/a.png):@ is one
convention a renderer may recognise; anything that does not still reads
as ordinary text.
''');

  _show('Layout and alignment', r'''
A block with no marker
=A marker opens a new block
and its alignment holds until the next one.
^<start^=center^>end^
>Outside a row, a ^ is plain text.
''');

  _show('Tables', r'''
~
^<Item  ^>Price^Stock^
^Apple  ^150^12^
^Banana ^98^3^
~
>:*Total 248
''');

  _show('Raw regions', r'''
Compare `a == b` inline, or fence a block:
`
cat file.txt | grep foo | wc -l
`
''');

  _show('Escaping', r'''
\=> at the start of a line is literal text.
\^ too.
\~ and \: are literal, \\ is one backslash.
Inside a cluster a decoration character escapes too: :---\%off
A path needs nothing: C:\Users\you\a.png -- but prefer C:/Users/you/a.png
''');
}

void _show(String title, String source) {
  print('=== $title ===');
  print(source.trim());
  print('--- parses to ---');
  print(NaturalBlockParser.parse(source));
  print('');
}
