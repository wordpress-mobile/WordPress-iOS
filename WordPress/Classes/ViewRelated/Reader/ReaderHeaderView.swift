import UIKit
import WordPressUI

final class ReaderHeaderView: ReaderBaseHeaderView {
    let titleView = ReaderTitleView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(titleView)
        titleView.pinEdges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ReaderHeaderView {
    static func makeForFollowing() -> ReaderHeaderView {
        let view = ReaderHeaderView()
        view.titleView.titleLabel.text = SharedStrings.Reader.recent
        view.titleView.detailsTextView.text = Strings.followingDetails
        return view
    }
}

private enum Strings {
    static let followingDetails = NSLocalizedString("reader.following.header.details", value: "Stay current with the blogs you've subscribed to.", comment: "Screen header details")
}
