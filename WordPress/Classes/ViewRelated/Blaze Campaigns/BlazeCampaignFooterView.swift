import UIKit

final class BlazeCampaignFooterView: UIView {
    var onRetry: (() -> Void)?

    private lazy var errorView: UIView = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.text = Strings.errorMessage

        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.title = Strings.retry
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        button.configuration = configuration
        button.addTarget(self, action: #selector(buttonRetryTapped), for: .touchUpInside)

        return UIStackView(arrangedSubviews: [label, UIView(), button])
    }()

    private let spinner = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(errorView)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(errorView, insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0), priority: .init(999))

        addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        pinSubviewAtCenter(spinner)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var state: State = .empty {
        didSet {
            guard oldValue != state else { return }

            subviews.forEach { $0.isHidden = true }
            switch state {
            case .empty: break
            case .error: errorView.isHidden = false
            case .loading: spinner.isHidden = false
            }
        }
    }

    @objc private func buttonRetryTapped() {
        onRetry?()
    }

    private struct Strings {
        static let errorMessage = NSLocalizedString("blaze.campaigns.pageLoadError", value: "An error occcured", comment: "A bootom footer error message in Campaign list.")
        static let retry = NSLocalizedString("blaze.campaigns.pageLoadRetry", value: "Retry", comment: "A bottom footer retry button in Campaign list.")
    }

    enum State {
        case empty, loading, error
    }
}
