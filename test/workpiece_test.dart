import 'package:shaker/objects.dart';
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
      expect(w.gCodeDicts, equals([{'X': 1.0, 'G': 0}, {'M': 2}, {'G': 21}, {'G': 90}]));
    });
  });

  group('Simulation', () {

    test('G0 and G1 with G90 and G91', () {
      var w = Workpiece('G0 X10 Y 10');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(10, 10, 4)));
      w = Workpiece('G1 X10 Y 10 F100');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(10, 10, 4)));
      w = Workpiece('G1 X10 Y 10 F100\nG91 G1 X1 Y1');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(11, 11, 4)));
      w = Workpiece('G1 X10 Y 10 F100\nG91 G1 X1 Y1\nG90 G1 X0 Z-1.0');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(0, 11, -1)));
    });

  });
}