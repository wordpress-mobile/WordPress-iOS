import UIKit

class JetpackBadgeCell: UITableViewCell {

    static let reuseIdentifier = "JetpackBadgeCell"

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
        separatorInset = UIEdgeInsets(top: 0, left: contentView.frame.width, bottom: 0, right: 0)
        backgroundColor = .listBackground
        contentView.addSubview(badge)
        contentView.pinSubviewAtCenter(badge)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
