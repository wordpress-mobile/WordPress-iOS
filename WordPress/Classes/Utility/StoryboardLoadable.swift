import Foundation

/// Protocol to conform for views that can be loaded from storyboards.
public protocol StoryboardLoadable {

    /// Default storyboard name.
    static var defaultStoryboardName: String { get }

    /// Default controller ID in storyboard.
    static var defaultControllerID: String { get }

    /// Default bundle to load.
    static var defaultBundle: Bundle { get }
}

public extension StoryboardLoadable where Self: UIViewController {

    static var defaultControllerID: String {
        return String(describing: self)
    }

    static var defaultBundle: Bundle {
        return Bundle.main
    }

    /// Loads view from storyboard and allows initializer injection.
    ///
    /// - Returns: Loaded view.
    static func loadFromStoryboard<ViewController: UIViewController>(creator: ((NSCoder) -> ViewController?)? = nil) -> Self {
        let storyboard = UIStoryboard(name: defaultStoryboardName, bundle: defaultBundle)
        guard let viewController = storyboard.instantiateViewController(identifier: defaultControllerID, creator: creator) as? Self else {
            fatalError("[StoryboardLoadable] Cannot instantiate view controller from storyboard.")
        }
        return viewController
    }
}
