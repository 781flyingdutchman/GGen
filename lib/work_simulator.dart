import 'dart:math';

import 'package:logging/logging.dart';

import 'conversion.dart';
import 'objects.dart';

/// Base class for existing workpiece
class WorkSimulator {
  final log = Logger('Workpiece');
  final String gCode;

  final _lineComment = RegExp(r'\(.*\)$');
  final _semiComment = RegExp(r'[^;]*');
  final _GCommand = RegExp(r'G[0-9]*');
  final _parameters = ['X', 'Y', 'Z', 'I', 'J', 'F'];
  final _intParameters = ['G', 'M', 'L', 'P', 'T'];

  // machine state variables
  Point3D toolPoint = Point3D(0, 0, 4);
  Point3D physicalToolPoint =
      Point3D(0, 0, 4); // does not respond to coord changes
  Rect box = Rect.zero();
  Rect physicalBox = Rect.zero();
  double f = 0;
  bool absolute = true; // G90
  bool metric = true; // G21
  Duration elapsedTime = Duration(seconds: 0);

  WorkSimulator(this.gCode) {
    initMachine();
  }

  // Initialize all machine state variables
  void initMachine() {
    toolPoint = Point3D(0, 0, 4);
    f = 0;
    absolute = true; // G90
    metric = true; // G21
    elapsedTime = Duration(seconds: 0);
  }

  // Getters build on each other:
  // 1) split in lines
  // 2) remove comments
  // 3) split lines with multiple G codes
  // 4) convert to codeDict for easier interpretation

  Iterable<String> get gCodeLines => gCode.split('\n');

  Iterable<String> get gCodeWithoutComments =>
      gCodeLines.expand(withoutComments);

  Iterable<String> get gCodeWithSplitGCommands =>
      gCodeWithoutComments.expand(splitGCodes);

  Iterable<Map<String, dynamic>> get gCodeDicts =>
      gCodeWithSplitGCommands.expand(codeDict);

  /// Return the outline of this workpiece in its coordinates
  Rect get outline {
    var lines = gCodeLines.expand(withoutComments);
    return Rect(Point(0, 0), Point(0, 0));
  }

  /// Yields code line without comments
  Iterable<String> withoutComments(String line) sync* {
    line = line.trim();
    if (line.isNotEmpty && !_lineComment.hasMatch(line)) {
      // not an empty or comment line
      var match = _semiComment.firstMatch(line)!; // must match
      line = match.group(0)!;
      yield line;
    }
  }

  /// Splits lines with multiple G codes into separate lines
  Iterable<String> splitGCodes(String line) sync* {
    var matches = _GCommand.allMatches(line);
    if (matches.length <= 1) {
      yield line;
    } else {
      // multiple, so split at the start of every G code
      var i = 0; // start of line
      for (var m in matches.skip(1)) {
        yield line.substring(i, m.start).trim();
        i = m.start;
      }
      yield line.substring(i);
    }
  }

  /// Yields code dict for line
  Iterable<Map<String, dynamic>> codeDict(String line) sync* {
    final p = GParser();
    final lineDict = <String, dynamic>{};
    lineDict['line'] = line; // the original line
    _parameters.forEach((parameter) {
      if (p.hasParameter(parameter, line)) {
        lineDict[parameter] = p.parseValueOf(parameter, line);
      }
    });
    _intParameters.forEach((parameter) {
      if (p.hasParameter(parameter, line)) {
        lineDict[parameter] = p.parseIntValueOf(parameter, line);
      }
    });
    yield lineDict;
  }

  void simulate() => gCodeDicts.forEach(simulateLine);

