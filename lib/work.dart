import 'dart:math';

import 'package:shaker/config.dart';
import 'package:shaker/objects.dart';

/// Base class for the actual work
///
/// Extends this class and override [create]
class Work {
  final gCode = <String>[];
  Point toolPoint = Point(0, 0);
  double toolZ = 0;

  /// Creates the work
  void create() {
    validateConfig();
    updateConfig();
  }

  /// Utility function to move the tool
  ///
  /// Note the actual tool position is maintained in [toolPoint] and
  /// [toolZ]
  String baseMove(String g, {double? x, double? y, double? z, double? f}) {
    if (x == null && y == null && z == null) {
      throw StateError('In move, one of x|y|z must be given');
    }
    var line = '$g';
    if (x != null) {
      line = lineAddArgAndValue(line, 'X', x);
      toolPoint = Point(x, toolPoint.y);
    }
    ;
    if (y != null) {
      line = lineAddArgAndValue(line, 'Y', y);
      toolPoint = Point(toolPoint.x, y);
    }
    ;
    if (z != null) {
      line = lineAddArgAndValue(line, 'Z', z);
      toolZ = z;
    }
    ;
    if (f != null) line = lineAddArgAndValue(line, 'F', f);

    return line;
  }

  /// Move rapidly, using G0
  String rapidMove({double? x, double? y, double? z}) {
    return baseMove('G0', x: x, y: y, z: z);
  }

  /// Move rapidly, using G0
  String rapidMoveToPoint(Point p, {double? z}) {
    return rapidMove(x: p.x, y: p.y, z: z);
  }

  /// Move linearly, using G1
  String linearMove({double? x, double? y, double? z, double? f}) {
    return baseMove('G1', x: x, y: y, z: z, f: f);
  }

  /// Move linearly, using G1
  String linearMoveToPoint(Point p, double z, double f) {
    return linearMove(x: p.x, y: p.y, z: z, f: f);
  }

  String moveToSafeHeight() => rapidMove(z: Machine().safeHeight);

  String moveToClearanceHeight() => rapidMove(z: Machine().clearanceHeight);

  // more complex operations

