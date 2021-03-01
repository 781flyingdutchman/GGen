import 'dart:math';

import 'package:shaker/config.dart';
import 'package:shaker/objects.dart';

/// Base class for the actual work
///
/// Extends this class and override [create]
class Work {
  final gCode = <String>[];

  /// Creates the work
  void create() {
    validateConfig();
    updateConfig();
  }

  String baseMove(String g, {double? x, double? y, double? z, double? f}) {
    if (x == null && y == null && z == null) {
      throw StateError('In move, one of x|y|z must be given');
    }
    var line = '$g ';
    if (x != null) line = lineAddArgAndValue(line, 'X', x);
    if (y != null) line = lineAddArgAndValue(line, 'Y', y);
    if (z != null) line = lineAddArgAndValue(line, 'Z', z);
    if (f != null) line = lineAddArgAndValue(line, 'F', f);
    return line;
  }

  /// Move rapidly, using G0
  String rapidMove({double? x, double? y, double? z}) {
    return baseMove('G0', x: x, y: y, z: z);
  }

  String rapidMoveToPoint(Point p, {double? z}) {
    return rapidMove(x: p.x, y: p.y, z: z);
  }

  /// Move linearly, using G1
  String linearMove({double? x, double? y, double? z, double? f}) {
    return baseMove('G1', x: x, y: y, z: z, f: f);
  }

  String linearMoveToPoint(Point p, double z, double f) {
    return linearMove(x: p.x, y: p.y, z: z, f: f);
  }

  String moveToSafeHeight() => 'G0 Z${Machine().safeHeight}';

  String moveToClearanceHeight() => 'G0 Z${Machine().clearanceHeight}';

  String lineAddArgAndValue(String line, String argument, double value) {
    var valueAsString = value.toStringAsFixed(4);
    return '$line $argument$valueAsString';
  }

  String lineWithComment(String line, String comment) => '$line;  $comment';

  String comment(String comment) => '($comment)';

  // calculations

  /// Returns a map with tab points
  ///
  /// A cut direction with tab(s) is listed as 'H', or 'V' for horizontal or
  /// vertical, and the values are the mid points of each tab
  Map<String, List<double>> tabPoints(Rect rect) {
    var result = <String, List<double>>{};
    var panel = Panel();
    // horizontal
    var numTabs = (rect.width / panel.tabSpacing).floor();
    if (numTabs > 0) {
      var dist = rect.width / (numTabs + 1);
      result['H'] = List.generate(numTabs, (index) => (index + 1) * dist);
    }
    // vertical
    numTabs = (rect.height / panel.tabSpacing).floor();
    if (numTabs > 0) {
      var dist = rect.height / (numTabs + 1);
      result['V'] = List.generate(numTabs, (index) => (index + 1) * dist);
    }
    return result;
  }

  /// Validates the configuration
  ///
  /// If an error is found, throws a StateError, otherwise returns
  void validateConfig() {
    var panel = Panel();
    if (panel.width == 0 || panel.height == 0) {
      throw StateError('Panel width and height must be set');
    }
    var machine = Machine();
    if (machine.safeHeight < machine.clearanceHeight) {
      throw StateError('SafeHeight must be > ClearanceHeight');
    }
    if (machine.safeHeight <= 1 || machine.clearanceHeight <= 1) {
      throw StateError('SafeHeight and ClearanceHeight must be > 1 mm');
    }
  }

