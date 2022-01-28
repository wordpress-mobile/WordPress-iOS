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
        retryLabel.text = "Tap to retry"
        retryLabel.textColor = .textSubtle
        WPStyleGuide.configureLabel(retryLabel, textStyle: .callout, fontWeight: .regular)
        return retryLabel
    }()

    convenience init(message: String, retry: Bool) {
        self.init(arrangedSubviews: [])

        errorTitle.text = message
        addArrangedSubview(errorTitle)

        axis = .vertical
        spacing = Constants.spacing

        if retry {
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
}
