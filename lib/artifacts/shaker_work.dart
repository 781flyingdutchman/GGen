import '../conversion.dart';
import '../objects.dart';
import '../work_generator.dart';

/// Configuration parameters for the Panel
class ShakerPanel {
  static final ShakerPanel _singleton = ShakerPanel._internal();

  // configuration variables for the shaker panel
  double width = 300;
  double height = 150;
  double styleWidth = 2.inch;
  double pocketDepth = -4;
  Point? handleOffset; // if null, no handle
  bool? handleOrientationLandscape; // if null, single hole
  double handleWidth = 0;
  double? handleHoleDepth; // if null, cut through

  factory ShakerPanel() {
    return _singleton;
  }

  void resetToDefaults() {
    width = 300;
    height = 150;
    styleWidth = 2.inch;
    pocketDepth = -4;
    handleOffset = null; // if null, no handle
    handleOrientationLandscape = null; // if null, single hole
    handleWidth = 0;
    handleHoleDepth = null; // if null, cut through
  }

  ShakerPanel._internal();

  bool get isLandscape => width > height;

  @override
  String toString() {
    return 'ShakerPanel with width: $width, height: $height, '
        'styleWidth: $styleWidth, pocketDepth: $pocketDepth, '
        'handleOffset: $handleOffset, handleOrientationLandscape: '
        '$handleOrientationLandscape, handleWidth: $handleWidth';
  }
}

class ShakerWork extends WorkGenerator {
  @override
  void workpieceCode() {
    // assume bottom left of panel is (0, 0)
    // calculate the rectangles
    var machine = Machine();
    var panel = ShakerPanel();
    var panelRect = Rect(Point(0, 0), Point(panel.width, panel.height));
    var offSet = panel.styleWidth;
    var innerRect = Rect(Point(offSet, offSet),
        Point(panel.width - offSet, panel.height - offSet));
    offSet += machine.toolRadius;
    var millRect = Rect(Point(offSet, offSet),
        Point(panel.width - offSet, panel.height - offSet));
    // add operations
    final handleOffset = panel.handleOffset;
    if (handleOffset != null) {
      var handleMidPoint = Point(panelRect.center.x + handleOffset.x,
          panelRect.center.y + handleOffset.y);
      addHandleHoles(handleMidPoint, drillDepth: panel.handleHoleDepth,
          landscape: panel.handleOrientationLandscape, size: panel.handleWidth);
    }
    addRectCut(innerRect,
        insideCut: true,
        cutDepth: panel.pocketDepth,
        description: 'Inside edge trim');
    addRectMill(millRect, millDepth: panel.pocketDepth);
    addRectCut(panelRect, makeTabs: true, description: 'Panel outline');
  }

  @override
  void header() {
    super.header();
    gCode.addAll([
      space(),
      comment(Machine().toString()),
      space(),
      comment(ShakerPanel().toString()),
      space()
    ]);
  }

  @override
  void validateConfig() {
    super.validateConfig();
    var panel = ShakerPanel();
    if (panel.width == 0 || panel.height == 0) {
      throw StateError('Panel width and height must be set');
    }
  }
}
