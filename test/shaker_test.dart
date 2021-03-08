import 'package:shaker/objects.dart';
import 'package:shaker/artifacts/shaker_work.dart';
import 'package:test/test.dart';
import 'package:shaker/conversion.dart';


void main() {
  test('No handle', () {
    var w = ShakerWork();
    w.generateCode();
    print('No actual test comparisons for No handle');
  });

  test('With handle', () {
    var panel = ShakerPanel();
    panel.handleMidpoint = Point(50, 50);
    panel.handleOrientationLandscape = true;
    panel.handleWidth = 4.inch;
    var w = ShakerWork();
    w.generateCode();
    print(w.gCodeAsString);
    print('No actual test comparisons for With handle');
  });
}
