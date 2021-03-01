import 'dart:math';

/// Basic Dart objects
/// 

const precision = 0.01;

class Point {
  final double x, y;

  Point(this.x, this.y);

  bool isSameAs(Point other) =>
      (x - other.x).abs() < precision && (y - other.y).abs() < precision;

  bool isSameHorizontalAs(Point other) => (y - other.y).abs() < precision;

  bool isSameVerticalAs(Point other) => (x - other.x).abs() < precision;
  
  double distanceTo(Point p) => sqrt(pow(x - p.x, 2) + pow(y - p.y, 2));
  
}

class Rect {
  final Point bl, tr;

  /// Rectangle defined by bottom-left and top-right points
  Rect(this.bl, this.tr);

  double get width => tr.x - bl.x;

  double get height => tr.y - bl.y;

  Point get tl => Point(bl.x, tr.y);

  Point get br => Point(tr.x, bl.y);

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
