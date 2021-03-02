import 'dart:io';

import 'package:args/args.dart';

class Cli {
  final mainParser = ArgParser();
  late ArgParser shakerParser;

  void main(List<String> arguments) {
    exitCode = 0; // presume success;

    // Command 'shaker'
    shakerParser = mainParser.addCommand('shaker');
    shakerParser.addOption('width', abbr: 'w', help: 'Width of the panel');
    shakerParser.addOption('height', abbr: 'h', help: 'Height of the panel');
    shakerParser.addOption('styleWidth', abbr: 's', help: 'Width of the styles', defaultsTo: '5cm');
    shakerParser.addOption('pocketDepth', abbr: 'p', help: 'Depth of middle pocket', defaultsTo: '4');
    shakerParser.addFlag('handle', help: 'Drill hole(s) for handle', defaultsTo: false);
    shakerParser.addOption('handleOffsetX', abbr: 'x', help: 'Handle X offset relative to center of panel');
    shakerParser.addOption('handleOffsetY', abbr: 'y', help: 'Handle Y offset relative to center of panel');
    shakerParser.addOption('handleOrientation', abbr: 'o', allowed: ['landscape', 'portrait'], help: 'Handle orientation (if 2 holes)');
    shakerParser.addOption('handleWidth', help: 'Distance between holes (if 2 holes)');
    // machine related options for shaker
    shakerParser.addOption('clearanceHeight', help: 'ClearanceHeight (safe for in-workpiece moves)');
    shakerParser.addOption('safeHeight', help: 'SafeHeight (above everything)');
    shakerParser.addOption('toolDiameter', abbr: 'd', help: 'Tool diameter');
    shakerParser.addOption('horizontalFeedCutting', abbr: 'f', help: 'Horizontal feed for cutting operation');
    shakerParser.addOption('horizontalFeedMilling', help: 'Horizontal feed for milling operation');
    shakerParser.addOption('verticalFeed', abbr: 'v', help: 'Vertical feed');
    shakerParser.addOption('materialThickness', abbr: 'm', help: 'Thickness of the material', defaultsTo: '0.75in');

    // parse the arguments
    var result = mainParser.parse(arguments);
    var command = result.command;
    if (command == null) {
      errorNoCommand();
      return;
    }
    errorInvalidUsage('shaker', shakerParser);
  }

  void errorInvalidUsage(String command, ArgParser parser) {
    stdout.write('Invalid usage for command $command\n');
    stdout.write(parser.usage);
    exitCode = 2;
  }

  void errorNoCommand() {
    stdout.write('Missing command\n\nValid commands are: shaker');
  }
}

void main(List<String> arguments) {
  final cli = Cli();
  cli.main(arguments);
}


