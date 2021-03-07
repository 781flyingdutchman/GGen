import 'package:shaker/multi_workpiece.dart';
import 'package:shaker/objects.dart';
import 'package:shaker/work_simulator.dart';
import 'package:test/test.dart';

final testCode = 'G1 X10 Y10 F100';
final testCodeTall =  'G1 X10 Y20 F100';

void main() {

  test('add', () {
    var w = WorkSimulator(testCode);
    w.simulate();
    expect(w.physicalBox, equals(Rect(Point.zero(), Point(10, 10))));
    var multi = MultiWorkpiece();
    expect(() => multi.add(WorkpiecePlacement(w, Placement.up)), throwsStateError);
    multi.add(WorkpiecePlacement(w, Placement.initial));
    expect(() => multi.add(WorkpiecePlacement(w, Placement.initial)), throwsStateError);
    multi.add(WorkpiecePlacement(w, Placement.right));
  });

  test('layout right', () {
    var w = WorkSimulator(testCode);
    var multi = MultiWorkpiece();
    multi.add(WorkpiecePlacement(w, Placement.initial));
    multi.layout();
    expect(multi.encompassingBox(), equals(Rect(Point.zero(), Point(10, 10))));
    multi.add(WorkpiecePlacement(w, Placement.right));
    multi.safetyMargin = 0;
    multi.layout();
    expect(multi.encompassingBox(), equals(Rect(Point.zero(), Point(20, 10))));
    multi.safetyMargin = 20;
    multi.layout();
    expect(multi.encompassingBox(), equals(Rect(Point.zero(), Point(40, 10))));
  });

  test('layout right and up', () {
    var w = WorkSimulator(testCode);
    var multi = MultiWorkpiece();
    multi.add(WorkpiecePlacement(w, Placement.initial));
    multi.add(WorkpiecePlacement(w, Placement.right));
    multi.add(WorkpiecePlacement(w, Placement.up));
    multi.layout();
    expect(multi.encompassingBox(), equals(Rect(Point.zero(), Point(40, 40))));
    expect(multi.machineBoxes.last, equals(Rect(Point(30, 30), Point(40, 40))));
  });

  test('layout right and upAlignLeft', () {
    var w = WorkSimulator(testCode);
    var multi = MultiWorkpiece();
    multi.add(WorkpiecePlacement(w, Placement.initial));
    multi.add(WorkpiecePlacement(w, Placement.right));
    multi.add(WorkpiecePlacement(w, Placement.upAlignLeft));
    multi.layout();
    expect(multi.encompassingBox(), equals(Rect(Point.zero(), Point(40, 40))));
    expect(multi.machineBoxes.last, equals(Rect(Point(0, 30), Point(10, 40))));
    // add another one to the right
    multi.add(WorkpiecePlacement(w, Placement.right));
    multi.layout();
    expect(multi.encompassingBox(), equals(Rect(Point.zero(), Point(40, 40))));
    expect(multi.machineBoxes.last, equals(Rect(Point(30, 30), Point(40, 40))));
  });

  test('layout right and upAlignLeft with tall items', () {
    var w = WorkSimulator(testCode);
    var wTall = WorkSimulator(testCodeTall);
    var multi = MultiWorkpiece();
    multi.add(WorkpiecePlacement(wTall, Placement.initial));
    multi.add(WorkpiecePlacement(w, Placement.right));
    multi.add(WorkpiecePlacement(w, Placement.upAlignLeft));
    multi.layout();
    expect(multi.encompassingBox(), equals(Rect(Point.zero(), Point(40, 50))));
    expect(multi.machineBoxes.last, equals(Rect(Point(0, 40), Point(10, 50))));
  });

  test('layout right and upAlignLeft with multiple tall items', () {
    var w = WorkSimulator(testCode);
    var wTall = WorkSimulator(testCodeTall);
    var multi = MultiWorkpiece();
    multi.add(WorkpiecePlacement(w, Placement.initial));
    multi.add(WorkpiecePlacement(wTall, Placement.right));
    multi.add(WorkpiecePlacement(w, Placement.upAlignLeft));
    multi.layout();
    expect(multi.encompassingBox(), equals(Rect(Point(0, -5), Point(40, 40))));
    expect(multi.machineBoxes.last, equals(Rect(Point(0, 30), Point(10, 40))));
    // add to right should 'skip' the tall object placed second
    multi.add(WorkpiecePlacement(w, Placement.right));
    multi.layout();
    expect(multi.encompassingBox(), equals(Rect(Point(0, -5), Point(70, 40))));
    expect(multi.machineBoxes.last, equals(Rect(Point(60, 30), Point(70, 40))));
  });
}