/// Basic Dart objects

class Point {
  final double x, y;

  Point(this.x, this.y);

  bool isSameAs(Point other) =>
      (x - other.x).abs() < 0.01 && (y - other.y).abs() < 0.01;

  bool isSameHorizontalAs(Point other) => (y - other.y).abs() < 0.01;

  bool isSameVerticalAs(Point other) => (x - other.x).abs() < 0.01;
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
