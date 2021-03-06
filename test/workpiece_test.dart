import 'package:shaker/workpiece.dart';
import 'package:test/test.dart';

void main() {

  group('utils', () {

    test('cleanCode', () {
      var w = Workpiece('A=4\n(comment)\n\n   X=4.5 Z1; test\n()');
      expect(w.cleanCodeLines(w.gCodeLines).toList(), equals(['A=4', 'X=4.5 Z1']));

    });

  });
}