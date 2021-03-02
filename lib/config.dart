
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
  double toolDiameter = 6.35;
  double maxCutStepDepth = 5;
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
  double tabHeight = 11;  // positive value
  double tabWidth = 20;
  double tabSpacing = 300;
  double get tabTopDepth => -materialThickness + tabHeight;


}


/// Configuration parameters for the Panel
class Panel {
  static final Panel _singleton = Panel._internal();

  // configuration variables for machine

  double width = 0;
  double height = 0;
  double styleWidth = 40;
  double millDepth = 4;


  factory Panel() {
    return _singleton;
  }

  Panel._internal();

  bool get isLandscape => width > height;

}
