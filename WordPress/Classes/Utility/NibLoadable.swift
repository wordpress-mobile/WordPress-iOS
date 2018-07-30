import UIKit

/// A protocol for views that can be loaded from nibs.
public protocol NibLoadable {

    /// Default nib name.
    static var defaultNibName: String { get }

    /// Default bundle to load from.
    static var defaultBundle: Bundle { get }

    /// Default nib created using nib name and bundle.
    static var defaultNib: UINib { get }
}

public extension NibLoadable {

    static var defaultNibName: String {
        return String(describing: self)
    }

    static var defaultBundle: Bundle {
        return Bundle.main
    }

    static var defaultNib: UINib {
        return UINib(nibName: defaultNibName, bundle: defaultBundle)
    }

    /// Loads view from the default nib.
    ///
    /// - Returns: Loaded view.
    static func loadFromNib() -> Self {
        guard let result = defaultBundle.loadNibNamed(defaultNibName, owner: nil, options: nil)?.first as? Self else {
            fatalError("[NibLoadable] Cannot load view from nib.")
        }
        return result
    }
}
