import UIKit

class DashboardPostListErrorCell: UITableViewCell, Reusable {

    // MARK: Public Variables

    var errorMessage: String? {
        didSet {
            errorTitle.text = errorMessage
        }
    }

    /// Closure to be called when cell is tapped
    /// If set, the retry label is displayed
    var onCellTap: (() -> Void)? {
        didSet {
            if onCellTap != nil {
                showRetry()
            }
            else {
                hideRetry()
            }
        }
    }

    // MARK: Views

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Constants.spacing
        return stackView
    }()

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

    private var tapGestureRecognizer: UITapGestureRecognizer?

    // MARK: Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: Helpers

    private func commonInit() {
        stackView.addArrangedSubviews([errorTitle, retryLabel])

        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdges(stackView, priority: Constants.constraintPriority)

        backgroundColor = .clear

        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
    }

    private func showRetry() {
        retryLabel.isHidden = false
        isUserInteractionEnabled = true
        if let tapGestureRecognizer = tapGestureRecognizer {
            addGestureRecognizer(tapGestureRecognizer)
        }
    }

    private func hideRetry() {
        retryLabel.isHidden = true
        isUserInteractionEnabled = false
        if let tapGestureRecognizer = tapGestureRecognizer {
            removeGestureRecognizer(tapGestureRecognizer)
        }
    }

    @objc func didTap() {
        onCellTap?()
    }

    private enum Constants {
        static let spacing: CGFloat = 8
        static let constraintPriority = UILayoutPriority(999)
    }

    private enum Strings {
        static let tapToRetry = NSLocalizedString("Tap to retry", comment: "Label for a button to retry loading posts")
    }
}
