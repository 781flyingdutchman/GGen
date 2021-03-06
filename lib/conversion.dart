/// Conversions convert the value given in a unit other than mm, to the
/// value in mm.
///
/// For example, 10.cm equals 100, because 10 cm is 100 mm.
/// Distance-per-time units are converted to mm/min
extension MmConversions on num {
  double get cm => this * 10;

  double get m => this * 1000;

  double get inch => this * 25.4;

  double get ft => inch * 12;

  double get fpm => ft; // feet per minute
  double get ipm => inch; // inch per minute
  double get cpm => cm; // centimeter per minute
  double get mmps => this * 60.0; // mm per second
  double get fps => fpm * 60.0; // feet per second
  double get ips => ipm * 60.0; // inch per second
}

/// Singleton to help with GCode parsing
class GParser {
  final _floatGroup = r'([-+]?[0-9]*\.?[0-9]+)'; // eg -3.12
  final _intGroup = r'([0-9]*)'; // eg 3
  final _whitespaceMatch = r'\s*'; // used with preceding letter, eg X
  final _distanceUnitGroup = r"""(m|cm|mm|in|inch|inches|\"|ft|feet|')?""";
  final _feedUnitGroup =
      r'(mm\/min|mm\/s|cm\/min|in\/min|inch\/min|inches\/min|in\/s|inch\/s|inches\/s|ft\/min|feet\/min)?';

  static final GParser _singleton = GParser._internal();

  factory GParser() {
    return _singleton;
  }

  GParser._internal();

  /// Returns the value of a parameter
  ///
  /// eg in [input] 'G1 X-1.23' calling with [parameter] 'X' will return -1.23
  /// Throws ArgumentError if argument cannot be found or value not parsed
  double parseValueOf(String parameter, String input, {bool isInt = false}) {
    final exp = isInt
        ? RegExp(parameter + _whitespaceMatch + _intGroup)
        : RegExp(parameter + _whitespaceMatch + _floatGroup);
    final match = exp.firstMatch(input);
    if (match == null) {
      throw ArgumentError('Parameter $parameter not found in $input');
    }
    return double.parse(match.group(1)!);
  }

  /// Returns the int values of a parameter as a list
  ///
  /// eg in [input] 'G1 X-1.23' calling with [parameter] 'G' will return [1]
  /// Throws ArgumentError if argument cannot be found or value not parsed
  int parseIntValueOf(String parameter, String input) => parseValueOf(parameter, input, isInt: true).truncate();

  /// Convert distance values to mm
  double parseDistanceValue(String valueWithUnit) {
    final exp = RegExp(_floatGroup + _distanceUnitGroup + '\$');
    final match = exp.firstMatch(valueWithUnit);
    if (match == null) {
      throw ArgumentError('Could not parse $valueWithUnit as a distance');
    }
    var value = double.parse(match.group(1)!);
    if (match.groupCount == 1 || match.group(2) == null) {
      return value;
    }
    if (match.groupCount > 2) {
      throw ArgumentError('Could not parse $valueWithUnit as a distance');
    }
    switch (match.group(2)) {
      case 'm':
        return value.m;

      case 'cm':
        return value.cm;

      case 'mm':
        return value;

      case 'in':
      case 'inch':
      case 'inches':
      case '"':
        return value.inch;

      case 'ft':
      case 'feet':
      case "'":
        return value.ft;

      default:
        throw ArgumentError('Could not parse $valueWithUnit as a distance');
    }
  }

  /// Convert feed values to mm/min
  double parseFeedValue(String valueWithUnit) {
    final exp = RegExp(_floatGroup + _feedUnitGroup + '\$');
    final match = exp.firstMatch(valueWithUnit);
    if (match == null) {
      throw ArgumentError('Could not parse $valueWithUnit as a feed value');
    }
    var value = double.parse(match.group(1)!);
    if (match.groupCount == 1 || match.group(2) == null) {
      return value;
    }
    if (match.groupCount > 2) {
      throw ArgumentError('Could not parse $valueWithUnit as a feed value');
    }
    switch (match.group(2)) {
      case 'mm/min':
        return value;

      case 'mm/s':
        return value.mmps;

      case 'cm/min':
        return value.cpm;

      case 'in/s':
      case 'inch/s':
      case 'inches/s':
        return value.ips;

      case 'in/min':
      case 'inch/min':
      case 'inches/min':
        return value.ipm;

      case 'ft/min':
      case 'feet/min':
        return value.fpm;

      default:
        throw ArgumentError('Could not parse $valueWithUnit as a feed value');
    }
  }
}
