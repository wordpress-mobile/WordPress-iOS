import UIKit

@objc class JetpackBadgeCell: UITableViewCell {

    private lazy var jetpackBadgeButton: JetpackButton = {
        let jetpackBadgeButton = JetpackButton(style: .badge)
        jetpackBadgeButton.translatesAutoresizingMaskIntoConstraints = false
        return jetpackBadgeButton
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .listBackground
        contentView.addSubview(jetpackBadgeButton)
        NSLayoutConstraint.activate([
            jetpackBadgeButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            jetpackBadgeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
