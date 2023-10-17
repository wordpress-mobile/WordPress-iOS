import UIKit

final class PostSearchTokenTableCell: UITableViewCell {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private lazy var stackView = UIStackView(arrangedSubviews: [
        iconView, titleLabel, UIView()
    ])

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        iconView.tintColor = .secondaryLabel

        stackView.spacing = 8
        stackView.alignment = .center
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdges(stackView)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    func configure(with token: any PostSearchToken, isLast: Bool) {
        iconView.image = token.icon
        titleLabel.text = token.value
        stackView.layoutMargins.bottom = isLast ? 16 : 8
    }
}
