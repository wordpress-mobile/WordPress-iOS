import UIKit

final class PostSearchTokenTableCell: UITableViewCell {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private lazy var stackView = UIStackView(arrangedSubviews: [
        iconView, titleLabel, UIView()
    ])
    let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        iconView.tintColor = .secondaryLabel

        separator.backgroundColor = .separator

        stackView.spacing = 8
        stackView.alignment = .center
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdges(stackView)

        // The native one doesn't quite work the way we need if there is only one result
        contentView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    func configure(with token: any PostSearchToken, isLast: Bool) {
        iconView.image = token.icon
        titleLabel.text = token.value
        stackView.layoutMargins.bottom = isLast ? 14 : 8
        separator.isHidden = !isLast
    }
}
