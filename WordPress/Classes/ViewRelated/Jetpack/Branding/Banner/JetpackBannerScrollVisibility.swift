import Foundation
import UIKit

struct JetpackBannerScrollVisibility {
    static func shouldHide(_ scrollView: UIScrollView) -> Bool {
        return Self.shouldHide(
            contentHeight: scrollView.contentSize.height,
            /// We default to the superview's (UIStackView) frame height because it's unaffected by the banner's visibility, unlike the UIScrollView's frame.
            /// This prevents a looping edge case where hiding the banner causes the content height to be less than the frame height, and vice versa.
            frameHeight: scrollView.superview?.frame.height ?? scrollView.frame.height,
            verticalContentOffset: scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        )
    }

    static func shouldHide(
        contentHeight: CGFloat,
        frameHeight: CGFloat,
        verticalContentOffset: CGFloat
    ) -> Bool {
        /// The scrollable content isn't any larger than its frame, so don't hide the banner if the view is bounced.
        if contentHeight <= frameHeight {
            return false
        /// Don't hide the banner until the view has scrolled down some. Currently the height of the banner itself.
        } else if verticalContentOffset <= JetpackBannerView.minimumHeight {
            return false
        }

        return true
    }
}
