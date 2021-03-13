import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shaker/multi_workpiece.dart';
import 'package:shaker/work_simulator.dart';

import 'cli.dart';

class LayoutCommand extends Command {
  final placements = {
    'l': Placement.left,
    'r': Placement.right,
    'u': Placement.up,
    'd': Placement.down,
    'ul': Placement.upAlignLeft,
    'ur': Placement.upAlignRight,
    'dl': Placement.downAlignLeft,
    'dr': Placement.downAlignRight
  };

  @override
  final name = 'layout';

  @override
  final description = [
    'Layout multiple work pieces in one gCode file',
    'Usage: ggen layout file [file placement]... [outputFile]',
    '',
    'where placement sets placement relative to the previous workpiece:',
    'r  - right',
    'u  - up',
    'l  - left',
    'd  - down',
    'ul - up and left-align with leftmost workpiece',
    'ur - up and right-align with rightmost workpiece',
    'dl - down and left-align with leftmost workpiece',
    'dr - down and right-align with rightmost workpiece',
    '',
    'To place the same workpiece as the previous one, use underscore _',
    'instead of filename',
    '',
    'For example, to create 3 copies of a small drawer front and 2 copies',
    'of a large one above it, use:',
    '',
    '    ggen layout small.nc _ r _ r large.nc ul _ r',
    '',
    'where small.nc and large.nc are example filenames'
  ].join('\n');

  LayoutCommand();

  @override
  void run() {
    final results = argResults?.rest;
    if (results != null) {
      var arguments = List.from(results);
      if (arguments.length < 3) {
        reportError('Layout requires at least two files');
        return;
      }
      // substitute * for file names
      var lastFileName = arguments.first;
      for (var i = 1; i < arguments.length; i += 2) {
        if (arguments[i] == '_') {
          arguments[i] = lastFileName;
        } else {
          lastFileName = arguments[i];
        }
      }
      try {
        // add first file with initial placement to the MultiWorkpiece
        var multi = MultiWorkpiece();
        var fileName = arguments.first;
        var file = File(fileName);
        var gCode = file.readAsStringSync();
        var workSimulator = WorkSimulator(gCode);
        var workpiecePlacement = WorkpiecePlacement(
            workSimulator, Placement.initial,
            description: p.split(fileName).last);
        multi.add(workpiecePlacement);
        // add each subsequent file and placement to the MultiWorkpiece
        var i = 1; // index in arguments
        File? outFile;
        while (i < arguments.length) {
          fileName = arguments[i];
          if (i + 1 < arguments.length) {
            file = File(fileName);
            gCode = file.readAsStringSync();
            workSimulator = WorkSimulator(gCode);
            var placementString;
            placementString = arguments[i + 1];
            var placement = placements[placementString];
            if (placement != null) {
              workpiecePlacement = WorkpiecePlacement(workSimulator, placement,
                  description: multi.uniqueNameFor(p.split(fileName).last));
              multi.add(workpiecePlacement);
            } else {
              reportError('Placement directive $placementString is not valid');
              return;
            }
          } else {
            // last item, must be output file
            outFile = File(fileName);
          }
          i += 2;
        }
        if (outFile != null) {
          // we have an output file as last argument
          if (outFile.existsSync()) {
            stdout.write('File ${outFile.path} exists. Overwrite? (Y/N)');
            var response = stdin.readLineSync();
            if (response == null || !response.toLowerCase().startsWith('y')) {
              return;
            }
          }
        }
        // Do the layout and generate the code
        multi.layout();
        var generator = MultiWorkGenerator(multi)..generateCode();
        gCode = generator.gCodeAsString;
        if (outFile != null) {
          outFile.writeAsStringSync(gCode);
        } else {
          stdout.writeln(gCode);
        }
      } catch (e) {
        reportError(e.toString());
      }
    }
  }
  
}
