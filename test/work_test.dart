import 'package:shaker/work.dart';
import 'package:test/test.dart';
import 'package:shaker/objects.dart';

void main() {

  test('Rectangle', () {
    var w = ShakerWork();
    var rect = Rect(Point(0, 0), Point(100, 100));
    w.addRectCut(rect);
    expect(w.gCode.toString(), equals('[(Rectangle cut), G0 Z5.0, G0  X-3.1750 Y-3.1750, G0 Z1.0, G1  X-3.1750 Y-3.1750 Z-5.0000 F60.0000, G1  X-3.1750 Y103.1750 Z-5.0000 F500.0000, G1  X103.1750 Y103.1750 Z-5.0000 F500.0000, G1  X103.1750 Y-3.1750 Z-5.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-5.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-10.0000 F60.0000, G1  X-3.1750 Y103.1750 Z-10.0000 F500.0000, G1  X103.1750 Y103.1750 Z-10.0000 F500.0000, G1  X103.1750 Y-3.1750 Z-10.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-10.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-15.0000 F60.0000, G1  X-3.1750 Y103.1750 Z-15.0000 F500.0000, G1  X103.1750 Y103.1750 Z-15.0000 F500.0000, G1  X103.1750 Y-3.1750 Z-15.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-15.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-20.0000 F60.0000, G1  X-3.1750 Y103.1750 Z-20.0000 F500.0000, G1  X103.1750 Y103.1750 Z-20.0000 F500.0000, G1  X103.1750 Y-3.1750 Z-20.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-20.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-21.5000 F60.0000, G1  X-3.1750 Y103.1750 Z-21.5000 F500.0000, G1  X103.1750 Y103.1750 Z-21.5000 F500.0000, G1  X103.1750 Y-3.1750 Z-21.5000 F500.0000, G1  X-3.1750 Y-3.1750 Z-21.5000 F500.0000, G0 Z1.0;  Rectangle cut done]'));
    w = ShakerWork();
    expect(() => w.addRectCut(rect, cutDepth: 10), throwsStateError);
    w.addRectCut(rect, cutDepth: -12, description: 'testCut');
    expect(w.gCode[0], equals('(testCut)'));
    expect(w.gCode.toString(), equals('[(testCut), G0 Z5.0, G0  X-3.1750 Y-3.1750, G0 Z1.0, G1  X-3.1750 Y-3.1750 Z-5.0000 F60.0000, G1  X-3.1750 Y103.1750 Z-5.0000 F500.0000, G1  X103.1750 Y103.1750 Z-5.0000 F500.0000, G1  X103.1750 Y-3.1750 Z-5.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-5.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-10.0000 F60.0000, G1  X-3.1750 Y103.1750 Z-10.0000 F500.0000, G1  X103.1750 Y103.1750 Z-10.0000 F500.0000, G1  X103.1750 Y-3.1750 Z-10.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-10.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-12.0000 F60.0000, G1  X-3.1750 Y103.1750 Z-12.0000 F500.0000, G1  X103.1750 Y103.1750 Z-12.0000 F500.0000, G1  X103.1750 Y-3.1750 Z-12.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-12.0000 F500.0000, G0 Z1.0;  Rectangle cut done]'));
    w = ShakerWork();
    w.addRectCut(rect, makeTabs: true); // should be same result as normal
    expect(w.gCode.toString(), equals('[(Rectangle cut), G0 Z5.0, G0  X-3.1750 Y-3.1750, G0 Z1.0, G1  X-3.1750 Y-3.1750 Z-5.0000 F60.0000, G1  X-3.1750 Y103.1750 Z-5.0000 F500.0000, G1  X103.1750 Y103.1750 Z-5.0000 F500.0000, G1  X103.1750 Y-3.1750 Z-5.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-5.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-10.0000 F60.0000, G1  X-3.1750 Y103.1750 Z-10.0000 F500.0000, G1  X103.1750 Y103.1750 Z-10.0000 F500.0000, G1  X103.1750 Y-3.1750 Z-10.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-10.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-15.0000 F60.0000, G1  X-3.1750 Y103.1750 Z-15.0000 F500.0000, G1  X103.1750 Y103.1750 Z-15.0000 F500.0000, G1  X103.1750 Y-3.1750 Z-15.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-15.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-20.0000 F60.0000, G1  X-3.1750 Y103.1750 Z-20.0000 F500.0000, G1  X103.1750 Y103.1750 Z-20.0000 F500.0000, G1  X103.1750 Y-3.1750 Z-20.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-20.0000 F500.0000, G1  X-3.1750 Y-3.1750 Z-21.5000 F60.0000, G1  X-3.1750 Y103.1750 Z-21.5000 F500.0000, G1  X103.1750 Y103.1750 Z-21.5000 F500.0000, G1  X103.1750 Y-3.1750 Z-21.5000 F500.0000, G1  X-3.1750 Y-3.1750 Z-21.5000 F500.0000, G0 Z1.0;  Rectangle cut done]'));
    w = ShakerWork();
    rect = Rect(Point(0, 0), Point(1000, 1000));
    w.addRectCut(rect, makeTabs: true);
    print(w.gCode.join('\n'));

  });
}