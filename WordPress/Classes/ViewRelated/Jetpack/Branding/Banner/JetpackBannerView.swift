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

    func setup() {
        backgroundColor = Self.jetpackBannerBackgroundColor

        let jetpackButton = JetpackButton(style: .banner)
        jetpackButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(jetpackButton)

        pinSubviewToAllEdges(jetpackButton)
    }

    private static let jetpackBannerBackgroundColor = UIColor(light: .muriel(color: .jetpackGreen, .shade0),
                                                              dark: .muriel(color: .jetpackGreen, .shade90))
}

// MARK: Responding to scroll events
extension JetpackBannerView: Subscriber {

    typealias Input = CGFloat
    typealias Failure = Never

    func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }

    func receive(_ input: CGFloat) -> Subscribers.Demand {

        let isHidden: Bool = input < 0

        guard self.isHidden != isHidden else {
            return .unlimited
        }

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: { [weak self] in
            self?.isHidden = isHidden
        }, completion: nil)
        return .unlimited
    }

    func receive(completion: Subscribers.Completion<Never>) {}
}
