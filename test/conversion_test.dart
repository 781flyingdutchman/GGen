import 'package:test/test.dart';
import 'package:shaker/conversion.dart';

void main() {

  test('DistanceConversions', () {
    final d = 10;
    expect(d.cm, equals(100));
    expect(d.m, equals(10000));
    expect(d.inch, equals(254));
    expect(d.ft, equals(254*12));
    // feed rates
    expect(d.fpm, equals(d.ft));
    expect(d.ipm, equals(d.inch));
    expect(d.cpm, equals(d.cm));
    expect(d.mmps, equals(d * 60));
  });

  test('valueOf', () {
    var input = 'G0 X1.23';
    expect(GParser().parseValueOf('X', input), equals(1.23));
    input = 'G0 X 1.23';
    expect(GParser().parseValueOf('X', input), equals(1.23));
    input = 'G0   X  1.23  Y1';
    expect(GParser().parseValueOf('X', input), equals(1.23));
    input = 'G0';
    expect(() => GParser().parseValueOf('X', input), throwsArgumentError);
    // integers
    expect(GParser().parseIntValueOf('G', input), equals(0));
    expect(() => GParser().parseIntValueOf('X', input), throwsArgumentError);
  });
}
