import Foundation

protocol InfiniteScrollerViewDelegate: AnyObject {
    /// Called on every step of `CADisplayLink` to adjust the `InfiniteScrollerView`'s offset.
    ///
    /// A negative value scrolls downward.
    func rate(for infiniteScrollerView: InfiniteScrollerView) -> CGFloat
}
