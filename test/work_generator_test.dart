import 'package:shaker/conversion.dart';
import 'package:shaker/objects.dart';
import 'package:shaker/work_generator.dart';
import 'package:test/test.dart';

void main() {
  group('utils', () {
    test('comment', () {
      var w = WorkGenerator();
      expect(w.comment('test'), equals('(test)'));
      expect(
          w.comment(
              'test a very long line with different characters over 35 in length'),
          equals('(test a very long line with)\n'
              '(different characters over 35 in)\n'
              '(length)'));
      expect(w.comment('averylonglinewithoutspacvesgoingover25inlneght'),
          equals('(averylonglinewithoutspacvesgoingov)\n'
              '(er25inlneght)'));
      expect(w.comment('c(ommentWith)'), equals('(c[ommentWith])'));
    });
  });

  group('addRectCut', () {
    test('addRectCut regular', () {
      var w = WorkGenerator();
      var rect = Rect(Point(0, 0), Point(100, 100));
      w.addRectCut(rect);
      expect(
          w.gCode.toString(),
          equals(
              '[, (Rectangle cut), G0 Z5.0000, G0 X-3.1750 Y-3.1750, G0 Z1.0000, G1 X-3.1750 Y-3.1750 Z-5.0000 F60.0000, G1 X-3.1750 Y103.1750 Z-5.0000 F500.0000, G1 X103.1750 Y103.1750 Z-5.0000 F500.0000, G1 X103.1750 Y-3.1750 Z-5.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-5.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-10.0000 F60.0000, G1 X-3.1750 Y103.1750 Z-10.0000 F500.0000, G1 X103.1750 Y103.1750 Z-10.0000 F500.0000, G1 X103.1750 Y-3.1750 Z-10.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-10.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-15.0000 F60.0000, G1 X-3.1750 Y103.1750 Z-15.0000 F500.0000, G1 X103.1750 Y103.1750 Z-15.0000 F500.0000, G1 X103.1750 Y-3.1750 Z-15.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-15.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-20.0000 F60.0000, G1 X-3.1750 Y103.1750 Z-20.0000 F500.0000, G1 X103.1750 Y103.1750 Z-20.0000 F500.0000, G1 X103.1750 Y-3.1750 Z-20.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-20.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-21.5000 F60.0000, G1 X-3.1750 Y103.1750 Z-21.5000 F500.0000, G1 X103.1750 Y103.1750 Z-21.5000 F500.0000, G1 X103.1750 Y-3.1750 Z-21.5000 F500.0000, G1 X-3.1750 Y-3.1750 Z-21.5000 F500.0000, G0 Z1.0000;  Rectangle cut done]'));
      w = WorkGenerator();
      expect(() => w.addRectCut(rect, cutDepth: 10), throwsStateError);
      w.addRectCut(rect, cutDepth: -12, description: 'testCut');
      expect(w.gCode[1], equals('(testCut)'));
      expect(
          w.gCode.toString(),
          equals(
              '[, (testCut), G0 Z5.0000, G0 X-3.1750 Y-3.1750, G0 Z1.0000, G1 X-3.1750 Y-3.1750 Z-5.0000 F60.0000, G1 X-3.1750 Y103.1750 Z-5.0000 F500.0000, G1 X103.1750 Y103.1750 Z-5.0000 F500.0000, G1 X103.1750 Y-3.1750 Z-5.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-5.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-10.0000 F60.0000, G1 X-3.1750 Y103.1750 Z-10.0000 F500.0000, G1 X103.1750 Y103.1750 Z-10.0000 F500.0000, G1 X103.1750 Y-3.1750 Z-10.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-10.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-12.0000 F60.0000, G1 X-3.1750 Y103.1750 Z-12.0000 F500.0000, G1 X103.1750 Y103.1750 Z-12.0000 F500.0000, G1 X103.1750 Y-3.1750 Z-12.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-12.0000 F500.0000, G0 Z1.0000;  Rectangle cut done]'));
    });

    test('addRectCut with tabs', () {
      var w = WorkGenerator();
      var rect = Rect(Point(0, 0), Point(1000, 1000));
      w.addRectCut(rect, makeTabs: true);
      expect(
          w.gCode.toString(),
          equals(
              '[, (Rectangle cut), G0 Z5.0000, G0 X-3.1750 Y-3.1750, G0 Z1.0000, G1 X-3.1750 Y-3.1750 Z-5.0000 F60.0000, G1 X-3.1750 Y1003.1750 Z-5.0000 F500.0000, G1 X1003.1750 Y1003.1750 Z-5.0000 F500.0000, G1 X1003.1750 Y-3.1750 Z-5.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-5.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-10.0000 F60.0000, G1 X-3.1750 Y238.4125 Z-10.0000 F500.0000, G1 X-3.1750 Y238.4125 Z-9.0000 F120.0000;  tab, G1 X-3.1750 Y264.7625 Z-9.0000 F500.0000, G1 X-3.1750 Y264.7625 Z-10.0000 F60.0000, G1 X-3.1750 Y490.0000 Z-10.0000 F500.0000, G1 X-3.1750 Y490.0000 Z-9.0000 F120.0000;  tab, G1 X-3.1750 Y516.3500 Z-9.0000 F500.0000, G1 X-3.1750 Y516.3500 Z-10.0000 F60.0000, G1 X-3.1750 Y741.5875 Z-10.0000 F500.0000, G1 X-3.1750 Y741.5875 Z-9.0000 F120.0000;  tab, G1 X-3.1750 Y767.9375 Z-9.0000 F500.0000, G1 X-3.1750 Y767.9375 Z-10.0000 F60.0000, G1 X-3.1750 Y1003.1750 Z-10.0000 F500.0000, G1 X238.4125 Y1003.1750 Z-10.0000 F500.0000, G1 X238.4125 Y1003.1750 Z-9.0000 F120.0000;  tab, G1 X264.7625 Y1003.1750 Z-9.0000 F500.0000, G1 X264.7625 Y1003.1750 Z-10.0000 F60.0000, G1 X490.0000 Y1003.1750 Z-10.0000 F500.0000, G1 X490.0000 Y1003.1750 Z-9.0000 F120.0000;  tab, G1 X516.3500 Y1003.1750 Z-9.0000 F500.0000, G1 X516.3500 Y1003.1750 Z-10.0000 F60.0000, G1 X741.5875 Y1003.1750 Z-10.0000 F500.0000, G1 X741.5875 Y1003.1750 Z-9.0000 F120.0000;  tab, G1 X767.9375 Y1003.1750 Z-9.0000 F500.0000, G1 X767.9375 Y1003.1750 Z-10.0000 F60.0000, G1 X1003.1750 Y1003.1750 Z-10.0000 F500.0000, G1 X1003.1750 Y767.9375 Z-10.0000 F500.0000, G1 X1003.1750 Y767.9375 Z-9.0000 F120.0000;  tab, G1 X1003.1750 Y741.5875 Z-9.0000 F500.0000, G1 X1003.1750 Y741.5875 Z-10.0000 F60.0000, G1 X1003.1750 Y516.3500 Z-10.0000 F500.0000, G1 X1003.1750 Y516.3500 Z-9.0000 F120.0000;  tab, G1 X1003.1750 Y490.0000 Z-9.0000 F500.0000, G1 X1003.1750 Y490.0000 Z-10.0000 F60.0000, G1 X1003.1750 Y264.7625 Z-10.0000 F500.0000, G1 X1003.1750 Y264.7625 Z-9.0000 F120.0000;  tab, G1 X1003.1750 Y238.4125 Z-9.0000 F500.0000, G1 X1003.1750 Y238.4125 Z-10.0000 F60.0000, G1 X1003.1750 Y-3.1750 Z-10.0000 F500.0000, G1 X767.9375 Y-3.1750 Z-10.0000 F500.0000, G1 X767.9375 Y-3.1750 Z-9.0000 F120.0000;  tab, G1 X741.5875 Y-3.1750 Z-9.0000 F500.0000, G1 X741.5875 Y-3.1750 Z-10.0000 F60.0000, G1 X516.3500 Y-3.1750 Z-10.0000 F500.0000, G1 X516.3500 Y-3.1750 Z-9.0000 F120.0000;  tab, G1 X490.0000 Y-3.1750 Z-9.0000 F500.0000, G1 X490.0000 Y-3.1750 Z-10.0000 F60.0000, G1 X264.7625 Y-3.1750 Z-10.0000 F500.0000, G1 X264.7625 Y-3.1750 Z-9.0000 F120.0000;  tab, G1 X238.4125 Y-3.1750 Z-9.0000 F500.0000, G1 X238.4125 Y-3.1750 Z-10.0000 F60.0000, G1 X-3.1750 Y-3.1750 Z-10.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-15.0000 F60.0000, G1 X-3.1750 Y238.4125 Z-15.0000 F500.0000, G1 X-3.1750 Y238.4125 Z-9.0000 F120.0000;  tab, G1 X-3.1750 Y264.7625 Z-9.0000 F500.0000, G1 X-3.1750 Y264.7625 Z-15.0000 F60.0000, G1 X-3.1750 Y490.0000 Z-15.0000 F500.0000, G1 X-3.1750 Y490.0000 Z-9.0000 F120.0000;  tab, G1 X-3.1750 Y516.3500 Z-9.0000 F500.0000, G1 X-3.1750 Y516.3500 Z-15.0000 F60.0000, G1 X-3.1750 Y741.5875 Z-15.0000 F500.0000, G1 X-3.1750 Y741.5875 Z-9.0000 F120.0000;  tab, G1 X-3.1750 Y767.9375 Z-9.0000 F500.0000, G1 X-3.1750 Y767.9375 Z-15.0000 F60.0000, G1 X-3.1750 Y1003.1750 Z-15.0000 F500.0000, G1 X238.4125 Y1003.1750 Z-15.0000 F500.0000, G1 X238.4125 Y1003.1750 Z-9.0000 F120.0000;  tab, G1 X264.7625 Y1003.1750 Z-9.0000 F500.0000, G1 X264.7625 Y1003.1750 Z-15.0000 F60.0000, G1 X490.0000 Y1003.1750 Z-15.0000 F500.0000, G1 X490.0000 Y1003.1750 Z-9.0000 F120.0000;  tab, G1 X516.3500 Y1003.1750 Z-9.0000 F500.0000, G1 X516.3500 Y1003.1750 Z-15.0000 F60.0000, G1 X741.5875 Y1003.1750 Z-15.0000 F500.0000, G1 X741.5875 Y1003.1750 Z-9.0000 F120.0000;  tab, G1 X767.9375 Y1003.1750 Z-9.0000 F500.0000, G1 X767.9375 Y1003.1750 Z-15.0000 F60.0000, G1 X1003.1750 Y1003.1750 Z-15.0000 F500.0000, G1 X1003.1750 Y767.9375 Z-15.0000 F500.0000, G1 X1003.1750 Y767.9375 Z-9.0000 F120.0000;  tab, G1 X1003.1750 Y741.5875 Z-9.0000 F500.0000, G1 X1003.1750 Y741.5875 Z-15.0000 F60.0000, G1 X1003.1750 Y516.3500 Z-15.0000 F500.0000, G1 X1003.1750 Y516.3500 Z-9.0000 F120.0000;  tab, G1 X1003.1750 Y490.0000 Z-9.0000 F500.0000, G1 X1003.1750 Y490.0000 Z-15.0000 F60.0000, G1 X1003.1750 Y264.7625 Z-15.0000 F500.0000, G1 X1003.1750 Y264.7625 Z-9.0000 F120.0000;  tab, G1 X1003.1750 Y238.4125 Z-9.0000 F500.0000, G1 X1003.1750 Y238.4125 Z-15.0000 F60.0000, G1 X1003.1750 Y-3.1750 Z-15.0000 F500.0000, G1 X767.9375 Y-3.1750 Z-15.0000 F500.0000, G1 X767.9375 Y-3.1750 Z-9.0000 F120.0000;  tab, G1 X741.5875 Y-3.1750 Z-9.0000 F500.0000, G1 X741.5875 Y-3.1750 Z-15.0000 F60.0000, G1 X516.3500 Y-3.1750 Z-15.0000 F500.0000, G1 X516.3500 Y-3.1750 Z-9.0000 F120.0000;  tab, G1 X490.0000 Y-3.1750 Z-9.0000 F500.0000, G1 X490.0000 Y-3.1750 Z-15.0000 F60.0000, G1 X264.7625 Y-3.1750 Z-15.0000 F500.0000, G1 X264.7625 Y-3.1750 Z-9.0000 F120.0000;  tab, G1 X238.4125 Y-3.1750 Z-9.0000 F500.0000, G1 X238.4125 Y-3.1750 Z-15.0000 F60.0000, G1 X-3.1750 Y-3.1750 Z-15.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-20.0000 F60.0000, G1 X-3.1750 Y238.4125 Z-20.0000 F500.0000, G1 X-3.1750 Y238.4125 Z-9.0000 F120.0000;  tab, G1 X-3.1750 Y264.7625 Z-9.0000 F500.0000, G1 X-3.1750 Y264.7625 Z-20.0000 F60.0000, G1 X-3.1750 Y490.0000 Z-20.0000 F500.0000, G1 X-3.1750 Y490.0000 Z-9.0000 F120.0000;  tab, G1 X-3.1750 Y516.3500 Z-9.0000 F500.0000, G1 X-3.1750 Y516.3500 Z-20.0000 F60.0000, G1 X-3.1750 Y741.5875 Z-20.0000 F500.0000, G1 X-3.1750 Y741.5875 Z-9.0000 F120.0000;  tab, G1 X-3.1750 Y767.9375 Z-9.0000 F500.0000, G1 X-3.1750 Y767.9375 Z-20.0000 F60.0000, G1 X-3.1750 Y1003.1750 Z-20.0000 F500.0000, G1 X238.4125 Y1003.1750 Z-20.0000 F500.0000, G1 X238.4125 Y1003.1750 Z-9.0000 F120.0000;  tab, G1 X264.7625 Y1003.1750 Z-9.0000 F500.0000, G1 X264.7625 Y1003.1750 Z-20.0000 F60.0000, G1 X490.0000 Y1003.1750 Z-20.0000 F500.0000, G1 X490.0000 Y1003.1750 Z-9.0000 F120.0000;  tab, G1 X516.3500 Y1003.1750 Z-9.0000 F500.0000, G1 X516.3500 Y1003.1750 Z-20.0000 F60.0000, G1 X741.5875 Y1003.1750 Z-20.0000 F500.0000, G1 X741.5875 Y1003.1750 Z-9.0000 F120.0000;  tab, G1 X767.9375 Y1003.1750 Z-9.0000 F500.0000, G1 X767.9375 Y1003.1750 Z-20.0000 F60.0000, G1 X1003.1750 Y1003.1750 Z-20.0000 F500.0000, G1 X1003.1750 Y767.9375 Z-20.0000 F500.0000, G1 X1003.1750 Y767.9375 Z-9.0000 F120.0000;  tab, G1 X1003.1750 Y741.5875 Z-9.0000 F500.0000, G1 X1003.1750 Y741.5875 Z-20.0000 F60.0000, G1 X1003.1750 Y516.3500 Z-20.0000 F500.0000, G1 X1003.1750 Y516.3500 Z-9.0000 F120.0000;  tab, G1 X1003.1750 Y490.0000 Z-9.0000 F500.0000, G1 X1003.1750 Y490.0000 Z-20.0000 F60.0000, G1 X1003.1750 Y264.7625 Z-20.0000 F500.0000, G1 X1003.1750 Y264.7625 Z-9.0000 F120.0000;  tab, G1 X1003.1750 Y238.4125 Z-9.0000 F500.0000, G1 X1003.1750 Y238.4125 Z-20.0000 F60.0000, G1 X1003.1750 Y-3.1750 Z-20.0000 F500.0000, G1 X767.9375 Y-3.1750 Z-20.0000 F500.0000, G1 X767.9375 Y-3.1750 Z-9.0000 F120.0000;  tab, G1 X741.5875 Y-3.1750 Z-9.0000 F500.0000, G1 X741.5875 Y-3.1750 Z-20.0000 F60.0000, G1 X516.3500 Y-3.1750 Z-20.0000 F500.0000, G1 X516.3500 Y-3.1750 Z-9.0000 F120.0000;  tab, G1 X490.0000 Y-3.1750 Z-9.0000 F500.0000, G1 X490.0000 Y-3.1750 Z-20.0000 F60.0000, G1 X264.7625 Y-3.1750 Z-20.0000 F500.0000, G1 X264.7625 Y-3.1750 Z-9.0000 F120.0000;  tab, G1 X238.4125 Y-3.1750 Z-9.0000 F500.0000, G1 X238.4125 Y-3.1750 Z-20.0000 F60.0000, G1 X-3.1750 Y-3.1750 Z-20.0000 F500.0000, G1 X-3.1750 Y-3.1750 Z-21.5000 F60.0000, G1 X-3.1750 Y238.4125 Z-21.5000 F500.0000, G1 X-3.1750 Y238.4125 Z-9.0000 F120.0000;  tab, G1 X-3.1750 Y264.7625 Z-9.0000 F500.0000, G1 X-3.1750 Y264.7625 Z-21.5000 F60.0000, G1 X-3.1750 Y490.0000 Z-21.5000 F500.0000, G1 X-3.1750 Y490.0000 Z-9.0000 F120.0000;  tab, G1 X-3.1750 Y516.3500 Z-9.0000 F500.0000, G1 X-3.1750 Y516.3500 Z-21.5000 F60.0000, G1 X-3.1750 Y741.5875 Z-21.5000 F500.0000, G1 X-3.1750 Y741.5875 Z-9.0000 F120.0000;  tab, G1 X-3.1750 Y767.9375 Z-9.0000 F500.0000, G1 X-3.1750 Y767.9375 Z-21.5000 F60.0000, G1 X-3.1750 Y1003.1750 Z-21.5000 F500.0000, G1 X238.4125 Y1003.1750 Z-21.5000 F500.0000, G1 X238.4125 Y1003.1750 Z-9.0000 F120.0000;  tab, G1 X264.7625 Y1003.1750 Z-9.0000 F500.0000, G1 X264.7625 Y1003.1750 Z-21.5000 F60.0000, G1 X490.0000 Y1003.1750 Z-21.5000 F500.0000, G1 X490.0000 Y1003.1750 Z-9.0000 F120.0000;  tab, G1 X516.3500 Y1003.1750 Z-9.0000 F500.0000, G1 X516.3500 Y1003.1750 Z-21.5000 F60.0000, G1 X741.5875 Y1003.1750 Z-21.5000 F500.0000, G1 X741.5875 Y1003.1750 Z-9.0000 F120.0000;  tab, G1 X767.9375 Y1003.1750 Z-9.0000 F500.0000, G1 X767.9375 Y1003.1750 Z-21.5000 F60.0000, G1 X1003.1750 Y1003.1750 Z-21.5000 F500.0000, G1 X1003.1750 Y767.9375 Z-21.5000 F500.0000, G1 X1003.1750 Y767.9375 Z-9.0000 F120.0000;  tab, G1 X1003.1750 Y741.5875 Z-9.0000 F500.0000, G1 X1003.1750 Y741.5875 Z-21.5000 F60.0000, G1 X1003.1750 Y516.3500 Z-21.5000 F500.0000, G1 X1003.1750 Y516.3500 Z-9.0000 F120.0000;  tab, G1 X1003.1750 Y490.0000 Z-9.0000 F500.0000, G1 X1003.1750 Y490.0000 Z-21.5000 F60.0000, G1 X1003.1750 Y264.7625 Z-21.5000 F500.0000, G1 X1003.1750 Y264.7625 Z-9.0000 F120.0000;  tab, G1 X1003.1750 Y238.4125 Z-9.0000 F500.0000, G1 X1003.1750 Y238.4125 Z-21.5000 F60.0000, G1 X1003.1750 Y-3.1750 Z-21.5000 F500.0000, G1 X767.9375 Y-3.1750 Z-21.5000 F500.0000, G1 X767.9375 Y-3.1750 Z-9.0000 F120.0000;  tab, G1 X741.5875 Y-3.1750 Z-9.0000 F500.0000, G1 X741.5875 Y-3.1750 Z-21.5000 F60.0000, G1 X516.3500 Y-3.1750 Z-21.5000 F500.0000, G1 X516.3500 Y-3.1750 Z-9.0000 F120.0000;  tab, G1 X490.0000 Y-3.1750 Z-9.0000 F500.0000, G1 X490.0000 Y-3.1750 Z-21.5000 F60.0000, G1 X264.7625 Y-3.1750 Z-21.5000 F500.0000, G1 X264.7625 Y-3.1750 Z-9.0000 F120.0000;  tab, G1 X238.4125 Y-3.1750 Z-9.0000 F500.0000, G1 X238.4125 Y-3.1750 Z-21.5000 F60.0000, G1 X-3.1750 Y-3.1750 Z-21.5000 F500.0000, G0 Z1.0000;  Rectangle cut done]'));
      var numTabs =
          w.gCode.where((element) => element.contains('tab')).toList().length;
      expect(numTabs, 48);
      w = WorkGenerator();
      rect = Rect(Point(0, 0), Point(100, 1000)); //  no tabs on horizontal
      w.addRectCut(rect, makeTabs: true);
      numTabs =
          w.gCode.where((element) => element.contains('tab')).toList().length;
      expect(numTabs, 24);
      w = WorkGenerator();
      rect = Rect(Point(0, 0), Point(1000, 100)); //  no tabs on vertical
      w.addRectCut(rect, makeTabs: true);
      numTabs =
          w.gCode.where((element) => element.contains('tab')).toList().length;
      expect(numTabs, 24);
      w = WorkGenerator();
      rect = Rect(Point(0, 0), Point(110, 100)); //  small, triggers min # tabs
      w.addRectCut(rect, makeTabs: true);
      numTabs =
          w.gCode.where((element) => element.contains('tab')).toList().length;
      expect(numTabs, 8);
      w = WorkGenerator();
      rect = Rect(Point(0, 0), Point(100, 100));
      w.addRectCut(rect,
          cutDepth: -5, makeTabs: true); // shallow, no tabs
      numTabs =
          w.gCode.where((element) => element.contains('tab')).toList().length;
      expect(numTabs, 0);
      w = WorkGenerator();
      rect = Rect(Point(0, 0), Point(1000, 1000));
      w.addRectCut(rect,
          cutDepth: -10, makeTabs: true); // shallow, only one tab
      numTabs =
          w.gCode.where((element) => element.contains('tab')).toList().length;
      expect(numTabs, 12);
    });

    test('Inner addRectCut', () {
      var w = WorkGenerator();
      var rect = Rect(Point(0, 0), Point(100, 100));
      w.addRectCut(rect, insideCut: true);
      expect(
          w.gCode.toString(),
          equals(
              '[, (Rectangle cut), G0 Z5.0000, G0 X3.1750 Y3.1750, G0 Z1.0000, G1 X3.1750 Y3.1750 Z-5.0000 F60.0000, G1 X3.1750 Y96.8250 Z-5.0000 F500.0000, G1 X96.8250 Y96.8250 Z-5.0000 F500.0000, G1 X96.8250 Y3.1750 Z-5.0000 F500.0000, G1 X3.1750 Y3.1750 Z-5.0000 F500.0000, G1 X3.1750 Y3.1750 Z-10.0000 F60.0000, G1 X3.1750 Y96.8250 Z-10.0000 F500.0000, G1 X96.8250 Y96.8250 Z-10.0000 F500.0000, G1 X96.8250 Y3.1750 Z-10.0000 F500.0000, G1 X3.1750 Y3.1750 Z-10.0000 F500.0000, G1 X3.1750 Y3.1750 Z-15.0000 F60.0000, G1 X3.1750 Y96.8250 Z-15.0000 F500.0000, G1 X96.8250 Y96.8250 Z-15.0000 F500.0000, G1 X96.8250 Y3.1750 Z-15.0000 F500.0000, G1 X3.1750 Y3.1750 Z-15.0000 F500.0000, G1 X3.1750 Y3.1750 Z-20.0000 F60.0000, G1 X3.1750 Y96.8250 Z-20.0000 F500.0000, G1 X96.8250 Y96.8250 Z-20.0000 F500.0000, G1 X96.8250 Y3.1750 Z-20.0000 F500.0000, G1 X3.1750 Y3.1750 Z-20.0000 F500.0000, G1 X3.1750 Y3.1750 Z-21.5000 F60.0000, G1 X3.1750 Y96.8250 Z-21.5000 F500.0000, G1 X96.8250 Y96.8250 Z-21.5000 F500.0000, G1 X96.8250 Y3.1750 Z-21.5000 F500.0000, G1 X3.1750 Y3.1750 Z-21.5000 F500.0000, G0 Z1.0000;  Rectangle cut done]'));
    });
  });

  group('addRectMill', () {
    test('addRectMill - landscape', () {
      var w = WorkGenerator();
      var rect = Rect(Point(0, 0), Point(200, 100));
      w.addRectMill(rect, millDepth: -4);
      var input = w.gCode[3];
      expect(GParser().parseValueOf('X', input), equals(Machine().toolRadius));
      expect(GParser().parseValueOf('Y', input), equals(Machine().toolRadius));
      input = w.gCode[w.gCode.length - 4];
      expect(GParser().parseValueOf('X', input),
          equals(200 - Machine().toolRadius));
      expect(GParser().parseValueOf('Y', input),
          equals(100 - Machine().toolRadius));
      input = w.gCode[w.gCode.length - 2];
      expect(GParser().parseValueOf('X', input), equals(Machine().toolRadius));
      expect(GParser().parseValueOf('Y', input),
          equals(100 - Machine().toolRadius));
    });

    test('addRectMill - portrait', () {
      var w = WorkGenerator();
      var rect = Rect(Point(0, 0), Point(100, 200));
      w.addRectMill(rect, millDepth: -4);
      var input = w.gCode[3];
      expect(GParser().parseValueOf('X', input), equals(Machine().toolRadius));
      expect(GParser().parseValueOf('Y', input), equals(Machine().toolRadius));
      input = w.gCode[w.gCode.length - 4];
      expect(GParser().parseValueOf('X', input),
          equals(100 - Machine().toolRadius));
      expect(GParser().parseValueOf('Y', input),
          equals(200 - Machine().toolRadius));
      input = w.gCode[w.gCode.length - 2];
      expect(GParser().parseValueOf('X', input),
          equals(100 - Machine().toolRadius));
      expect(GParser().parseValueOf('Y', input), equals(Machine().toolRadius));
    });

    test('addRectMill - deep', () {
      var w = WorkGenerator();
      var rect = Rect(Point(0, 0), Point(100, 200));
      w.addRectMill(rect, millDepth: -11);
      // expect 3 'return to bottom left' moves, one for each cut
      expect(w.gCode.where((element) => element == 'G0 X3.1750 Y3.1750').length,
          equals(3));
      var sortedZs = sortedValuesFor('Z', w);
      expect(sortedZs, equals([-11.0, -10.0, -5.0, 1.0, 5.0]));
    });

    test('addRectMill - through', () {
      var w = WorkGenerator();
      var rect = Rect(Point(0, 0), Point(100, 200));
      w.addRectMill(rect); // no millDepth means cut through
      var sortedZs = sortedValuesFor('Z', w);
      expect(sortedZs, equals([-21.5, -20.0, -15.0, -10.0, -5.0, 1.0, 5.0]));
    });
  });

  group('addHandleHoles', () {
    test('Single hole', () {
      var w = WorkGenerator();
      var p = Point(100, 200);
      w.addHandleHoles(p);
      var sortedXs = sortedValuesFor('X', w);
      expect(sortedXs.first, equals(100));
      var sortedYs = sortedValuesFor('Y', w);
      expect(sortedYs.first, equals(200));
      var sortedZs = sortedValuesFor('Z', w);
      expect(sortedZs.first, equals(Machine().cutThroughDepth));
    });

    test('Landscape holes', () {
      var w = WorkGenerator();
      var p = Point(100, 200);
      w.addHandleHoles(p, landscape: true, size: 10);
      var sortedXs = sortedValuesFor('X', w);
      expect(sortedXs, equals([95, 105]));
      var sortedYs = sortedValuesFor('Y', w);
      expect(sortedYs, equals([200]));
      var sortedZs = sortedValuesFor('Z', w);
      expect(sortedZs.first, equals(Machine().cutThroughDepth));
    });

    test('Portrait holes', () {
      var w = WorkGenerator();
      var p = Point(100, 200);
      w.addHandleHoles(p, landscape: false, size: 10);
      var sortedXs = sortedValuesFor('X', w);
      expect(sortedXs, equals([100]));
      var sortedYs = sortedValuesFor('Y', w);
      expect(sortedYs, equals([195, 205]));
      var sortedZs = sortedValuesFor('Z', w);
      expect(sortedZs.first, equals(Machine().cutThroughDepth));
    });

    test('Partial depth', () {
      var w = WorkGenerator();
      var p = Point(100, 200);
      w.addHandleHoles(p, drillDepth: -5);
      var sortedXs = sortedValuesFor('X', w);
      expect(sortedXs.first, equals(100));
      var sortedYs = sortedValuesFor('Y', w);
      expect(sortedYs.first, equals(200));
      var sortedZs = sortedValuesFor('Z', w);
      expect(sortedZs.first, equals(-5));
    });

    test('Errors', () {
      var w = WorkGenerator();
      var p = Point(100, 200);
      expect(() => w.addHandleHoles(p, drillDepth: 5), throwsStateError);
      expect(() => w.addHandleHoles(p, landscape: true), throwsStateError);
    });
  });
}

/// Returns sorted values of all occurrences of [arg] in the work [w]
List<double> sortedValuesFor(String arg, WorkGenerator w) {
  var values = <double>{};
  w.gCode.forEach((line) {
    if (line.contains(arg)) {
      values.add(GParser().parseValueOf(arg, line));
    }
  });
  var sorted = values.toList()..sort();
  return sorted;
}
