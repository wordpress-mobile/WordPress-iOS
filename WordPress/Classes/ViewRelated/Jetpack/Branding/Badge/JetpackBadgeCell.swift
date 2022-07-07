import UIKit

@objc class JetpackBadgeCell: UITableViewCell {

    @objc func configure() {
        let jetpackBadgeButton = JetpackButton.makeDefaultBadge()
        contentView.addSubview(jetpackBadgeButton)
        backgroundColor = .listBackground
        NSLayoutConstraint.activate([
            jetpackBadgeButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            jetpackBadgeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
