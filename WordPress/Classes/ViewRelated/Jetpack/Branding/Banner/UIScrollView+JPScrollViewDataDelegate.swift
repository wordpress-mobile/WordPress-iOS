import Foundation

extension UIScrollView: JPScrollViewDataDelegate {

    var translationY: CGFloat {
        return panGestureRecognizer.translation(in: superview).y
    }

    var scrollViewFrameHeight: CGFloat {
        frame.height
    }

    var scrollViewContentHeight: CGFloat {
        contentSize.height
    }

    var scrollViewContentOffsetY: CGFloat {
        contentOffset.y + adjustedContentInset.top
    }
}
