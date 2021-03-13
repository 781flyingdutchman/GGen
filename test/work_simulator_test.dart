import 'package:shaker/objects.dart';
import 'package:shaker/work_simulator.dart';
import 'package:test/test.dart';
import 'dart:io';
import 'package:shaker/conversion.dart';

void main() {

  group('utils', () {

    test('gCodeWithoutComments', () {
      var w = WorkSimulator('A=4\n(comment)\n\n   X=4.5 Z1; test\n()');
      expect(w.gCodeWithoutComments, equals(['A=4', 'X=4.5 Z1']));
    });

    test('gCodeWithSplitGCommands', () {
      var w = WorkSimulator('G0 X1\nM2\nG21 G90');
      expect(w.gCodeWithSplitGCommands, equals(['G0 X1', 'M2', 'G21', 'G90']));
    });

    test('codeDict', () {
      var w = WorkSimulator('G0 X1\nM2\nG21 G90');
      expect(w.gCodeDicts, equals([{'line': 'G0 X1', 'X': 1.0, 'G': 0},
        {'line': 'M2', 'M': 2},
        {'line': 'G21', 'G': 21},
        {'line': 'G90', 'G': 90}]));
    });

    test('gCodeWithout specific code, like M2', () {
      var w = WorkSimulator('G0 X1 F150\nM2\n; M2\n(M2)\nM2 G17');
      expect(w.gCodeWithout('M2'), equals('G0 X1 F150\n\n; M2\n(M2)\nG17\n'));
    });

    test('updateBoxes', () {
      var w = WorkSimulator('G1 X10 Y 10 F100');
      w.toolPoint = Point3D(10, 11, 0);
      w.updateBoxes();
      expect(w.box.bl, equals(Point(0, 0)));
      expect(w.box.tr, equals(Point(10, 11)));
      w.toolPoint = Point3D(-10, -11, 0);
      w.updateBoxes();
      expect(w.box.bl, equals(Point(-10, -11)));
      expect(w.box.tr, equals(Point(10, 11)));
      expect(w.physicalBox, Rect(Point(0, 0), Point(0, 0)));
      w.toolPoint = Point3D(0, 0, 0); // inside box, so no change
      w.updateBoxes();
      expect(w.box.bl, equals(Point(-10, -11)));
      expect(w.box.tr, equals(Point(10, 11)));
      expect(w.physicalBox, Rect(Point(0, 0), Point(0, 0)));
      // move physicalToolPoint
      w.physicalToolPoint = Point3D(10, 11, 0);
      w.updateBoxes();
      expect(w.physicalBox, Rect(Point(0, 0), Point(10, 11)));
    });

    test('elapsedTime', () {
      var w = WorkSimulator('G1 X100 F100');
      w.simulate();
      expect(w.elapsedTime, equals(Duration(minutes: 1)));
    });
  });

  group('Simulation', () {

    test('G0 and G1 with G90 and G91', () {
      var w = WorkSimulator('G0 X10 Y 10');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(10, 10, 4)));
      w = WorkSimulator('G1 X10 Y 10 F100');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(10, 10, 4)));
      w = WorkSimulator('G1 X10 Y 10 F100\nG91 G1 X1 Y1');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(11, 11, 4)));
      w = WorkSimulator('G1 X10 Y 10 F100\nG91 G1 X1 Y1\nG90 G1 X0 Z-1.0');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(0, 11, -1)));
    });

    test('G2', () {
      var w = WorkSimulator('G1 Y10 F100\nG2 X10 Y0 I0 J-10');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(10, 0, 4)));
      expect(w.box, equals(Rect(Point(0, 0), Point(10, 10))));
      w = WorkSimulator('G1 Y-10 F100\nG2 X10 Y0 I0 J-10');
      expect(() => w.simulate(), throwsStateError); // center improperly defined
      w = WorkSimulator('G1 Y-10 F100\nG2 X10 Y0 I0 J+10');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(10, 0, 4)));
      expect(w.box, equals(Rect(Point(-10, -10), Point(10, 10))));
    });

    test('G3', () {
      var w = WorkSimulator('G1 Y10 F100\nG3 X10 Y0 I0 J-10');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(10, 0, 4)));
      expect(w.box, equals(Rect(Point(-10, -10), Point(10, 10))));
      w = WorkSimulator('G1 Y-10 F100\nG3 X10 Y0 I0 J-10');
      expect(() => w.simulate(), throwsStateError); // center improperly defined
      w = WorkSimulator('G1 Y-10 F100\nG3 X10 Y0 I0 J+10');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(10, 0, 4)));
      expect(w.box, equals(Rect(Point(0, -10), Point(10, 0))));
    });

    test('G20 - programming in inches', () {
      var w = WorkSimulator('G20\nG0 X10 Y 10');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(10.inch, 10.inch, 4)));
      w = WorkSimulator('G20 G1 X10 Y 10 F100');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(10.inch, 10.inch, 4)));
      w = WorkSimulator('G20 G1 Y10 F100\nG2 X10 Y0 I0 J-10');
      w.simulate();
      expect(w.toolPoint, equals(Point3D(10.inch, 0, 4)));
      expect(w.box, equals(Rect(Point(0, 0), Point(10.inch, 10.inch))));
    });

  });

  group('Actual g-code', () {

    test('dp_side_right.nc - regular large cuts', () {
      var w = WorkSimulator(File('test/gCode/dp_side_right.nc').readAsStringSync());
      w.simulate();
      expect(w.box, equals(Rect(Point(-301.375, -3.175), Point(301.375, 745.875))));
      expect(w.box, equals(w.physicalBox));
      expect(w.elapsedTime, equals(Duration(minutes: 46, seconds: 11, milliseconds: 982)));
    });

    test('slider_spacer_left_3ct_vertical_displaced.nc with displacement', () {
      var w = WorkSimulator(File('test/gCode/slider_spacer_left_3ct_vertical_displaced.nc').readAsStringSync());
      w.simulate();
      expect(w.box, equals(Rect(Point(-3.175, -3.175), Point(532.175, 57))));
      expect(w.physicalBox, equals(Rect(Point(-3.175, -3.175), Point(532.175, 161.175))));
    });

  });
}