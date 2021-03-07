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
  Rect? machineBox; // box in machine coordinates

  WorkpiecePlacement(this.workSimulator, this.placement);

  void reset() => machineBox = null;
}

class MultiWorkpiece {
  final workpiecePlacements = <WorkpiecePlacement>[];
  double safetyMargin = 20; // safety margin around box for conflict assessment

  List<Rect?> get machineBoxes => workpiecePlacements.map((wp) => wp.machineBox).toList();

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
        if (wp.placement == Placement.downAlignLeft || wp.placement == Placement.upAlignLeft) {
          box = box.alignLeftWith(encompassingBox());
        }
        if (wp.placement == Placement.downAlignRight || wp.placement == Placement.upAlignRight) {
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
            throw StateError('Code error - initial should not be possible here');
        }
        final translate = Point(dx, dy);
        while (conflict(box.grow(safetyMargin * 2))) {
          box = box.translated(translate);
        }
        wp.machineBox = box;
        lastMachineBox = box;
      }
    });
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
}
