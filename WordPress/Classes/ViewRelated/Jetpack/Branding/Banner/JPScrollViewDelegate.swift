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
        let shouldHide = JetpackBannerScrollVisibility.shouldHide(scrollView)
        scrollViewTranslationPublisher.send(shouldHide)
    }
}