  /// Simulate the tool movement for this line and update min/max values
  ///
  /// Note that state that transcends the line must be set, and may be updated
  /// by the code in this line. For example, switching to imperial units will
  /// affect all future lines.  This method must therefore be called in
  /// sequence, uninterrupted, and after calling initMachine.
  void simulateLine(final Map<String, dynamic> lineDict) {
    // map of g-codes to simulator functions
    final gCommands = {
      0: simG0,
      1: simG1,
      2: simG2,
      3: simG3,
      10: simG10,
      17: simG17,
      20: simG20,
      21: simG21,
      90: simG90,
      91: simG91
    };
    if (lineDict.containsKey('G')) {
      final gCommand = lineDict['G']!;
      var simFunc = gCommands[gCommand];
      if (simFunc != null) {
        simFunc(lineDict);
      } else {
        throw ArgumentError('G-code G$gCommand is not supported');
      }
    }

  }

  // action code functions for simulating a specific code, eg G0

  /// Returns [Point3D] representing the parameters X, Y and Z in the code line
  ///
  /// Missing parameters are 0, unless [startValues] are given
  /// The caller must determine whether to interpret XYZ as an absolute or a
  /// relative value.
  Point3D parseXyz(final Map<String, dynamic> lineDict,
      {Point3D? startValues}) {
    var x = startValues?.x ?? 0.0;
    var y = startValues?.y ?? 0.0;
    var z = startValues?.z ?? 0.0;
    if (lineDict.containsKey('X')) x = lineDict['X']!;
    if (lineDict.containsKey('Y')) y = lineDict['Y']!;
    if (lineDict.containsKey('Z')) z = lineDict['Z']!;
    return Point3D(x, y, z);
  }

  /// Returns [Point3D] representing the center of a circle defined by
  /// parameters I, J and K in the code line
  ///
  /// Missing parameters are 0, unless [startValues] are given
  /// IJK are always interpreted as relative to the start value
  /// and the returned point is the absolute center point
  Point3D parseIjk(final Map<String, dynamic> lineDict,
      {required Point3D startValues}) {
    var i = startValues.x;
    var j = startValues.y;
    var k = startValues.z;
    if (lineDict.containsKey('I')) i += lineDict['I']!;
    if (lineDict.containsKey('J')) j += lineDict['J']!;
    if (lineDict.containsKey('K')) k += lineDict['K']!;
    return Point3D(i, j, k);
  }

  void parseAndSetF(final Map<String, dynamic> lineDict) {
    if (lineDict.containsKey('F')) f = lineDict['F']!;
  }

  void simG0(final Map<String, dynamic> lineDict) {
    var to = absolute
        ? parseXyz(lineDict, startValues: toolPoint)
        : toolPoint + parseXyz(lineDict);
    if (toolPoint.z <= 0 || to.z <= 0) {
      warning('G0 with tool inside material', lineDict: lineDict);
    }
    linearMoveTo(to, 1000);
  }

  void simG1(final Map<String, dynamic> lineDict) {
    var to = absolute
        ? parseXyz(lineDict, startValues: toolPoint)
        : toolPoint + parseXyz(lineDict);
    parseAndSetF(lineDict);
    if (f == 0) {
      ArgumentError('Attempting to use G1 with F equal to 0');
    }
    linearMoveTo(to, f);
  }

  void simG2_3(final Map<String, dynamic> lineDict, {required bool clockWise}) {
    var to = absolute
        ? parseXyz(lineDict, startValues: toolPoint)
        : toolPoint + parseXyz(lineDict);
    var center = parseIjk(lineDict, startValues: toolPoint);
    // do double center check
    final r = center.distanceTo3D(toolPoint);
    if (!almostEqual(r, center.distanceTo3D(to))) {
      error('Circle midpoint not defined correctly', lineDict: lineDict);
      return;
    }
    // calculate start and end angles that can be reached clockwise or
    // anti-clockwise as required, then make linear moves for each
    // degree of angle change
    var aStart = atan2(toolPoint.y - center.y, toolPoint.x - center.x);
    var aEnd = atan2(to.y - center.y, to.x - center.x);
    final aIncrement = 2 * pi / 360;
    if (clockWise) {
      while (aStart < aEnd) {
        aStart += 2 * pi;
      }
      var a = aStart;
      while (a > aEnd) {
        a = max(a - aIncrement, aEnd);
        if (almostEqual(a, aEnd)) a = aEnd;
        var stepTo = Point3D(center.x + cos(a) * r, center.y + sin(a) * r, toolPoint.z);
        linearMoveTo(stepTo, f);
      }
    }
    else {
      while (aStart > aEnd) {
        aStart -= 2 * pi;
      }
      var a = aStart;
      while (a < aEnd) {
        a = min(a + aIncrement, aEnd);
        if (almostEqual(a, aEnd)) a = aEnd;
        var stepTo = Point3D(center.x + cos(a) * r, center.y + sin(a) * r, toolPoint.z);
        linearMoveTo(stepTo, f);
      }
    }
  }

