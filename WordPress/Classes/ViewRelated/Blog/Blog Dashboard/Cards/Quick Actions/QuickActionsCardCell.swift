import UIKit
import WordPressShared

class QuickActionsCardCell: UICollectionViewCell, Reusable {

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [iconView, titleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Constants.stackViewSpacing
        return stackView
    }()

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        imageView.tintColor = .listIcon
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = WPStyleGuide.serifFontForTextStyle(.body, fontWeight: .semibold)
        label.textColor = .text
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    func configure(title: String) {
        titleLabel.text =  title
    }
}

extension QuickActionsCardCell {

    private func setup() {
        contentView.backgroundColor = .listForeground
        contentView.layer.cornerRadius = Constants.contentViewCornerRadius

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.leadingPadding),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.trailingPadding),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.verticalPadding),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.verticalPadding)
        ])
    }
}

extension QuickActionsCardCell {

    private enum Constants {
        static let contentViewCornerRadius = 8.0
        static let stackViewSpacing = 16.0
        static let leadingPadding = 16.0
        static let trailingPadding = 24.0
        static let verticalPadding = 12.0
    }
}
