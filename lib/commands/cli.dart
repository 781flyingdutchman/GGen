import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:shaker/shaker_work.dart';

import '../conversion.dart';
import '../objects.dart';
import '../work.dart';
import 'shaker_command.dart';

class Cli {
  final mainParser = ArgParser();

  /// Run the command line interpreter
  void run(List<String> arguments) {
    exitCode = 0; // presume success;

    var runner = CommandRunner('ggen', 'Generate G-code.')
      ..addCommand(ShakerCommand());

    runner.run(arguments).catchError((error) {
      if (error is! UsageException) throw error;
      stderr.write(error);
      exit(64); // Exit code 64 indicates a usage error.
    });
  }

  /// Configure machine parameters with the arguments provided
  static void configureMachine(ArgResults argResults) {
    final machine = Machine();
    final p = GParser();
    for (var option in argResults.options) {
      var value = argResults[option]; // Can include unit
      switch (option) {
        case 'clearanceHeight':
          machine.clearanceHeight = p.parseDistanceValue(value);
          break;

        case 'safeHeight':
          machine.safeHeight = p.parseDistanceValue(value);
          break;

        case 'toolDiameter':
          machine.toolDiameter = p.parseDistanceValue(value);
          break;

        case 'horizontalFeedCutting':
          machine.horizontalFeedCutting = p.parseFeedValue(value);
          break;

        case 'horizontalFeedMilling':
          machine.horizontalFeedMilling = p.parseFeedValue(value);
          break;

        case 'verticalFeed':
        case 'v':
          machine.verticalFeedDown = p.parseFeedValue(value);
          break;

        case 'materialThickness':
          machine.materialThickness = p.parseDistanceValue(value);
          break;

        default:
          break;
      }
    }
  }

  /// Configure machine parameters with the arguments provided
  static void configureShakerPanel(ArgResults argResults) {
    final panel = ShakerPanel();
    final p = GParser();
    var hasHandle = false;
    var handleOffsetX, handleOffsetY, handleOrientationLandscape;
    final options = argResults.options;
    for (var option in options) {
      var value = argResults[option];
      switch (option) {
        case 'width':
          panel.width = p.parseDistanceValue(value);
          break;

        case 'height':
          panel.height = p.parseDistanceValue(value);
          break;

        case 'styleWidth':
        case 's':
          panel.styleWidth = p.parseDistanceValue(value);
          break;

        case 'pocketDepth':
        case 'p':
          panel.pocketDepth = p.parseDistanceValue(value);
          break;

        case 'handle':
          hasHandle = value;
          break;

        case 'handleWidth':
          panel.handleWidth = p.parseDistanceValue(value);
          break;

        case 'handleOffsetX':
        case 'x':
          handleOffsetX = p.parseDistanceValue(value);
          break;

        case 'handleOffsetY':
        case 'y':
          handleOffsetY = p.parseDistanceValue(value);
          break;

        case 'handleOrientation':
        case 'o':
          handleOrientationLandscape = value == 'landscape';
          break;

        default:
          break;
      }
    }
    // check required values were present
    if (!options.contains('width') || !options.contains('height')) {
      throw ArgumentError('Panel width and height are required');
    }
    // check handle values
    if (hasHandle) {
      panel.handleMidpoint = Point(handleOffsetX, handleOffsetY);
      if (handleOrientationLandscape != null) {
        if (panel.handleWidth == 0) {
          throw ArgumentError('If handle orientation is given, also provide a handleWidth');
        }
        panel.handleOrientationLandscape = handleOrientationLandscape;
      }
      else {
        if (panel.handleWidth > 0) {
          throw ArgumentError('If handleWidth is given, also provide handleOrientation');
        }
      }
    }
    else {
      // no handle
      if (handleOffsetX != 0 || handleOffsetY != 0 || handleOrientationLandscape != null || panel.handleWidth > 0) {
        throw ArgumentError('Specify --handle when providing handle related options');
      }
      panel.handleMidpoint = null;
    }
    // cleanup pocketDepth
    if (panel.pocketDepth > 0) {
      panel.pocketDepth = -panel.pocketDepth;
    }
  }
}

void errorInvalidUsage(String command, ArgParser parser) {
  stdout.write('Invalid usage for command $command\n');
  stdout.write(parser.usage);
  exitCode = 2;
}

void exitWithError(String message) {
  stdout.write(message);
  exitCode = 1;
}