  /// Updates the configuration based on the configuration
  ///
  void updateConfig() {
    // nothing yet
  }
}

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

  void addRectCut(Rect outline,
      {double? cutDepth,
        insideCut = false,
        bool makeTabs = false,
        String? description}) {
    var machine = Machine();
    var panel = Panel();
    var depth = cutDepth ?? panel.cutThroughDepth;
    if (depth > 0) throw StateError('Depth must be < 0');
    gCode.add(comment(description ?? 'Rectangle cut'));
    var offSet = insideCut ? -machine.toolRadius : machine.toolRadius;
    // cutRect is the outline adjusted for tool radius, using offSet
    var cutRect = Rect(Point(outline.bl.x - offSet, outline.bl.y - offSet),
        Point(outline.tr.x + offSet, outline.tr.y + offSet));
    // determine tabs
    var tabs = makeTabs ? tabPoints(cutRect) : {};
    // create move points - assumes you start at cutRect.bl
    var movePoints = {
      'normal': [cutRect.tl, cutRect.tr, cutRect.br, cutRect.bl]
    };
    if (tabs.isNotEmpty) {
      // determine the movePoints for tabs
      var points = <Point>[];
      // up move
      var verTabs = tabs['V'];
      if (verTabs == null) {
        points.add(cutRect.tl);
      } else {
        verTabs.forEach((yValue) {
          points.add(Point(cutRect.tl.x, yValue));
        });
        points.add(cutRect.tl);
      }
      // right move
      var horTabs = tabs['H'];
      if (horTabs == null) {
        points.add(cutRect.tr);
      } else {
        horTabs.forEach((xValue) {
          points.add(Point(xValue, cutRect.tr.y));
        });
        points.add(cutRect.tr);
      }
      // down move
      if (verTabs == null) {
        points.add(cutRect.br);
      } else {
        verTabs.reversed.forEach((yValue) {
          points.add(Point(cutRect.br.x, yValue));
        });
        points.add(cutRect.br);
      }
      // left move
      if (horTabs == null) {
        points.add(cutRect.bl);
      } else {
        horTabs.forEach((xValue) {
          points.add(Point(xValue, cutRect.bl.y));
        });
        points.add(cutRect.bl);
      }
      movePoints['tabs'] = points;
    }
    gCode.addAll([
      moveToSafeHeight(),
      rapidMoveToPoint(cutRect.bl),
      moveToClearanceHeight()
    ]);
    var currentZ = machine.clearanceHeight;
    while (currentZ > depth) {
      var targetZ = max(depth,
          min(currentZ - machine.maxCutStepDepth, -machine.maxCutStepDepth));
      gCode.add(linearMoveToPoint(cutRect.bl, targetZ, machine.verticalFeedDown));
      var points = (tabs.isNotEmpty && targetZ < panel.tabTopDepth)
          ? movePoints['tabs']!
          : movePoints['normal']!;
      var currentPoint = cutRect.bl;
      points.forEach((p) {
        if (cutRect.hasPoint(p)) {
          // corner of rectangle, so move there
          gCode.add(
              linearMoveToPoint(p, targetZ, machine.horizontalFeedCutting));
        }
        else {
          // tab point
          Point startOfTab, endOfTab;
          if (p.isSameVerticalAs(currentPoint)) {
            // vertically oriented tab
            var tabIsAbove = p.y > currentPoint.y;
            startOfTab = Point(currentPoint.x,
                tabIsAbove ?
                p.y - panel.tabWidth / 2
                    : p.y + panel.tabWidth / 2);
            endOfTab = Point(currentPoint.x,
                tabIsAbove ?
                p.y + panel.tabWidth / 2
                    : p.y - panel.tabWidth / 2);
          }
          else {
            // horizontally oriented tab
            var tabIsToRight = p.x > currentPoint.x;
            startOfTab = Point(
                tabIsToRight ?
                p.x - panel.tabWidth / 2
                    : p.x + panel.tabWidth / 2, p.y);
            endOfTab = Point(
                tabIsToRight ?
                p.x + panel.tabWidth / 2
                    : p.x - panel.tabWidth / 2, p.y);
          }
          // create the tab
          gCode.addAll(
              [
                linearMoveToPoint(
                    startOfTab, targetZ, machine.horizontalFeedCutting),
                lineWithComment(linearMoveToPoint(
                    startOfTab, panel.tabTopDepth, machine.verticalFeedUp), 'tab'),
                linearMoveToPoint(
                    endOfTab, panel.tabTopDepth, machine.horizontalFeedCutting),
                linearMoveToPoint(endOfTab, targetZ, machine.verticalFeedDown)
              ]);
        }
      });
      currentZ = targetZ;
    }
    gCode.add(lineWithComment(moveToClearanceHeight(), 'Rectangle cut done'));
  }
}
