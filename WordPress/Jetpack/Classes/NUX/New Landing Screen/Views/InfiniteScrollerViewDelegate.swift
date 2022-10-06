import Foundation

protocol InfiniteScrollerViewDelegate {
    /// Called on every step of `CADisplayLink` to adjust the `InfiniteScrollerView`'s offset.
    ///
    /// A negative value scrolls downward.
    var rate: CGFloat { get }
}
