import UIKit

/// This UIScrollView subclass enables scrolling when the initial tap is inside a UIButton.
/// By default touches inside a UIButton cancels the scrolling action. This subclass overrides this behavior.
/// It's recommended to use this subclass when a scroll view is mainly populated by UIButtons.
class ButtonScrollView: UIScrollView {

    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view.isKind(of: UIButton.self) {
          return true
        }

        return super.touchesShouldCancel(in: view)
    }

}
