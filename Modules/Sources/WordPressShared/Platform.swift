#if canImport(UIKit)
import UIKit

/// The platform's color type: `UIColor` on UIKit platforms, `NSColor` on AppKit.
///
/// A thin bridge so cross-platform modules can name a color in a signature without
/// importing UIKit. The concrete color is only ever materialized at the UI layer.
public typealias PlatformColor = UIColor

/// The platform's image type: `UIImage` on UIKit platforms, `NSImage` on AppKit.
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit

public typealias PlatformColor = NSColor
public typealias PlatformImage = NSImage
#endif
