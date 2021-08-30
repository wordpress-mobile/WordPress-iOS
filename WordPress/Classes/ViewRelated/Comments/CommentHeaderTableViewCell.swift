import UIKit

class CommentHeaderTableViewCell: UITableViewCell, Reusable {

    // MARK: Initialization

    required init(reuseIdentifier: String = CommentHeaderTableViewCell.defaultReuseID) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        configureStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Helpers

    private func configureStyle() {
        accessoryType = .disclosureIndicator

        textLabel?.font = WPStyleGuide.fontForTextStyle(.footnote)
        textLabel?.textColor = .textSubtle
        textLabel?.numberOfLines = 2

        detailTextLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline)
        detailTextLabel?.textColor = .text
        detailTextLabel?.numberOfLines = 1
    }

}