  void simG2(final Map<String, dynamic> lineDict) {
    simG2_3(lineDict, clockWise: true);
  }

  void simG3(final Map<String, dynamic> lineDict) {
    simG2_3(lineDict, clockWise: false);
  }


  void simG10(final Map<String, dynamic> lineDict) {
    // coordinate system reset
    if (lineDict['L'] == null || lineDict['P'] == null) {
      error('Expect G10 to use L20 P1');
    }
    var lCode = lineDict['L']!;
    var pCode = lineDict['P']!;
    if (lCode != 20 || pCode != 1) {
      error('Expect G10 to use L20 P1');
    }
    // set toolPoint without actual movement
    toolPoint = absolute
        ? parseXyz(lineDict, startValues: toolPoint)
        : toolPoint + parseXyz(lineDict);
    updateBoxes();
  }

  void simG20(final Map<String, dynamic> lineDict) {
    metric = true;
  }

  void simG17(final Map<String, dynamic> lineDict) {}

  void simG21(final Map<String, dynamic> lineDict) {
    metric = false;
    error('G21 (imperial system) is not implemented. Use metric G17');
  }

  void simG90(final Map<String, dynamic> lineDict) {
    absolute = true;
  }

  void simG91(final Map<String, dynamic> lineDict) {
    absolute = false;
  }

  void simNoOp(final Map<String, dynamic> lineDict) => null;

  /// Move to absolute point [to] at given [feedRate]
  void linearMoveTo(Point3D to, double feedRate) {
    if (feedRate == 0) {
      throw StateError('Attempting move with feed rate 0');
    }
    var distance = toolPoint.distanceTo3D(to);
    elapsedTime += timeToMove(distance, feedRate);
    var movement = to - toolPoint;
    physicalToolPoint += movement;
    toolPoint = to;
    updateBoxes();
  }

  /// Update [box] and [physicalBox]
  void updateBoxes() {
    if (toolPoint.toLeftOf(box.bl)) box = box.withNewLeft(toolPoint.x);
    if (toolPoint.toRightOf(box.tr)) box = box.withNewRight(toolPoint.x);
    if (toolPoint.above(box.tr)) box = box.withNewTop(toolPoint.y);
    if (toolPoint.below(box.bl)) box = box.withNewBottom(toolPoint.y);

    if (physicalToolPoint.toLeftOf(physicalBox.bl)) {
      physicalBox = physicalBox.withNewLeft(physicalToolPoint.x);
    }
    if (physicalToolPoint.toRightOf(physicalBox.tr)) {
      physicalBox = physicalBox.withNewRight(physicalToolPoint.x);
    }
    if (physicalToolPoint.above(physicalBox.tr)) {
      physicalBox = physicalBox.withNewTop(physicalToolPoint.y);
    }
    if (physicalToolPoint.below(physicalBox.bl)) {
      physicalBox = physicalBox.withNewBottom(physicalToolPoint.y);
    }
  }

  /// Time it takes to move [distance] in mm at [feedRate] mm/min
  Duration timeToMove(double distance, double feedRate) =>
      Duration(milliseconds: (distance / feedRate * 60000).toInt());

  void warning(String message, {final Map<String, dynamic>? lineDict}) {
    if (lineDict != null) {
      message += ' in line ${lineDict['line']}';
    }
    log.warning(message);
  }

  void error(String message, {final Map<String, dynamic>? lineDict}) {
    if (lineDict != null) {
      message += ' in line ${lineDict['line']}';
    }
    throw StateError(message);
  }
}
