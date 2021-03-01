
/// Configuration parameters for the machine
class Machine {
  static final Machine _singleton = Machine._internal();
  
  // configuration variables for machine
  double clearanceHeight = 1;
  double safeHeight = 5;
  double horizontalFeedCutting = 500; // in mm/min
  double horizontalFeedMilling = 900; // in mm/min
  double verticalFeedDown = 60; // in mm/min
  double verticalFeedUp = 120; // in mm/min


  double toolDiameter = 6.35;
  double maxCutStepDepth = 5;

  factory Machine() {
    return _singleton;
  }

  Machine._internal();

  double get toolRadius => toolDiameter / 2;
}


/// Configuration parameters for the Panel
class Panel {
  static final Panel _singleton = Panel._internal();

  // configuration variables for machine
  double materialThickness = 20;
  double width = 0;
  double height = 0;
  double styleWidth = 40;
  double millDepth = 4;
  double tabHeight = 11;  // positive value
  double tabWidth = 20;
  double tabSpacing = 300;

  factory Panel() {
    return _singleton;
  }

  Panel._internal();

  bool get isLandscape => width > height;
  double get cutThroughDepth => -(materialThickness + 1.5);
  double get tabTopDepth => -materialThickness + tabHeight;
}
