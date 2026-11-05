import 'dart:io';

import '../test/support/grid.dart';

/// Writes the grid's expected files from the parser as it stands now.
///
/// Read the diff before keeping it: regenerating without reading makes the
/// grid stop being a net.
void main() {
  for (final name in gridContexts.keys) {
    final file = File(gridPath(name));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('${gridText(name)}\n');
    stdout.writeln('wrote ${file.path}');
  }
  File(markupPath).writeAsStringSync('${markupText()}\n');
  stdout.writeln('wrote $markupPath');
}
