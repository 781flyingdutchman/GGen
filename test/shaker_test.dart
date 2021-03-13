import 'dart:io';

import 'package:shaker/objects.dart';
import 'package:shaker/artifacts/shaker_work.dart';
import 'package:test/test.dart';
import 'package:shaker/conversion.dart';


void main() {

  setUp(() {
    ShakerPanel().resetToDefaults();
  });

  test('No handle', () {
    var w = ShakerWork();
    w.generateCode();
    var file = File('test/gCode/shaker_without_handle_test.nc');
    // To reset test expectation (after verification!) uncomment next line once
    // file.writeAsStringSync(w.gCodeAsString);
    // remove all lines with reference to Time from the gCode
    var gCode = w.gCodeAsString
        .split('\n')
        .where((line) => !line.contains('Time:'))
        .join('\n');
    var fileGCode = file.readAsStringSync().split('\n')
        .where((line) => !line.contains('Time:'))
        .join('\n');
    expect(gCode, equals(fileGCode));
  });

  test('With handle', () {
    var panel = ShakerPanel();
    panel.handleOffset = Point(50, 50);
    panel.handleOrientationLandscape = true;
    panel.handleWidth = 4.inch;
    var w = ShakerWork();
    w.generateCode();
    var file = File('test/gCode/shaker_with_handle_test.nc');
    // To reset test expectation (after verification!) uncomment next line once
    // file.writeAsStringSync(w.gCodeAsString);
    // remove all lines with reference to Time from the gCode
    var gCode = w.gCodeAsString
        .split('\n')
        .where((line) => !line.contains('Time:'))
        .join('\n');
    var fileGCode = file.readAsStringSync().split('\n')
        .where((line) => !line.contains('Time:'))
        .join('\n');
    expect(gCode, equals(fileGCode));
  });

  test('With handle and shallow, 1mm holes', () {
    var panel = ShakerPanel();
    panel.handleOffset = Point(50, 50);
    panel.handleOrientationLandscape = true;
    panel.handleWidth = 4.inch;
    panel.handleHoleDepth = -1;
    var w = ShakerWork();
    w.generateCode();
    var file = File('test/gCode/shaker_with_handle_shallow_test.nc');
    // To reset test expectation (after verification!) uncomment next line once
    // file.writeAsStringSync(w.gCodeAsString);
    // remove all lines with reference to Time from the gCode
    var gCode = w.gCodeAsString
        .split('\n')
        .where((line) => !line.contains('Time:'))
        .join('\n');
    var fileGCode = file.readAsStringSync().split('\n')
        .where((line) => !line.contains('Time:'))
        .join('\n');
    expect(gCode, equals(fileGCode));
  });
}
