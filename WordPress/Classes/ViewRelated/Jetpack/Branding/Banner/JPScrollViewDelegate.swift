import Combine
import CoreGraphics
import UIKit

/// Conform to this protocol to send scrollview translations to a `JetpackBannerView` instance
protocol JPScrollViewDelegate: UIScrollViewDelegate {

    var scrollViewTranslationPublisher: PassthroughSubject<Bool, Never> { get }
    func addTranslationObserver(_ receiver: JetpackBannerView)
}

extension JPScrollViewDelegate {

    func addTranslationObserver(_ receiver: JetpackBannerView) {
        scrollViewTranslationPublisher.subscribe(receiver)
    }

    func processJetpackBannerVisibility(_ scrollView: UIScrollView) {
        let shouldHideJetpackBanner = Self.shouldHideJetpackBanner(
            contentHeight: scrollView.contentSize.height,
            frameHeight: scrollView.frame.height,
            verticalContentOffset: scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        )

        scrollViewTranslationPublisher.send(shouldHideJetpackBanner)
    }

    static func shouldHideJetpackBanner(
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
