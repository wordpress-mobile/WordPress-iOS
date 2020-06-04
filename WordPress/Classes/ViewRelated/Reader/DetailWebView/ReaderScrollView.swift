import Foundation

/// A UIScrollView decorator
///
class ReaderScrollView: UIScrollView {
    weak var navigationBar: UINavigationBar?

    override var contentOffset: CGPoint {
        get {
            return super.contentOffset
        }

        set {
            /// When reaching the bottom of the content the nav bar and toolbar appears
            /// This causes a changing on the content offset due to the navigation bar
            /// If that's the case, we simply ignore that, so the text doesn't "jumps" while the user is reading
            if contentOffset.y - newValue.y != navigationBar?.frame.height {
                super.contentOffset = newValue
            }
        }
    }
}
