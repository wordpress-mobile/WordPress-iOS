import UIKit

class TimeZoneTableViewCell: WPTableViewCell {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        label.font = UIFont(descriptor: fontDescriptor, size: fontDescriptor.pointSize)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label

        if label.effectiveUserInterfaceLayoutDirection == .leftToRight {
            // swiftlint:disable:next natural_text_alignment
            label.textAlignment = .left
        } else {
            // swiftlint:disable:next inverse_text_alignment
            label.textAlignment = .right
        }
        return label
    }()

    let leftSubtitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1)
        label.font = UIFont(descriptor: fontDescriptor, size: fontDescriptor.pointSize)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel

        if label.effectiveUserInterfaceLayoutDirection == .leftToRight {
            // swiftlint:disable:next natural_text_alignment
            label.textAlignment = .left
        } else {
            // swiftlint:disable:next inverse_text_alignment
            label.textAlignment = .right
        }

        return label
    }()

    let rightSubtitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1)
        label.font = UIFont(descriptor: fontDescriptor, size: fontDescriptor.pointSize)
        label.adjustsFontForContentSizeCategory = true
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

    private func setupSubviews() {
        // Not every WPTimeZone has a time zone offset so wrapping content in UIStackView
        // to allow for dynamic resizing for these cases
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill

        let subtitleContainerView = UIView()
        subtitleContainerView.translatesAutoresizingMaskIntoConstraints = false
        subtitleContainerView.addSubview(leftSubtitle)
        subtitleContainerView.addSubview(rightSubtitle)

        stackView.addArrangedSubviews([titleLabel, subtitleContainerView])

        configureConstraints(subtitleContainerView: subtitleContainerView)

        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdges(stackView, insets: UIEdgeInsets(
                top: Constants.topPadding,
                left: Constants.leadingTrailingPadding,
                bottom: Constants.bottomPadding,
                right: Constants.leadingTrailingPadding)
        )
    }

    private func configureConstraints(subtitleContainerView: UIView) {
        NSLayoutConstraint.activate([
            // contentView
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            // leftSubtitle
            leftSubtitle.topAnchor.constraint(equalTo: subtitleContainerView.topAnchor, constant: Constants.subtitleTopPadding),
            leftSubtitle.leadingAnchor.constraint(equalTo: subtitleContainerView.leadingAnchor),
            leftSubtitle.bottomAnchor.constraint(equalTo: subtitleContainerView.bottomAnchor),
            // rightSubtitle
            rightSubtitle.centerYAnchor.constraint(equalTo: leftSubtitle.centerYAnchor),
            rightSubtitle.leadingAnchor.constraint(greaterThanOrEqualTo: leftSubtitle.trailingAnchor, constant: Constants.subtitleHorizSpacingBetweenLabels),
            rightSubtitle.trailingAnchor.constraint(equalTo: subtitleContainerView.trailingAnchor)
        ])
    }
}


// MARK: - Constants

private extension TimeZoneTableViewCell {
    enum Constants {
        static let leadingTrailingPadding: CGFloat = 16
        static let topPadding: CGFloat = 12
        static let bottomPadding: CGFloat = 10
        static let subtitleTopPadding: CGFloat = 3
        static let subtitleHorizSpacingBetweenLabels: CGFloat = 8
    }
}
