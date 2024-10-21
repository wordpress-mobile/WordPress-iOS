import UIKit
import WordPressUI

/// A Reader stream header with a large title and a description.
final class ReaderStreamTitleView: UIView {
    let titleLabel = UILabel()
    let detailsTextView = UITextView.makeLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle).withWeight(.bold)
        detailsTextView.font = UIFont.preferredFont(forTextStyle: .subheadline)
        detailsTextView.textColor = .secondaryLabel

        let stackView = UIStackView(axis: .vertical, alignment: .leading, [titleLabel, detailsTextView])
        addSubview(stackView)
        stackView.pinEdges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
