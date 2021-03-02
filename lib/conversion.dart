
/// Conversions convert the value given in a unit other than mm, to the
/// value in mm.
///
/// For example, 10.cm equals 100, because 10 cm is 100 mm.
/// Distance-per-time units are converted to mm/min
extension MmConversions on num {
  double get cm => this * 10;
  double get m => this * 1000;
  double get inch => this * 25.4;
  double get feet => inch * 12;
  double get fpm => feet; // feet per minute
  double get ipm => inch; // inch per minute
  double get cpm => cm; // centimeter per minute
  double get mmps => this * 60.0; // mm per second
}

/// Singleton to help with GCode parsing
class GParser {
  final floatCapture = r'([-+]?[0-9]*\.?[0-9]+)'; // eg -3.12
  final whitespaceMatch = r'\s*'; // used with preceding letter, eg X

  static final GParser _singleton = GParser._internal();

  factory GParser() {
    return _singleton;
  }

  GParser._internal();

  /// returns the value of a parameter
  ///
  /// eg in [input] 'G1 X-1.23' calling with [parameter] 'X' will return -1.23
  /// Throws ArgumentError if argument cannot be found or value not parsed
  double valueOf(String parameter, String input) {
    final exp = RegExp(parameter + whitespaceMatch + floatCapture);
    final match = exp.firstMatch(input);
    if (match == null) {
      throw ArgumentError('Parameter $parameter not found in $input');
    }
    return double.parse(match.group(1)!);
  }

}

