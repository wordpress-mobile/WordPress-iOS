import Foundation

protocol JPScrollViewDataDelegate {

    var translationY: CGFloat { get }
    var scrollViewFrameHeight: CGFloat { get }
    var scrollViewContentHeight: CGFloat { get }
    var scrollViewContentOffsetY: CGFloat { get }
}
