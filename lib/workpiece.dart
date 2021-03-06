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
  var toolPoint = Point(0, 0);
  double toolZ = 4;
  double minX = 0, minY = 0, maxX = 0, maxY = 0;
  bool absolute = true; // G90
  bool metric = true; // G21

  Workpiece(this.gCode);

  List<String> get gCodeLines => gCode.split('\n');

  /// Return the outline of this workpiece in its coordinates
  Rect get outline {
    var lines = cleanCodeLines(gCodeLines);
    return Rect(Point(0, 0), Point(0, 0));
  }

  /// Yields clean code lines that can be directly interpreted
  Iterable<String> cleanCodeLines(Iterable<String> lines) sync* {
    for (var line in lines) {
      line = line.trim();
      if (line.isNotEmpty && !_lineComment.hasMatch(line)) {
        // not an empty or comment line
        var match = _semiComment.firstMatch(line)!; // must match
        line = match.group(0)!;
        yield line;
      }
    }
  }

  /// Splits lines with multiple G codes into separate lines
  Iterable<String> splitGCodes(Iterable<String> lines) sync* {
    for (var line in lines) {
      var matches = _GCommand.allMatches(line);
      if (matches.length <= 1) {
        yield line;
      }
      else {
        // multiple, so split at the start of every G code
        matches.skip(1).for
      }
    }
  }


  /// Yields code dict for every line
  Iterable<Map<String, dynamic>> codeDict(Iterable<String> lines) sync* {
    final p = GParser();
    for (var line in lines) {
      final lineDict = <String, dynamic>{};
      _parameters.forEach((parameter) {
        lineDict[parameter] = p.parseValueOf(parameter, line);
      });
      _intParameters.forEach((parameter) {
        lineDict[parameter] = p.parseIntValueOf(parameter, line);
      });
      yield lineDict;
    }
  }

  /// Simulate the tool movement for this line and update min/max values
  ///
  /// Note that state that transcends the line must be set, and may be updated
  /// by the code in this line. For example, switching to imperial units will
  /// affect all future lines.  This method must therefore be called in
  /// sequence, uninterrupted, and after an initialization step.
  void simulateLine(final Map<String, dynamic> lineDict) {
    var gs = lineDict['G'] as List<int>;
    var firstG;
    if (gs.isNotEmpty) {
      firstG = gs.first;
    }
    for (var g in gs) {
      switch (g) {
        case 10:
          // coordinate system reset
          if (!absolute) {
            error('Cannot  use G10 in incremental (G91) mode');
          }
          if (lineDict['L'] == null || lineDict['P'] == null) {
            error('Expect G10 to use L20 P1');
          }
          var lCode = lineDict['L']!.first;
          var pCode = lineDict['P']!.first;
          if (lCode != 20 || pCode != 1) {
            error('Expect G10 to use L20 P1');
          }
          //TODO  need to parse without reference to tool

        case 17: // X/Y plane
          break;

        case 18:
        case 19:
          error('Only X/Y plane (G17) operations allowed');
          break;

        case 20:
          metric = false;
          break;

        case 21:
          metric = true;
          break;

        case 90:
          absolute = true;
          break;

        case 91:
          absolute = false;
          break;
      }
    }
  }

  // action code functions for simulating a specific code, eg G0

  void simG0(final Map<String, dynamic> lineDict) {
    //TODO
  }

  void error(String message) {
    throw StateError(message);
  }

  /// Returns new tool coordinates based on the lineDict, as [x, y, z]
  ///
  /// Does take machine state into account, but does not update the tool
  List<double> newCoordinates(Map<String, dynamic> lineDict) {
    var x = lineDict['X'] as double?;
    var y = lineDict['Y'] as double?;
    var z = lineDict['Z'] as double?;
    var result = [toolPoint.x, toolPoint.y, toolZ];
    if (x != null) {
      if (!metric) x = x.inch;
      result[0] = absolute ? x : result[0] + x;
    }
    if (y != null) {
      if (!metric) y = y.inch;
      result[1] = absolute ? y : result[1] + y;
    }
    if (z != null) {
      if (!metric) z = z.inch;
      result[2] = absolute ? z : result[2] + z;
    }
    return result;
  }
}
