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

    static let preferredInsets = UIEdgeInsets(top: 4, left: 16, bottom: 8, right: 16)
}

extension ReaderStreamTitleView {
    static func makeForFollowing() -> ReaderStreamTitleView {
        let view = ReaderStreamTitleView()
        view.titleLabel.text = SharedStrings.Reader.recent
        view.detailsTextView.text = Strings.followingDetails
        return view
    }
}

final class ReaderNavigationCustomTitleView: UIView {
    let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        textLabel.font = WPStyleGuide.navigationBarStandardFont
        textLabel.alpha = 0

        // The label has to be a subview of the title view because
        // navigation bar doesn't seem to allow you to change the alpha
        // of `navigationItem.titleView` itself.
        addSubview(textLabel)
        textLabel.pinEdges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateAlpha(in scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        if offsetY < 16 {
            textLabel.alpha = 0
        } else {
            let alpha = (offsetY - 16) / 24
            textLabel.alpha = max(0, min(1, alpha))
        }
    }
}

private enum Strings {
    static let followingDetails = NSLocalizedString("reader.following.header.details", value: "Stay current with the blogs you've subscribed to.", comment: "Screen header details")
}
