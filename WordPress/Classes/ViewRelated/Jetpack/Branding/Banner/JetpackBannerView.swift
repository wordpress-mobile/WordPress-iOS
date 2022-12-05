import Combine
import UIKit

class JetpackBannerView: UIView {

    var buttonAction: (() -> Void)?

    init(buttonAction: (() -> Void)? = nil) {
        super.init(frame: .zero)
        self.buttonAction = buttonAction
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    @objc private func jetpackButtonTapped() {
        buttonAction?()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: JetpackBannerView.minimumHeight).isActive = true
        backgroundColor = Self.jetpackBannerBackgroundColor

        let jetpackButton = JetpackButton(style: .banner)
        jetpackButton.translatesAutoresizingMaskIntoConstraints = false
        jetpackButton.addTarget(self, action: #selector(jetpackButtonTapped), for: .touchUpInside)
        addSubview(jetpackButton)

        pinSubviewToSafeArea(jetpackButton)
    }

    /// Preferred minimum height to be used for constraints
    static let minimumHeight: CGFloat = 44
    private static let jetpackBannerBackgroundColor = UIColor(light: .muriel(color: .jetpackGreen, .shade0),
                                                              dark: .muriel(color: .jetpackGreen, .shade90))
}

// MARK: Responding to scroll events
extension JetpackBannerView: Subscriber {

    typealias Input = Bool
    typealias Failure = Never

    func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }

    func receive(_ input: Bool) -> Subscribers.Demand {
        let isHidden = input

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
