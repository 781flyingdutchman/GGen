import 'package:shaker/work_generator.dart';
import 'package:shaker/work_simulator.dart';

import 'objects.dart';

enum Placement {
  initial,
  up,
  right,
  down,
  left,
  upAlignLeft,
  upAlignRight,
  downAlignLeft,
  downAlignRight
}

class WorkpiecePlacement {
  final WorkSimulator workSimulator;
  final Placement placement;
  final String description;
  Rect? machineBox; // box in machine coordinates

  WorkpiecePlacement(this.workSimulator, this.placement,
      {this.description = ''});

  String get fullDescription => description.isEmpty ? 'workpiece' : description;

  void reset() => machineBox = null;
}

class MultiWorkpiece {
  final workpiecePlacements = <WorkpiecePlacement>[];
  double safetyMargin = 20; // safety margin around box for conflict assessment
  bool layoutComplete = false;

  List<Rect?> get machineBoxes =>
      workpiecePlacements.map((wp) => wp.machineBox).toList();

  void add(WorkpiecePlacement workpiecePlacement) {
    if (workpiecePlacements.isEmpty) {
      if (workpiecePlacement.placement != Placement.initial) {
        throw StateError('First addition must have placement set to initial');
      }
    } else {
      if (workpiecePlacement.placement == Placement.initial) {
        throw StateError('Placement must be set for subsequent workpieces');
      }
    }
    workpiecePlacements.add(workpiecePlacement);
    layoutComplete = false;
  }

  /// Lays out all work pieces in accordance with their placement directive
  /// without their [machineBox] touching another
  void layout() {
    workpiecePlacements.forEach((wp) => wp.reset());
    var lastMachineBox = Rect.zero(); // remember last workpiece
    workpiecePlacements.forEach((wp) {
      wp.workSimulator.simulate(); // sets the bounding box
      if (wp == workpiecePlacements.first) {
        // simple placement for first workpiece
        wp.machineBox = wp.workSimulator.physicalBox;
        lastMachineBox = wp.workSimulator.physicalBox;
      } else {
        // subsequent placement
        // center on last box as the starting point for layout
        var box = wp.workSimulator.physicalBox.centerOn(lastMachineBox);
        // align with far left or far right as needed
        if (wp.placement == Placement.downAlignLeft ||
            wp.placement == Placement.upAlignLeft) {
          box = box.alignLeftWith(encompassingBox());
        }
        if (wp.placement == Placement.downAlignRight ||
            wp.placement == Placement.upAlignRight) {
          box = box.alignRightWith(encompassingBox());
        }
        // determine incremental movement direction
        var dx = 0.0;
        var dy = 0.0;
        switch (wp.placement) {
          case Placement.left:
            dx = -1;
            break;

          case Placement.right:
            dx = 1;
            break;

          case Placement.up:
          case Placement.upAlignLeft:
          case Placement.upAlignRight:
            dy = 1;
            break;

          case Placement.down:
          case Placement.downAlignLeft:
          case Placement.downAlignRight:
            dy = -1;
            break;

          case Placement.initial:
            throw StateError(
                'Code error - initial should not be possible here');
        }
        final translate = Point(dx, dy);
        while (conflict(box.grow(safetyMargin * 2))) {
          box = box.translated(translate);
        }
        wp.machineBox = box;
        lastMachineBox = box;
      }
    });
    layoutComplete = true;
  }

  /// Returns true if box overlaps with any of the machineBoxes
  bool conflict(Rect box) =>
      workpiecePlacements.any((wp) => wp.machineBox?.overlaps(box) ?? false);

  /// Returns the box that encompasses all machineBoxes
  Rect encompassingBox() {
    var box = Rect.zero();
    workpiecePlacements.forEach((wp) {
      var machineBox = wp.machineBox;
      if (machineBox != null) {
        if (machineBox.left < box.left) {
          box = box.withNewLeft(machineBox.left);
        }
        if (machineBox.right > box.right) {
          box = box.withNewRight(machineBox.right);
        }
        if (machineBox.bottom < box.bottom) {
          box = box.withNewBottom(machineBox.bottom);
        }
        if (machineBox.top > box.top) {
          box = box.withNewTop(machineBox.top);
        }
      }
    });
    return box;
  }

  /// Returns code combining all work pieces
  String generateCode() {
    if (!layoutComplete) {
      throw StateError(
          'Layout not complete: cannot generate code. Call layout() first');
    }
    var gCode = '';
    var totalElapsedTime = Duration(minutes: 0);
    var machineToolPoint = Point.zero(); // machine coordinates (fixed frame)
    workpiecePlacements.forEach((wp) {
      var description = wp.fullDescription;
      var machineBox = wp.machineBox;
      if (machineBox == null) {
        throw StateError('MachineBox is null');
      }
      var translate = Point(machineBox.left - machineToolPoint.x,
          machineBox.bottom - machineToolPoint.y);
      if (translate != Point.zero() && wp != workpiecePlacements.first) {
        var switchToMetric = wp.workSimulator.metric ? '' : 'G21\n';
        gCode += '\n(Move origin for $description)\n'
            '${switchToMetric}G10 L20 P1 X${(-translate.x).toStringAsFixed(4)} '
            'Y${(-translate.y).toStringAsFixed(4)}'
            '\n\n(start $description)\n\n';
      }
      totalElapsedTime += wp.workSimulator.elapsedTime;
      gCode += wp.workSimulator.gCodeWithout('M2') +
          '\n(Running time for $description: ${wp.workSimulator.elapsedTime})\n'
              '(Time to this point: $totalElapsedTime)\n'
              '(end $description)\n';
      // recalculate machineToolPoint at the end of this work
      // equal to original machineToolPoint + translation + physicalToolPoint
      // as the latter is in workpiece coordinates, offset from the start
      machineToolPoint = Point.add(Point.add(machineToolPoint, translate),
          wp.workSimulator.physicalToolPoint);
    });

    return gCode;
  }

  /// Returns a unique name for [WorkpiecePlacement] description
  ///
  /// If the name is already in the list, a incrementing number is added
  String uniqueNameFor(String description) {
    var existing = workpiecePlacements.map((e) => e.fullDescription).toList();
    if (!existing.contains(description)) {
      return description;
    }
    var i = 2;
    var newDescription = '$description #$i';
    while (existing.contains(newDescription)) {
      i++;
      newDescription = '$description #$i';
    }
    return newDescription;
  }
}

/// WorkGenerator for multiple workpieces
///
/// Initialize with the [MultiWorkpiece] and call
/// generateCode() to get the code encapsulated by the appropriate
/// pre- and post-ambles.
class MultiWorkGenerator extends WorkGenerator {
  final MultiWorkpiece multiWorkpiece;

  MultiWorkGenerator(this.multiWorkpiece);

  @override
  void header() {
    gCode.addAll([
      comment('Layout generated by GGen'),
      ...multiWorkpiece.workpiecePlacements
          .map((wp) => '(${wp.fullDescription} placement ${wp.placement})'),
      comment('Time: ${DateTime.now().toString()}'),
    ]);
  }

  @override
  void workpieceCode() =>
      gCode.addAll(multiWorkpiece.generateCode().split('\n'));

  @override
  void postamble() {
    var box = multiWorkpiece.encompassingBox();
    gCode.addAll([
      '(Total workspace extends from ${box.bl} to ${box.tr})',
      '(or a width of ${box.width.toStringAsFixed(3)} mm and height ${box.height.toStringAsFixed(3)} mm)'
    ]);
    super.postamble();
  }
}
