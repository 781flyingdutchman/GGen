import 'package:shaker/workpiece.dart';
import 'package:test/test.dart';

void main() {

  group('utils', () {

    test('gCodeWithoutComments', () {
      var w = Workpiece('A=4\n(comment)\n\n   X=4.5 Z1; test\n()');
      expect(w.gCodeWithoutComments, equals(['A=4', 'X=4.5 Z1']));
    });

    test('gCodeWithSplitGCommands', () {
      var w = Workpiece('G0 X1\nM2\nG21 G90');
      expect(w.gCodeWithSplitGCommands, equals(['G0 X1', 'M2', 'G21', 'G90']));
    });

    test('codeDict', () {
      var w = Workpiece('G0 X1\nM2\nG21 G90');
      print(w.gCodeDicts);
      expect(w.gCodeDicts, equals([{'X': 1.0, 'G': 0}, {'M': 2}, {'G': 21}, {'G': 90}]));
    });

  });
}