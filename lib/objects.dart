import 'dart:math';

/// Basic Dart objects
/// 

const precision = 0.01;

class Point {
  final double x, y;

  Point(this.x, this.y);

  Point.zero() : x = 0, y = 0;

  bool toRightOf(Point p) => x > p.x;
  bool toLeftOf(Point p) => x < p.x;
  bool below(Point p) => y < p.y;
  bool above(Point p) => y > p.y;


  bool isSameAs(Point other) =>
      (x - other.x).abs() < precision && (y - other.y).abs() < precision;

  bool isSameHorizontalAs(Point other) => (y - other.y).abs() < precision;

  bool isSameVerticalAs(Point other) => (x - other.x).abs() < precision;
  
  double distanceTo(Point p) => sqrt(pow(x - p.x, 2) + pow(y - p.y, 2));

  @override
  String toString() {
    return '($x, $y)';
  }
}

class Point3D extends Point {
  final double z;

  Point3D(double x, double y, this.z) : super(x, y);

  Point3D.zero() : z = 0, super(0, 0);

  Point get point => Point(x, y);  // without z

  @override
  bool isSameAs(Point other) => throw UnimplementedError('isSameAs not available for 3D');

  /// Returns distance to another Point3D
  double distanceTo3D(Point3D p) {
    var dx = (p.x - x).abs();
    var dy = (p.y - y).abs();
    var dz = (p.z - z).abs();
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  Point3D operator +(Point3D p) => Point3D(x + p.x, y + p.y, z + p.z);
  Point3D operator -(Point3D p) => Point3D(x - p.x, y - p.y, z - p.z);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point3D && runtimeType == other.runtimeType && x == other.x && y == other.y && z == other.z;

  @override
  int get hashCode => x.hashCode + y.hashCode + y.hashCode;
}

class Rect {
  final Point bl, tr;

  /// Rectangle defined by bottom-left and top-right points
  Rect(this.bl, this.tr);

  Rect.zero() : bl = Point.zero(), tr = Point.zero();

  Point get tl => Point(bl.x, tr.y);
  Point get br => Point(tr.x, bl.y);
  double get width => tr.x - bl.x;
  double get height => tr.y - bl.y;

  bool get isLandscape => width > height;

  bool hasPoint(Point p) =>
      p.isSameAs(bl) || p.isSameAs(tl) || p.isSameAs(tr) || p.isSameAs(br);
}

class Line {
  final Point start, end;

  Line(this.start, this.end);

  /// Returns a list of Points on this line, traveling from [start] to [end]
  ///
  /// Provide either [spacing] or [steps] to divide the line up in steps of
  /// size spacing
  List<Point> points({double? spacing, int? steps}) {
    if (steps != null) {
      spacing ??= length / steps;
    }
    if (spacing == null) {
      throw StateError('Either spacing or steps is required');
    }
    var result = <Point>[];
    var travel = 0.0;
    while (travel < length) {
      final fraction = travel / length;
      result.add(Point(start.x + fraction * (end.x - start.x), start.y + fraction * (end.y - start.y)));
      travel += spacing;
    }
    result.add(end);
    return result;
  }

  double get length => start.distanceTo(end);

  double get angle => atan2(end.y - start.y, end.x - start.x);
}
