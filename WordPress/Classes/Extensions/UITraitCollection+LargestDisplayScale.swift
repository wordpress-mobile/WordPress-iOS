import UIKit

extension UITraitCollection {
    /// A trait collection with the largest display scale of any device the app
    /// runs on: 3x, on iPhone. iPads, and the iPhone and iPad apps on Mac and
    /// Vision Pro, are 2x.
    ///
    /// Use it to size images when there is no view to read the display scale
    /// from. The images are sharp on every display, at the cost of downloading
    /// more data than a 2x display needs.
    @objc static let largestDisplayScale = UITraitCollection(displayScale: 3)
}
