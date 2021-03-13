# GGen
### G-code generator and layout utility

GGen generates gCode for use in CNC machines. It targets three-axis CNC machines,
not 3D printers.

#### Download
Download the executable [here](https://github.com/781flyingdutchman/GGen/blob/master/bin/ggen.exe).

#### Overview
GGen currently supports two commands:  
1. shaker - to create shaker style panels and drawer fronts
2. layout - to layout multiple gCode files as part of a larger job

#### shaker
Use `ggen shaker` to create shaker style panels and drawer fronts.  

    Shaker style doors and drawer fronts.
    Usage: ggen shaker [options] [outputFile]

    Usage: ggen shaker [arguments]
    -h, --help                     Print this usage information.
        --width                    Width of the panel
        --height                   Height of the panel
    -s, --styleWidth               Width of the styles
                                   (defaults to "2in")
    -p, --pocketDepth              Depth of middle pocket
                                   (defaults to "4mm")
        --[no-]handle              Drill hole(s) for handle
    -x, --handleOffsetX            Handle X offset relative to center of panel
                                   (defaults to "0")
    -y, --handleOffsetY            Handle Y offset relative to center of panel
                                   (defaults to "0")
    -o, --handleOrientation        Handle orientation (if 2 holes)
                                   [landscape, portrait]
        --handleWidth              Distance between holes (if 2 holes)
                                   (defaults to "0")
        --clearanceHeight          ClearanceHeight (safe for in-workpiece moves)
                                   (defaults to "1mm")
        --safeHeight               SafeHeight (above everything)
                                   (defaults to "4mm")
    -d, --toolDiameter             Tool diameter
                                   (defaults to "0.25in")
    -f, --horizontalFeedCutting    Horizontal feed for cutting operation
                                   (defaults to "500mm/min")
        --horizontalFeedMilling    Horizontal feed for milling operation
                                   (defaults to "900mm/min")
    -v, --verticalFeed             Vertical feed
                                   (defaults to "1mm/s")
    -m, --materialThickness        Thickness of the material
                                   (defaults to "0.75in")

All values are in mm by default, but can be set using typical suffixes. For example:

    ggen shaker --width=14in --height=7in -p 2 -m 0.5in panel.nc

generates a standard panel 14" by 7" with the middle recessed panel 2mm below the surface, cut  
from 1/2" material, stored in `panel.nc`.  
The G-Code will include 10mm high tabs to hold the panel, spaced 300mm apart, and
the origin (0, 0) is at the bottom left of the panel.

If `--handle` is set you can provide an offset from the midpoint of the panel, and
if the handle requires two holes (i.e. it is not a knob) then add `--handleOrientation`
and `--handleWidth`.  For example:  

    ggen shaker --width=14in --height=7in -p 2 -m 0.5in --handle --handleOrientation landscape  
    --handleWidth 4in panel.nc

generates the same panel with two holes, 4" apart, to support a horizontal handle in the middle.

#### layout

Use `ggen layout` to layout multiple gCode files on the work space while ensuring they
do not overlap.

    Layout multiple work pieces in one gCode file
    Usage: ggen layout file [file placement]... [outputFile]
    where placement sets placement relative to the previous workpiece:
    r  - right
    u  - up
    l  - left
    d  - down
    ul - up and left-align with leftmost workpiece
    ur - up and right-align with rightmost workpiece
    dl - down and left-align with leftmost workpiece
    dr - down and right-align with rightmost workpiece

    To place the same workpiece as the previous one, use underscore _
    instead of filename

For example, to create 3 copies of a small drawer front and 2 copies of a large one
above it, use `ggen layout small.nc _ r _ r large.nc ul _ r`. This translates into:  

1. Layout the `small.nc` drawer front (the `small.nc` argument)
2. add another one to the right (the `_` indicates another `small.nc` and `r` means to the right)
3. add another one to the right (same parameters)
4. move up and all the way left to place the `large.nc` drawer front (`ul` means up and align left)
5. add another to the right (the `_` and `r` parameters again)

Add an output file as the last parameter to save the output.

The layout uses the `G10 L20 P1` code to reset the machine's coordinate system, so
after the execution of the full work the machine origin will not be the same as it was
when it started.

The output gCode contains useful information about estimated duration of each work piece, and
the bounds of the entire work.  Make sure the entire work fits on the machine, given its
starting point.
