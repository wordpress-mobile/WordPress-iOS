import UIKit
import WordPressUI

/// A Reader stream header with a large title and a description.
final class ReaderTitleView: UIView {
    let titleLabel = UILabel()
    let detailsTextView = UITextView.makeLabel()

    init() {
        super.init(frame: .zero)

        titleLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle).withWeight(.bold)
        titleLabel.adjustsFontForContentSizeCategory = true

        detailsTextView.font = UIFont.preferredFont(forTextStyle: .subheadline)
        detailsTextView.textColor = .secondaryLabel
        detailsTextView.adjustsFontForContentSizeCategory = true

        let stackView = UIStackView(axis: .vertical, alignment: .leading, [titleLabel, detailsTextView])
        addSubview(stackView)
        stackView.pinEdges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
