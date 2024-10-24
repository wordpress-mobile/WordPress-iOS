import UIKit
import WordPressUI

/// A Reader stream header with a large title and a description.
final class ReaderStreamTitleView: UIView {
    let titleLabel = UILabel()
    let detailsTextView = UITextView.makeLabel()

    init(insets: UIEdgeInsets? = ReaderStreamTitleView.preferredInsets) {
        super.init(frame: .zero)

        titleLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle).withWeight(.bold)
        detailsTextView.font = UIFont.preferredFont(forTextStyle: .subheadline)
        detailsTextView.textColor = .secondaryLabel

        let stackView = UIStackView(axis: .vertical, alignment: .leading, insets: insets, [titleLabel, detailsTextView])
        addSubview(stackView)
        stackView.pinEdges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static let preferredInsets = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)
}

extension ReaderStreamTitleView {
    static func makeForFollowing() -> ReaderStreamTitleView {
        let view = ReaderStreamTitleView()
        view.titleLabel.text = Strings.followingTitle
        view.detailsTextView.text = Strings.followingDetails
        return view
    }
}

private enum Strings {
    static let followingTitle = NSLocalizedString("reader.following.header.title", value: "Following", comment: "Screen header title")
    static let followingDetails = NSLocalizedString("reader.following.header.details", value: "Stay current with the blogs you've subscribed to", comment: "Screen header details")
}
