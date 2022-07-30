import Combine
import UIKit

class JetpackBannerView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        backgroundColor = Self.jetpackBannerBackgroundColor

        let jetpackButton = JetpackButton(style: .banner)
        jetpackButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(jetpackButton)

        pinSubviewToAllEdges(jetpackButton)
    }

    /// Preferred minimum height to be used for constraints
    static let minimumHeight: CGFloat = 50
    private static let jetpackBannerBackgroundColor = UIColor(light: .muriel(color: .jetpackGreen, .shade0),
                                                              dark: .muriel(color: .jetpackGreen, .shade90))
}

// MARK: Responding to scroll events
extension JetpackBannerView: Subscriber {

    typealias Input = JPScrollViewDataDelegate
    typealias Failure = Never

    func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }

    func receive(_ input: JPScrollViewDataDelegate) -> Subscribers.Demand {
        let isHidden: Bool

        /// The scrollable content isn't any larger than its frame, so don't hide the banner if the view is bounced.
        if input.scrollViewContentHeight <= input.scrollViewFrameHeight {
            isHidden = false
        /// Don't hide the banner until the view has scrolled down some. Currently the height of the banner itself.
        } else if input.scrollViewContentOffsetY <= frame.height {
            isHidden = false
        /// The banner hides on scrolling down, shows on scrolling up.
        } else {
            isHidden = input.translationY < 0
        }

        guard self.isHidden != isHidden else {
            return .unlimited
        }

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
            self.isHidden = isHidden
            self.superview?.layoutIfNeeded()
        }, completion: nil)
        return .unlimited
    }

    func receive(completion: Subscribers.Completion<Never>) {}
}
