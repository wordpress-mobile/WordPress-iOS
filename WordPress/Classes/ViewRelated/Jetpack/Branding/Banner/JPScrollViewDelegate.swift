import Combine
import CoreGraphics

/// Conform to this protocol to send scrollview translations to a `JetpackBannerView` instance
protocol JPScrollViewDelegate: UIScrollViewDelegate {

    var scrollViewPublisher: PassthroughSubject<JPScrollViewDataDelegate, Never> { get }
    func addTranslationObserver(_ receiver: JetpackBannerView)
}

extension JPScrollViewDelegate {

    func addTranslationObserver(_ receiver: JetpackBannerView) {
        scrollViewPublisher.subscribe(receiver)
    }
}
