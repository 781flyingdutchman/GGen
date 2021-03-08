import 'dart:io';

import 'package:shaker/multi_workpiece.dart';
import 'package:shaker/objects.dart';
import 'package:shaker/work_simulator.dart';
import 'package:test/test.dart';

final testCode = 'G1 X10 Y10 F100';
final testCodeTall = 'G1 X10 Y20 F100';
final testCodeWithG10 = 'G1 X10 Y10 F100\nG10 L20 P1 Y0';

void main() {
  group('layout', () {
    test('add', () {
      var w = WorkSimulator(testCode);
      w.simulate();
      expect(w.physicalBox, equals(Rect(Point.zero(), Point(10, 10))));
      var multi = MultiWorkpiece();
      expect(() => multi.add(WorkpiecePlacement(w, Placement.up)),
          throwsStateError);
      multi.add(WorkpiecePlacement(w, Placement.initial));
      expect(() => multi.add(WorkpiecePlacement(w, Placement.initial)),
          throwsStateError);
      multi.add(WorkpiecePlacement(w, Placement.right));
    });

    test('layout right', () {
      var w = WorkSimulator(testCode);
      var multi = MultiWorkpiece();
      multi.add(WorkpiecePlacement(w, Placement.initial));
      multi.layout();
      expect(
          multi.encompassingBox(), equals(Rect(Point.zero(), Point(10, 10))));
      multi.add(WorkpiecePlacement(w, Placement.right));
      multi.safetyMargin = 0;
      multi.layout();
      expect(
          multi.encompassingBox(), equals(Rect(Point.zero(), Point(20, 10))));
      multi.safetyMargin = 20;
      multi.layout();
      expect(
          multi.encompassingBox(), equals(Rect(Point.zero(), Point(40, 10))));
    });

    test('layout right and up', () {
      var w = WorkSimulator(testCode);
      var multi = MultiWorkpiece();
      multi.add(WorkpiecePlacement(w, Placement.initial));
      multi.add(WorkpiecePlacement(w, Placement.right));
      multi.add(WorkpiecePlacement(w, Placement.up));
      multi.layout();
      expect(
          multi.encompassingBox(), equals(Rect(Point.zero(), Point(40, 40))));
      expect(
          multi.machineBoxes.last, equals(Rect(Point(30, 30), Point(40, 40))));
    });

    test('layout right and upAlignLeft', () {
      var w = WorkSimulator(testCode);
      var multi = MultiWorkpiece();
      multi.add(WorkpiecePlacement(w, Placement.initial));
      multi.add(WorkpiecePlacement(w, Placement.right));
      multi.add(WorkpiecePlacement(w, Placement.upAlignLeft));
      multi.layout();
      expect(
          multi.encompassingBox(), equals(Rect(Point.zero(), Point(40, 40))));
      expect(
          multi.machineBoxes.last, equals(Rect(Point(0, 30), Point(10, 40))));
      // add another one to the right
      multi.add(WorkpiecePlacement(w, Placement.right));
      multi.layout();
      expect(
          multi.encompassingBox(), equals(Rect(Point.zero(), Point(40, 40))));
      expect(
          multi.machineBoxes.last, equals(Rect(Point(30, 30), Point(40, 40))));
    });

    test('layout right and upAlignLeft with tall items', () {
      var w = WorkSimulator(testCode);
      var wTall = WorkSimulator(testCodeTall);
      var multi = MultiWorkpiece();
      multi.add(WorkpiecePlacement(wTall, Placement.initial));
      multi.add(WorkpiecePlacement(w, Placement.right));
      multi.add(WorkpiecePlacement(w, Placement.upAlignLeft));
      multi.layout();
      expect(
          multi.encompassingBox(), equals(Rect(Point.zero(), Point(40, 50))));
      expect(
          multi.machineBoxes.last, equals(Rect(Point(0, 40), Point(10, 50))));
    });

    test('layout right and upAlignLeft with multiple tall items', () {
      var w = WorkSimulator(testCode);
      var wTall = WorkSimulator(testCodeTall);
      var multi = MultiWorkpiece();
      multi.add(WorkpiecePlacement(w, Placement.initial));
      multi.add(WorkpiecePlacement(wTall, Placement.right));
      multi.add(WorkpiecePlacement(w, Placement.upAlignLeft));
      multi.layout();
      expect(
          multi.encompassingBox(), equals(Rect(Point(0, -5), Point(40, 40))));
      expect(
          multi.machineBoxes.last, equals(Rect(Point(0, 30), Point(10, 40))));
      // add to right should 'skip' the tall object placed second
      multi.add(WorkpiecePlacement(w, Placement.right));
      multi.layout();
      expect(
          multi.encompassingBox(), equals(Rect(Point(0, -5), Point(70, 40))));
      expect(
          multi.machineBoxes.last, equals(Rect(Point(60, 30), Point(70, 40))));
    });
  });

  group('generate', () {
    test('single', () {
      var w = WorkSimulator(testCode);
      var multi = MultiWorkpiece();
      multi.add(WorkpiecePlacement(w, Placement.initial));
      expect(() => multi.generateCode(), throwsStateError); // no layout yet
      multi.layout();
      expect(multi.generateCode(), contains(testCode));
    });

    test('multiple placements, no G10 within each', () {
      var w = WorkSimulator(testCode);
      var multi = MultiWorkpiece();
      multi.add(WorkpiecePlacement(w, Placement.initial,
          description: 'first workpiece'));
      multi.add(WorkpiecePlacement(w, Placement.right,
          description: 'second workpiece'));
      multi.layout();
      expect(multi.generateCode(), contains('G10 L20 P1 X-20.0000 Y10.0000'));
      expect(
          multi.generateCode(), contains('(Move origin for second workpiece)'));
      multi.add(WorkpiecePlacement(w, Placement.upAlignLeft,
          description: 'third workpiece'));
      multi.layout();
      expect(multi.generateCode(), contains('G10 L20 P1 X40.0000 Y-20.0000'));
    });

    test('multiple placements, with G10 within each', () {
      var w = WorkSimulator(testCodeWithG10);
      var multi = MultiWorkpiece();
      multi.add(WorkpiecePlacement(w, Placement.initial,
          description: 'first workpiece'));
      multi.add(WorkpiecePlacement(w, Placement.right,
          description: 'second workpiece'));
      multi.layout();
      expect(multi.generateCode(), contains('G10 L20 P1 X-20.0000 Y10.0000'));
      expect(
          multi.generateCode(), contains('(Move origin for second workpiece)'));
      multi.add(WorkpiecePlacement(w, Placement.upAlignLeft,
          description: 'third workpiece'));
      multi.layout();
      expect(multi.generateCode(), contains('G10 L20 P1 X40.0000 Y-20.0000'));
    });

    test('Actual workpiece', () {
      var w =
          WorkSimulator(File('test/gCode/slider_spacer.nc').readAsStringSync());
      var multi = MultiWorkpiece();
      multi
          .add(WorkpiecePlacement(w, Placement.initial, description: 'Part 1'));
      multi.add(WorkpiecePlacement(w, Placement.up, description: 'Part 2'));
      multi.add(WorkpiecePlacement(w, Placement.up, description: 'Part 3'));
      multi.layout();
      var multiWorkGenerator = MultiWorkGenerator(multi);
      multiWorkGenerator.generateCode();
      var file = File('test/gCode/multi_workpiece_test.nc');
      // To reset test expectation (after verification!) uncomment next line once
      // file.writeAsStringSync(multiWorkGenerator.gCodeAsString);
      // remove all lines with reference to Time from the gCode
      var gCode = multiWorkGenerator.gCodeAsString
          .split('\n')
          .where((line) => !line.contains('Time:'))
          .join('\n');
      var fileGCode = file.readAsStringSync().split('\n')
          .where((line) => !line.contains('Time:'))
          .join('\n');
      expect(gCode, equals(fileGCode));
    });
  });
}
