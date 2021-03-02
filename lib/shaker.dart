import 'config.dart';
import 'objects.dart';
import 'work.dart';

class ShakerWork extends Work {
  @override
  void create() {
    super.create();
    // assume bottom left of panel is (0, 0)
    // calculate the rectangles
    var machine = Machine();
    var panel = Panel();
    var panelRect = Rect(Point(0, 0), Point(panel.width, panel.height));
    var offSet = panel.styleWidth;
    var innerRect = Rect(Point(offSet, offSet),
        Point(panel.width - offSet, panel.height - offSet));
    offSet += machine.toolRadius;
    var millRect = Rect(Point(offSet, offSet),
        Point(panel.width - offSet, panel.height - offSet));
  }

  @override
  void validateConfig() {
    super.validateConfig();
    var panel = Panel();
    if (panel.width == 0 || panel.height == 0) {
      throw StateError('Panel width and height must be set');
    }
  }
}

