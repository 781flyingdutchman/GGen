

import 'package:shaker/workpiece.dart';

import 'objects.dart';

enum Placement {initial, up, right, down, left, upFarLeft, upFarRight, downFarLeft, downFarRight}

class WorkpiecePlacement {
  final Workpiece workpiece;
  final Placement placement;
  Rect? machineBox; // box in machine coordinates

  WorkpiecePlacement(this.workpiece, this.placement);
  
  void reset() => machineBox = null;
}

class MultiWorkpiece {
  final workpiecePlacements = <WorkpiecePlacement>[];
  
  void add(WorkpiecePlacement workpiecePlacement) {
    if (workpiecePlacements.isEmpty) {
      if (workpiecePlacement.placement != Placement.initial) {
        throw StateError('First addition must have placement set to initial');
      }
    }
    else {
      if (workpiecePlacement.placement == Placement.initial) {
        throw StateError('Placement must be set for subsequent workpieces');
      }
    }
    workpiecePlacements.add(workpiecePlacement);
  }
  
  /// Lays out all work pieces in accordance with their placement directive
  /// without their [physicalBox] touching another
  void layout() {
    workpiecePlacements.forEach((wp) => wp.reset());

    workpiecePlacements.forEach((wp) {
      var lastMachineBox = Rect.zero(); // remember last workpiece
      wp.workpiece.simulate();  // sets the bounding box
      if (wp == workpiecePlacements.first) {
        // simple placement for first workpiece
        wp.machineBox = wp.workpiece.physicalBox;
        lastMachineBox = wp.workpiece.physicalBox;
      }
      else {
        // subsequent placement
        // center on last box as the starting point for layout
        var box = wp.workpiece.physicalBox.centerOn(lastMachineBox);
        // align with far left or far right as needed
        //TODO
      }
    });
  }

  Rect compositeBox() {
    var box = Rect.zero();
    //TODO
    return box;
  }
  
}