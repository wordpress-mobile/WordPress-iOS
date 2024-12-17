import UIKit
import WordPressUI

final class TextViewTableCell: UITableViewCell {
    let titleLabel = UILabel()
    let detailsView = UITextView.makeLabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        detailsView.textContainer.maximumNumberOfLines = 1
        detailsView.textContainer.lineBreakMode = .byTruncatingMiddle
        detailsView.textColor = .secondaryLabel
        detailsView.font = .preferredFont(forTextStyle: .body)
        detailsView.dataDetectorTypes = .link

        titleLabel.setContentCompressionResistancePriority(.init(900), for: .horizontal)

        let stackView = UIStackView(alignment: .firstBaseline, spacing: 3, [titleLabel, UIView(), detailsView])
        contentView.addSubview(stackView)
        stackView.pinEdges(to: contentView.layoutMarginsGuide)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
