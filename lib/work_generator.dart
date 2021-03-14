import 'dart:math';

import 'package:shaker/objects.dart';

/// Base for all work
///
/// Contains a Machine configuration class, and a Work class where all the
/// operations happen
///
/// Extend the Work class for specific work, such as the ShakerWork

/// Configuration parameters for the machine
class Machine {
  static final Machine _singleton = Machine._internal();

  factory Machine() {
    return _singleton;
  }

  Machine._internal();

  // configuration variables for machine

  // heights
  double clearanceHeight = 1;
  double safeHeight = 5;

  // tool
  double _toolDiameter = 6.35;
  double maxCutStepDepth = 0.9 * 6.35;

  double get toolRadius => toolDiameter / 2;

  // feeds
  double horizontalFeedCutting = 500; // in mm/min
  double horizontalFeedMilling = 900; // in mm/min
  double verticalFeedDown = 60; // in mm/min
  double verticalFeedUp = 120; // in mm/min

  // material
  double materialThickness = 20;

  double get cutThroughDepth => -(materialThickness + 1.5);

  // operations
  double millOverlap = 0.5; // 0.5 means half tool diameter overlap

  // tabs
  double tabHeight = 11; // positive value
  double tabWidth = 20;
  double tabSpacing = 300;

  double get tabTopDepth => -materialThickness + tabHeight;

  double get toolDiameter => _toolDiameter;

  set toolDiameter(double d) {
    _toolDiameter = d;
    maxCutStepDepth = 0.9 * d;
  }

  @override
  String toString() {
    return 'Machine with clearanceHeight: $clearanceHeight, safeHeight: $safeHeight, toolDiameter: $toolDiameter, maxCutStepDepth: $maxCutStepDepth, horizontalFeedCutting: $horizontalFeedCutting, horizontalFeedMilling: $horizontalFeedMilling, verticalFeedDown: $verticalFeedDown, verticalFeedUp: $verticalFeedUp, materialThickness: $materialThickness, millOverlap: $millOverlap, tabHeight: $tabHeight, tabWidth: $tabWidth, tabSpacing: $tabSpacing';
  }
}

/// Base class for the actual work generation
///
/// Extends this class and override [workpieceCode] to insert the
/// actual workpiece gCode in the right spot.
class WorkGenerator {
  final gCode = <String>[];
  Point toolPoint = Point(0, 0);
  double toolZ = 0;

  /// Generates the G-code
  ///
  /// Prior to calling, ensure that [Machine] is set up correctly, and that
  /// any work-specific parameters used in [workpieceCode] are set.
  /// A subclass *must* override [workpieceCode] and *may* override
  /// [validateConfig], [header], [preamble] and [postamble],
  /// ideally calling super.
  void generateCode() {
    validateConfig();
    gCode.removeWhere((element) => true); // clear all
    header();
    preamble();
    workpieceCode();
    postamble();
  }

  String get gCodeAsString => gCode.join('\n');

  /// Insert header at top of file
  void header() {
    gCode.addAll([
      comment('Generated by GGen'),
      comment('Time: ${DateTime.now().toString()}'),
    ]);
  }

  /// Insert a standard preamble
  void preamble() {
    gCode.addAll([
      space(),
      comment('begin preamble'),
      'G17 G90',
      'G21',
    ]);
  }

  /// Insert the actual workpiece code
  void workpieceCode() {
    throw UnimplementedError('Subclass must override workpieceCode');
  }

