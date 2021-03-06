import 'dart:math';

import 'conversion.dart';
import 'objects.dart';

/// Base class for existing workpiece
class Workpiece {
  final String gCode;

  final _lineComment = RegExp(r'\(.*\)$');
  final _semiComment = RegExp(r'[^;]*');
  final _GCommand = RegExp(r'G[0-9]*');
  final _parameters = ['X', 'Y', 'Z', 'I', 'J', 'F'];
  final _intParameters = ['G', 'M', 'L', 'P', 'T'];

  // machine state variables
  Point3D toolPoint = Point3D(0, 0, 4);
  double minX = 0,
      minY = 0,
      maxX = 0,
      maxY = 0,
      f = 0;
  bool absolute = true; // G90
  bool metric = true; // G21
  Duration elapsedTime = Duration(seconds: 0);

  Workpiece(this.gCode) {
    initMachine();
  }

  // Initialize all machine state variables
  void initMachine() {
    toolPoint = Point3D(0, 0, 4);
    minX = 0;
    minY = 0;
    maxX = 0;
    maxY = 0;
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
      10: simG10,
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
      }
      else {
        throw ArgumentError('G-code G$gCommand is not supported');
      }
    }
  }

  // action code functions for simulating a specific code, eg G0

  /// Returns [Point3D] representing the paramters X, Y and Z in the code line
  ///
  /// Missing parameters are 0, unless [startValues] are given
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

  void parseAndSetF(final Map<String, dynamic> lineDict) {
    if (lineDict.containsKey('F')) f = lineDict['F']!;
  }

  void simG0(final Map<String, dynamic> lineDict) {
    var to = absolute ? parseXyz(lineDict, startValues: toolPoint) : toolPoint +
        parseXyz(lineDict);
    var distance = toolPoint.distanceTo3D(to);
    elapsedTime += timeToMove(distance, 1000);
    toolPoint = to;
  }

  void simG1(final Map<String, dynamic> lineDict) {
    var to = absolute ? parseXyz(lineDict, startValues: toolPoint) : toolPoint +
        parseXyz(lineDict);
    var distance = toolPoint.distanceTo3D(to);
    parseAndSetF(lineDict);
    if (f == 0) {
      ArgumentError('Attempting to use G1 with F equal to 0');
    }
    elapsedTime += timeToMove(distance, f);
    toolPoint = to;
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
    toolPoint = absolute ? parseXyz(lineDict, startValues: toolPoint) : toolPoint +
        parseXyz(lineDict);
  }

  void simG20(final Map<String, dynamic> lineDict) {
    metric = true;
  }

  void simG21(final Map<String, dynamic> lineDict) {
    metric = false;
  }

  void simG90(final Map<String, dynamic> lineDict) {
    absolute = true;
  }

  void simG91(final Map<String, dynamic> lineDict) {
    absolute = false;
  }



  void simNoOp(final Map<String, dynamic> lineDict) => null;

  /// Time it takes to move [distance] in mm at [f] mm/min
  Duration timeToMove(double distance, double f) =>
      Duration(milliseconds: (distance / f * 60000).toInt());

  void error(String message) {
    throw StateError(message);
  }

}
