import 'package:shaker/objects.dart';
import 'package:test/test.dart';

void main() {
  group('Rect', () {

    test('withNew', () {
      var r = Rect(Point(0, 0), Point(10, 20));
      expect(r.width, 10);
      expect(r.height, 20);
      var r2 = r.withNewLeft(-1);
      expect(r2.bl.x, equals(-1));
      expect(r2.width, 11);
      expect(r2.height, 20);
      r2 = r.withNewRight(11);
      expect(r2.tr.x, equals(11));
      expect(r2.width, 11);
      expect(r2.height, 20);
      r2 = r.withNewTop(11);
      expect(r2.tr.y, equals(11));
      expect(r2.width, 10);
      expect(r2.height, 11);
      r2 = r.withNewBottom(11);
      expect(r2.bl.y, equals(11));
      expect(r2.width, 10);
      expect(r2.height, 9);
    });

    test('center and centerOn', () {
      var r = Rect(Point(0, 0), Point(10, 20));
      expect(r.width, 10);
      expect(r.height, 20);
      var centerRect = Rect(Point(-1, -1), Point(1, 1));
      expect(centerRect.center, equals(Point(0,0)));
      var r2 = r.centerOn(centerRect);
      expect(r2.width, 10);
      expect(r2.height, 20);
      expect(r2.center, equals(Point(0,0)));
    });

  });
}