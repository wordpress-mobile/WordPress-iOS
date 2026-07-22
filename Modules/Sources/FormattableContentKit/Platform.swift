#if canImport(UIKit)
import UIKit

/// The platform's color type: `UIColor` on UIKit platforms, `NSColor` on AppKit.
///
/// FormattableContentKit's model and protocol layer is cross-platform; this alias
/// lets the notification-styling protocols name a color without hard-importing UIKit,
/// so the module builds on macOS. Colors are only ever materialized at render time,
/// which happens on iOS.
public typealias PlatformColor = UIColor

/// The platform's image type: `UIImage` on UIKit platforms, `NSImage` on AppKit.
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit

public typealias PlatformColor = NSColor
public typealias PlatformImage = NSImage
#endif
