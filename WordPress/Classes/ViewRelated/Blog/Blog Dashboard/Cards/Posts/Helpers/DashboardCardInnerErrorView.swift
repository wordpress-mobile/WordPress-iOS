import UIKit

protocol DashboardCardInnerErrorViewDelegate: AnyObject {
    func retry()
}

class DashboardCardInnerErrorView: UIStackView {
    weak var delegate: DashboardCardInnerErrorViewDelegate?

    private lazy var errorTitle: UILabel = {
        let errorTitle = UILabel()
        errorTitle.textAlignment = .center
        errorTitle.textColor = .textSubtle
        WPStyleGuide.configureLabel(errorTitle, textStyle: .callout, fontWeight: .semibold)
        return errorTitle
    }()

    private lazy var retryLabel: UILabel = {
        let retryLabel = UILabel()
        retryLabel.textAlignment = .center
        retryLabel.text = Strings.tapToRetry
        retryLabel.textColor = .textSubtle
        WPStyleGuide.configureLabel(retryLabel, textStyle: .callout, fontWeight: .regular)
        return retryLabel
    }()

    convenience init(message: String, canRetry: Bool) {
        self.init(arrangedSubviews: [])

        errorTitle.text = message
        addArrangedSubview(errorTitle)

        axis = .vertical
        spacing = Constants.spacing

        if canRetry {
            addArrangedSubview(retryLabel)

            isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
            addGestureRecognizer(tap)
        }
    }

    @objc func didTap() {
        delegate?.retry()
    }

    private enum Constants {
        static let spacing: CGFloat = 8
    }

    private enum Strings {
        static let tapToRetry = NSLocalizedString("Tap to retry", comment: "Label for a button to retry loading posts")
    }
}