  /// Insert a standard postamble
  void postamble() {
    gCode.addAll([space(), comment('begin postamble'), 'M5', 'G17 G90', 'M2']);
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
    addSpace();
    gCode.add(comment(description ?? 'Rectangle cut'));
    var offSet = insideCut ? -machine.toolRadius : machine.toolRadius;
    // cutRect is the outline adjusted for tool radius, using offSet
    var cutRect = outline.grow(2 * offSet);
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
        if (cutRect.hasCorner(p)) {
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
  /// [millDepth] in mm (negative) of the milled surface
  void addRectMill(Rect outline, {double? millDepth, String? description}) {
    // calculate the end points
    final machine = Machine();
    var depth = millDepth ?? machine.cutThroughDepth;
    if (depth > 0) throw StateError('Depth must be < 0');
    addSpace();
    gCode.add(comment(description ?? 'Mill rectangle'));
    final offSet = -machine.toolRadius; // inside cut
    // cutRect is the outline adjusted for tool radius, using offSet
    var cutRect = outline.grow(2 * offSet);
    final spacing = machine.toolDiameter * machine.millOverlap;
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
    while (toolZ > depth) {
      var targetZ = max(depth,
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
      if (toolZ > depth) {
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

  /// Creates hole at current position, using vertical feed
  ///
  /// Does not generate a canned drill mode like G81, but
  /// simulates that effect
  ///
  /// [depth] must be negative
  /// [feedRate] is feed rate
  ///
  /// If hole is deeper than [maxCutStepDepth] then the drilling will
  /// peck and retract to [clearanceHeight], then plunges again
  void addHole({required double depth, required double feedRate}) {
    if (depth > 0) throw StateError('Depth must be < 0');
    final machine = Machine();
    if (toolZ > machine.clearanceHeight) {
      gCode.add(moveToClearanceHeight());
    }
    var holeDepth = toolZ; // need to hold separately due to retract
    while (holeDepth > depth) {
      var targetZ = max(depth,
          min(holeDepth - machine.maxCutStepDepth, -machine.maxCutStepDepth));
      gCode.addAll(
          [linearMove(z: targetZ, f: feedRate), moveToClearanceHeight()]);
      holeDepth = targetZ;
    }
  }

  /// Add holes for a handle
  ///
  /// [midPoint] is the midPoint of the handle
  /// [drillDepth] if omitted will cut through
  /// [landscape] if given indicates a two-hole handle, and then requires [size]
  /// [size] is the distance between the holes
  /// [description] will be added as a comment at the start of the operation
  void addHandleHoles(Point midPoint,
      {double? drillDepth,
      bool? landscape,
      double? size,
      String? description}) {
    final machine = Machine();
    var depth = drillDepth ?? machine.cutThroughDepth;
    if (depth > 0) throw StateError('Depth must be < 0');
    addSpace();
    gCode.add(comment(description ?? 'Handle'));
    if (landscape == null) {
      // single hole drill
      gCode.addAll([
        moveToSafeHeight(),
        rapidMoveToPoint(midPoint),
      ]);
      addHole(depth: depth, feedRate: machine.verticalFeedDown);
    } else {
      // two-hole drill
      if (size == null) {
        throw StateError('Size must be given for two hole handle');
      }
      final Point p1, p2;
      if (landscape) {
        p1 = Point(midPoint.x - size / 2, midPoint.y);
        p2 = Point(midPoint.x + size / 2, midPoint.y);
      } else {
        p1 = Point(midPoint.x, midPoint.y - size / 2);
        p2 = Point(midPoint.x, midPoint.y + size / 2);
      }
      gCode.addAll([
        moveToSafeHeight(),
        rapidMoveToPoint(p1),
      ]);
      addHole(depth: depth, feedRate: machine.verticalFeedDown);
      gCode.add(rapidMoveToPoint(p2));
      addHole(depth: depth, feedRate: machine.verticalFeedDown);
    }
  }

  /// Appends an argument and a value to the line
  ///
  /// The value is a double, represented with 4 decimal places
  String lineAddArgAndValue(String line, String argument, double value) {
    var valueAsString = value.toStringAsFixed(4);
    return '$line $argument$valueAsString'.trim();
  }

  /// Appends comment using ';'
  String lineWithComment(String line, String comment) => '$line;  $comment';

  /// Returns a comment in (comment) form
  ///
  /// If the comment is longer than 35 characters then multiple comment
  /// lines will be returned, truncated at an appropriate point.
  String comment(String comment) {
    comment = comment.replaceAll(')', ']');
    comment = comment.replaceAll('(', '[');
    var output = <String>[];
    var lines = comment.split('\n');
    for (var line in lines) {
      while (line.length > 35) {
        var i = 34;
        while (i > 0) {
          if (line[i] == ' ') {
            break;
          }
          i--;
        }
        if (i == 0) {
          i = 34; // if no spaces found
        }
        output.add('(${line.substring(0, i)})');
        if (line.substring(i, i + 1) == ' ') {
          line = line.substring(i + 1);
        } else {
          line = line.substring(i);
        }
      }
      output.add('($line)');
    }
    return output.join('\n');
  }

  String space() => '';

  void addSpace() => gCode.add(space());

  // calculations

  /// Returns a map with tab points
  ///
  /// A cut direction with tab(s) is listed as 'H', or 'V' for horizontal or
  /// vertical, and the values are the mid points of each tab
  Map<String, List<double>> tabPoints(Rect rect) {
    var result = <String, List<double>>{};
    var machine = Machine();
    var numHorTabs = (rect.width / machine.tabSpacing).floor();
    var numVerTabs = (rect.height / machine.tabSpacing).floor();
    if (numHorTabs == 0 && numVerTabs == 0) {
      // Make sure there is at least one tab
      if (rect.isLandscape) {
        numHorTabs = 1;
      } else {
        numVerTabs = 1;
      }
    }
    // horizontal
    if (numHorTabs > 0) {
      var dist = rect.width / (numHorTabs + 1);
      result['H'] = List.generate(numHorTabs, (index) => (index + 1) * dist);
    }
    // vertical
    if (numVerTabs > 0) {
      var dist = rect.height / (numVerTabs + 1);
      result['V'] = List.generate(numVerTabs, (index) => (index + 1) * dist);
    }
    return result;
  }

  /// Validates the configuration
  ///
  /// If an error is found, throws a StateError, otherwise returns
  void validateConfig() {
    var machine = Machine();
    if (machine.safeHeight < machine.clearanceHeight) {
      throw StateError('SafeHeight must be > ClearanceHeight');
    }
    if (machine.safeHeight < 1 || machine.clearanceHeight < 1) {
      throw StateError('SafeHeight and ClearanceHeight must be >= 1 mm');
    }
  }
}
