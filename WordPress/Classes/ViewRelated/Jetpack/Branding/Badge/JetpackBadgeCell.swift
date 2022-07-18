import UIKit

class JetpackBadgeCell: UITableViewCell {

    private static let jetpackButtonTopInset: CGFloat = 30

    private lazy var badge: JetpackButton = {
        let button = JetpackButton(style: .badge)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private func setup() {
        // TODO: Change when the badge will display the modal
        badge.isUserInteractionEnabled = false

        selectionStyle = .none
        backgroundColor = .listBackground
        contentView.addSubview(badge)
        NSLayoutConstraint.activate([
            badge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            badge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.jetpackButtonTopInset),
            badge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