  /// Add rectangular cut to gCode list (multiple lines)
  ///
  /// [cutDepth] if omitted, will cut through material
  /// [insideCut] will cut inside the rectangle
  /// [maketabs] will leave tabs to hold the work piece, using tab parameters
  ///            in [Machine]
  void addRectCut(Rect outline,
      {double? cutDepth,
      insideCut = false,
      bool makeTabs = false,
      String? description}) {
    var machine = Machine();
    var depth = cutDepth ?? machine.cutThroughDepth;
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
        horTabs.reversed.forEach((xValue) {
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
    while (toolZ > depth) {
      var targetZ = max(depth,
          min(toolZ - machine.maxCutStepDepth, -machine.maxCutStepDepth));
      gCode.add(
          linearMoveToPoint(cutRect.bl, targetZ, machine.verticalFeedDown));
      var points = (tabs.isNotEmpty && targetZ < machine.tabTopDepth)
          ? movePoints['tabs']!
          : movePoints['normal']!;
      points.forEach((p) {
        if (cutRect.hasPoint(p)) {
          // corner of rectangle, so move there
          gCode.add(
              linearMoveToPoint(p, targetZ, machine.horizontalFeedCutting));
        } else {
          // tab point
          // offset is distance from tab center where tool must stop
          final tabToolOffset = machine.tabWidth / 2 + machine.toolRadius;
          Point startOfTab, endOfTab;
          if (p.isSameVerticalAs(toolPoint)) {
            // vertically oriented tab
            var tabIsAbove = p.y > toolPoint.y;
            startOfTab = Point(toolPoint.x,
                tabIsAbove ? p.y - tabToolOffset : p.y + tabToolOffset);
            endOfTab = Point(toolPoint.x,
                tabIsAbove ? p.y + tabToolOffset : p.y - tabToolOffset);
          } else {
            // horizontally oriented tab
            var tabIsToRight = p.x > toolPoint.x;
            startOfTab = Point(
                tabIsToRight ? p.x - tabToolOffset : p.x + tabToolOffset, p.y);
            endOfTab = Point(
                tabIsToRight ? p.x + tabToolOffset : p.x - tabToolOffset, p.y);
          }
          // create the tab
          gCode.addAll([
            linearMoveToPoint(
                startOfTab, targetZ, machine.horizontalFeedCutting),
            lineWithComment(
                linearMoveToPoint(
                    startOfTab, machine.tabTopDepth, machine.verticalFeedUp),
                'tab'),
            linearMoveToPoint(
                endOfTab, machine.tabTopDepth, machine.horizontalFeedCutting),
            linearMoveToPoint(endOfTab, targetZ, machine.verticalFeedDown)
          ]);
        }
      });
    }
    gCode.add(lineWithComment(moveToClearanceHeight(), 'Rectangle cut done'));
  }

  /// Add mill cut to gCode list (multiple lines)
  ///
  /// Milling will be along the long side of the rectangle
  ///
  /// [outline] rectangular outline of the cut
  /// [cutDepth] in mm (negative) of the milled surface
  void addRectMill(Rect outline, double cutDepth, {String? description}) {
    // calculate the end points
    final machine = Machine();
    if (cutDepth > 0) throw StateError('cutDepth must be < 0');
    gCode.add(comment(description ?? 'Mill rectangle'));
    final offSet = -machine.toolRadius; // inside cut
    // cutRect is the outline adjusted for tool radius, using offSet
    var cutRect = Rect(Point(outline.bl.x - offSet, outline.bl.y - offSet),
        Point(outline.tr.x + offSet, outline.tr.y + offSet));
    final spacing = machine.toolRadius * machine.millOverlap;
    var points = cutRect.isLandscape
        ? Line(cutRect.bl, cutRect.tl).points(spacing: spacing)
        : Line(cutRect.bl, cutRect.br).points(spacing: spacing);
    points.add(points.last); // duplicate last point for last mill run
    // get into position
    gCode.addAll([
      moveToSafeHeight(),
      rapidMoveToPoint(cutRect.bl),
      moveToClearanceHeight()
    ]);
    while (toolZ > cutDepth) {
      var targetZ = max(cutDepth,
          min(toolZ - machine.maxCutStepDepth, -machine.maxCutStepDepth));
      gCode.add(
          linearMoveToPoint(points.first, targetZ, machine.verticalFeedDown));
      var toPath = true; // in 'to' stage (versus 'return' stage) of mill
      points.skip(1).forEach((p) {
        final acrossPoint; // the point across from the current position
        final adjacentPoint; // the point adjacent to the acrossPoint
        if (cutRect.isLandscape) {
          acrossPoint =
              Point(toPath ? cutRect.tr.x : cutRect.bl.x, toolPoint.y);
          adjacentPoint = Point(acrossPoint.x, p.y);
        } else {
          acrossPoint =
              Point(toolPoint.x, toPath ? cutRect.tr.y : cutRect.bl.y);
          adjacentPoint = Point(p.x, acrossPoint.y);
        }
        gCode.add(linearMoveToPoint(
            acrossPoint, targetZ, machine.horizontalFeedMilling));
        gCode.add(linearMoveToPoint(
            adjacentPoint, targetZ, machine.horizontalFeedMilling));
        toPath = !toPath; // reverse direction
      });
      // if we need to make another mill cut, make sure the tool is back in the
      // bottom left start position
      if (toolZ > cutDepth) {
        final previousToolZ = toolZ;
        gCode.addAll([
          moveToClearanceHeight(),
          rapidMoveToPoint(cutRect.bl),
          linearMove(z: previousToolZ, f: machine.verticalFeedDown)
        ]);
      }
    }
    gCode.add(
        lineWithComment(moveToClearanceHeight(), 'Milling operation done'));
  }

  String lineAddArgAndValue(String line, String argument, double value) {
    var valueAsString = value.toStringAsFixed(4);
    return '$line $argument$valueAsString'.trim();
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
    var machine = Machine();
    // horizontal
    var numTabs = (rect.width / machine.tabSpacing).floor();
    if (numTabs > 0) {
      var dist = rect.width / (numTabs + 1);
      result['H'] = List.generate(numTabs, (index) => (index + 1) * dist);
    }
    // vertical
    numTabs = (rect.height / machine.tabSpacing).floor();
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
}
