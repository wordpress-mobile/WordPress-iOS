import UIKit

class CommentHeaderTableViewCell: UITableViewCell, Reusable {

    // MARK: Initialization

    required init() {
        super.init(style: .subtitle, reuseIdentifier: Self.defaultReuseID)
        configureStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Helpers

    private typealias Style = WPStyleGuide.CommentDetail.Header

    private func configureStyle() {
        accessoryType = .disclosureIndicator

        textLabel?.font = Style.font
        textLabel?.textColor = Style.textColor
        textLabel?.numberOfLines = 2

        detailTextLabel?.font = Style.detailFont
        detailTextLabel?.textColor = Style.detailTextColor
        detailTextLabel?.numberOfLines = 1
    }

}
