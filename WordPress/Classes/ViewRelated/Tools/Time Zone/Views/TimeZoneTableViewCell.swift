import UIKit

class TimeZoneTableViewCell: WPTableViewCell {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        setupTimeZoneLabel(label)
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label

        return label
    }()

    lazy var leftSubtitle: UILabel = {
        let label = UILabel()
        setupTimeZoneLabel(label)
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel

        return label
    }()

    lazy var rightSubtitle: UILabel = {
        let label = UILabel()
        setupTimeZoneLabel(label)
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel

        if label.effectiveUserInterfaceLayoutDirection == .leftToRight {
            // swiftlint:disable:next inverse_text_alignment
            label.textAlignment = .right
        } else {
            // swiftlint:disable:next natural_text_alignment
            label.textAlignment = .left
        }

        return label
    }()

    // MARK: - Initializers

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    public required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    func setupTimeZoneLabel(_ label: UILabel) {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
    }

    private func setupSubviews() {
        // Not every WPTimeZone has a time zone offset so wrapping content in UIStackView
        // to allow for dynamic resizing for these cases
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Constants.verticalSpacing

        let subtitleContainerView = UIView()
        subtitleContainerView.translatesAutoresizingMaskIntoConstraints = false
        subtitleContainerView.addSubview(leftSubtitle)
        subtitleContainerView.addSubview(rightSubtitle)

        let substack = UIStackView()
        substack.axis = .horizontal
        substack.alignment = .fill
        substack.spacing = Constants.subtitleHorizontalSpacing

        substack.addArrangedSubviews([leftSubtitle, rightSubtitle])
        stackView.addArrangedSubviews([titleLabel, substack])

        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdges(stackView, insets: UIEdgeInsets(
                top: Constants.verticalPadding,
                left: Constants.horizontalPadding,
                bottom: Constants.verticalPadding,
                right: Constants.horizontalPadding)
        )
    }
}

// MARK: - Constants

private extension TimeZoneTableViewCell {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 10
        static let verticalSpacing: CGFloat = 3
        static let subtitleHorizontalSpacing: CGFloat = 8
    }
}
