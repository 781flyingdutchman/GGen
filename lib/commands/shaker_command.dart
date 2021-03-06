import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:shaker/work.dart';

import '../shaker_work.dart';
import 'cli.dart';

class ShakerCommand extends Command {
  @override
  final name = 'shaker';
  @override
  final description = 'Shaker style doors and drawer fronts';

  ShakerCommand() {
    argParser.addOption('width', help: 'Width of the panel');
    argParser.addOption('height', help: 'Height of the panel');
    argParser.addOption('styleWidth', abbr: 's',
        help: 'Width of the styles',
        defaultsTo: '2in');
    argParser.addOption('pocketDepth', abbr: 'p',
        help: 'Depth of middle pocket',
        defaultsTo: '4mm');
    argParser.addFlag(
        'handle', help: 'Drill hole(s) for handle', defaultsTo: false);
    argParser.addOption('handleOffsetX', abbr: 'x',
        help: 'Handle X offset relative to center of panel', defaultsTo: '0');
    argParser.addOption('handleOffsetY', abbr: 'y',
        help: 'Handle Y offset relative to center of panel', defaultsTo: '0');
    argParser.addOption('handleOrientation', abbr: 'o',
        allowed: ['landscape', 'portrait'],
        help: 'Handle orientation (if 2 holes)');
    argParser.addOption(
        'handleWidth', help: 'Distance between holes (if 2 holes)', defaultsTo: '0');
    // machine related options for shaker
    argParser.addOption('clearanceHeight',
        help: 'ClearanceHeight (safe for in-workpiece moves)', defaultsTo: '1mm');
    argParser.addOption('safeHeight', help: 'SafeHeight (above everything)', defaultsTo: '4mm');
    argParser.addOption('toolDiameter', abbr: 'd', help: 'Tool diameter', defaultsTo: '0.25in');
    argParser.addOption('horizontalFeedCutting', abbr: 'f',
        help: 'Horizontal feed for cutting operation', defaultsTo: '500mm/min');
    argParser.addOption(
        'horizontalFeedMilling', help: 'Horizontal feed for milling operation', defaultsTo: '900mm/min');
    argParser.addOption('verticalFeed', abbr: 'v', help: 'Vertical feed', defaultsTo: '1mm/s');
    argParser.addOption('materialThickness', abbr: 'm',
        help: 'Thickness of the material',
        defaultsTo: '0.75in');
  }

  @override
  void run() {
    final results = argResults;
    if (results != null) {
      try {
        Cli.configureMachine(results);
        Cli.configureShakerPanel(results);
        var w = ShakerWork();
        w.generateCode();
        if (results.rest.isEmpty) {
                stdout.write(w.gCodeAsString);
              }
              else {
                if (results.rest.length > 1) {
                  throw ArgumentError('Only provide one output file. Got ${results.rest}');
                }
                var fileName = results.rest.first;
                var file = File(fileName);
                if (file.existsSync()) {
                  stdout.write('File $fileName exists. Overwrite? (Y/N)');
                  var response = stdin.readLineSync();
                  if (response != null && response.toLowerCase().startsWith('y')) {
                    file.writeAsStringSync(w.gCodeAsString);
                  }
                }
                else {
                  file.writeAsStringSync(w.gCodeAsString);
                }
              }
      } catch (e) {
        stderr.writeln(e);
        exitCode = 1;
      }
    }
  }
}