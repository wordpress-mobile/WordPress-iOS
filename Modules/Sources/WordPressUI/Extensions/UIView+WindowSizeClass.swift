import UIKit

extension UIView {
    /// The horizontal size class of the window the view is in, or the view's own size class while it isn't
    /// in a window.
    ///
    /// Use it for decisions about the whole window, such as how to present a modal or whether to use the
    /// larger metrics meant for a wide window. A view's own size class can be compact inside a wide window:
    /// on a full-screen iPad, the split view gives its sidebar and list columns a compact size class, and so
    /// does a form sheet, which is also what the default presentation style produces on iPadOS 26 and later.
    public var windowHorizontalSizeClass: UIUserInterfaceSizeClass {
        (window ?? self).traitCollection.horizontalSizeClass
    }
}

extension UIViewController {
    /// The horizontal size class of the window the view controller's view is in, or the view controller's
    /// own size class while its view isn't loaded or isn't in a window. See `UIView.windowHorizontalSizeClass`.
    public var windowHorizontalSizeClass: UIUserInterfaceSizeClass {
        viewIfLoaded?.windowHorizontalSizeClass ?? traitCollection.horizontalSizeClass
    }
}
