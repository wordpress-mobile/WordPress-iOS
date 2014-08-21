DTFoundation AppKit Enhancements
================================

This part of DTFoundation adds enhancements for AppKit on OS X.

## Classes

### DTScrollView

A scroll view that forwards scroll events up the responder chain if scrolling is along an axis that no scroll bar is shown for. This is useful to have a horizontal scroll view contained in a vertical one.

## Categories

### NSDocument (DTFoundation)

Utility Methods for working with `NSDocument` instances.

### NSImage (DTUtilities)

Utilities for `NSImage`.

### NSValue (DTConversion)

Category on NSValue providing some struct encoding that is missing on Mac, but exists on iOS.

### NSView (DTAutoLayout)

Useful shortcuts for auto layout on Mac.

### NSWindowController (DTPanelControllerPresenting)

Enhancement for `NSWindowController` to present a sheet modally, similar to iOS.
