import 'dart:math';

/// Basic Dart objects

/// Equals test for double values, to avoid rounding issues with ==
bool almostEqual(double a, double b) => (a - b).abs() < 0.01;

class Point  {
  final double x, y;

  Point(this.x, this.y);

  Point.zero()
      : x = 0,
        y = 0;

  // Point.add(Point a, Point b) : x = a.x + b.x, y = a.y + b.y;
  Point.subtract(Point a, Point b) : x = a.x - b.x, y = a.y - b.y;

  bool toRightOf(Point p) => x > p.x;

  bool toLeftOf(Point p) => x < p.x;

  bool below(Point p) => y < p.y;

  bool above(Point p) => y > p.y;

  // bool isSameAs(Point other) =>
  //     (x - other.x).abs() < precision && (y - other.y).abs() < precision;

  bool isSameHorizontalAs(Point other) => almostEqual(y, other.y);

  bool isSameVerticalAs(Point other) => almostEqual(x, other.x);

  double distanceTo(covariant Point p) => sqrt(pow(x - p.x, 2) + pow(y - p.y, 2));

  Point operator +(Point p) => Point(x + p.x, y + p.y);

  @override
  String toString() {
    return '(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          almostEqual(x, other.x) &&
          almostEqual(y, other.y);

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class Point3D extends Point {
  final double z;

  Point3D(double x, double y, this.z) : super(x, y);

  Point3D.zero()
      : z = 0,
        super(0, 0);

  // Point3D.add(Point3D a, Point3D b) : z = a.z + b.z, super(a.x + b.x, a.y + b.y);
  Point3D.subtract(Point3D a, Point3D b) : z = a.z - b.z, super(a.x - b.x, a.y - b.y);

  Point get point => Point(x, y); // without z

  /// Returns distance to another Point3D
  @override
  double distanceTo(covariant Point3D p) {
    var dx = (p.x - x).abs();
    var dy = (p.y - y).abs();
    var dz = (p.z - z).abs();
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  @override
  Point3D operator +(covariant Point3D p) => Point3D(x + p.x, y + p.y, z + p.z);

  @override
  String toString() {
    return '($x, $y, $z)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point3D &&
          runtimeType == other.runtimeType &&
          almostEqual(x, other.x) &&
          almostEqual(y, other.y) &&
          almostEqual(z, other.z);

  @override
  int get hashCode => x.hashCode + y.hashCode + y.hashCode;
}

class Rect {
  final Point bl, tr;

  /// Rectangle defined by bottom-left and top-right points
  Rect(this.bl, this.tr);

  Rect.zero()
      : bl = Point.zero(),
        tr = Point.zero();

  Point get tl => Point(bl.x, tr.y);

  Point get br => Point(tr.x, bl.y);

  double get left => bl.x;

  double get right => tr.x;

  double get top => tr.y;

  double get bottom => bl.y;

  double get width => tr.x - bl.x;

  double get height => tr.y - bl.y;

  bool get isLandscape => width > height;

  bool hasCorner(Point p) => p == bl || p == tl || p == tr || p == br;

  bool overlaps(Rect other) =>
      left < other.right &&
      right > other.left &&
      top > other.bottom &&
      bottom < other.top;

  Point get center => Point((bl.x + tr.x) / 2, (bl.y + tl.y) / 2);

  // Adjustments (return a new Rect as it is immutable)

  /// Return Rect of different size, with a new left
  Rect withNewLeft(double l) => Rect(Point(l, bl.y), tr);

  /// Return Rect of different size, with a new right
  Rect withNewRight(double r) => Rect(bl, Point(r, tr.y));

  /// Return Rect of different size, with a new top
  Rect withNewTop(double t) => Rect(bl, Point(tr.x, t));

  /// Return Rect of different size, with a new bottom
  Rect withNewBottom(double b) => Rect(Point(bl.x, b), tr);

  /// Returns Rect grown by s, with the same center
  Rect grow(double s) => Rect(
      Point(bl.x - s / 2, bl.y - s / 2), Point(tr.x + s / 2, tr.y + s / 2));

  /// Returns Rect of same size, centered on another Rect
  Rect centerOn(Rect other) =>
      translated(Point(other.center.x - center.x, other.center.y - center.y));

  /// Returns Rect of same size, with the left aligned another Rect
  Rect alignLeftWith(Rect other) => translated(Point(other.bl.x - bl.x, 0));

  /// Returns Rect of same size, with the right aligned another Rect
  Rect alignRightWith(Rect other) => translated(Point(other.tr.x - tr.x, 0));

  /// Returns this rect translated by the x and y of [translate]
  Rect translated(Point translate) => Rect(
      Point(bl.x + translate.x, bl.y + translate.y),
      Point(tr.x + translate.x, tr.y + translate.y));

  @override
  String toString() {
    return 'Rect{bl: $bl, tr: $tr}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rect &&
          runtimeType == other.runtimeType &&
          bl == other.bl &&
          tr == other.tr;

  @override
  int get hashCode => bl.hashCode ^ tr.hashCode;
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
      result.add(Point(start.x + fraction * (end.x - start.x),
          start.y + fraction * (end.y - start.y)));
      travel += spacing;
    }
    result.add(end);
    return result;
  }

  double get length => start.distanceTo(end);

  double get angle => atan2(end.y - start.y, end.x - start.x);
}
