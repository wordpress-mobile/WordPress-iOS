import UIKit

/// This class keeps a search bar properly sized inside its container.
/// We can't use Auto Layout constraints directly on the search bar, as they
/// get broken when it activates and is moved into its search controller's view.
class SearchWrapperView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()

        for view in subviews where view is UISearchBar {
            view.frame = self.bounds
        }
    }
}
