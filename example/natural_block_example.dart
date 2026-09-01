import 'package:natural_block/natural_block.dart';

/// Every construct the language has, parsed and printed.
///
/// `natural_block` only produces the tree -- rendering it is a separate
/// concern, and `natural_block_flutter` is one renderer for it.
void main() {
  _show('Decoration', r'''
:!Danger:! and :%Success:% and :?Info:? and :*Emphasis:*
:!*Danger and bold at once::back to plain
:+++Three steps larger:--- back to base
Bare punctuation is literal: C++, 10-20, 100%, Really?!, you@example.com
''');

  _show('Actionable runs', r'''
:@https://example.com:@ is a URL, :@#getting-started:@ names a section.
The parser records only that a run is actionable -- what acting on it
means is the app's decision. :@image(https://example.com/a.png):@ is one
convention a renderer may recognise; anything that does not still reads
as ordinary text.
''');

  _show('Layout and alignment', r'''
|A vertical block
|<start=^center=>end|
Left==Right
''');

  _show('Tables', r'''
|~Item=>Price=^Stock|
Apple=150=12|
Banana=98=3|~
:*Total=>248
''');

  _show('Escaping', r'''
\|and \= and \: are literal, \\ is one backslash.
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
