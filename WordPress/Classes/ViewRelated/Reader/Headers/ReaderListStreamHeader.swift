import UIKit
import WordPressShared
import WordPressUI

final class ReaderListStreamHeader: ReaderBaseHeaderView, ReaderStreamHeader {
    private let titleView = ReaderTitleView()

    // Required by ReaderStreamHeader protocol.
    public weak var delegate: ReaderStreamHeaderDelegate?

    // MARK: - Lifecycle Methods

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(titleView)
        titleView.pinEdges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    @objc public func configureHeader(_ topic: ReaderAbstractTopic) {
        wpAssert(topic.isKind(of: ReaderListTopic.self))

        let listTopic = topic as! ReaderListTopic

        titleView.titleLabel.text = topic.title
        titleView.detailsTextView.text = listTopic.owner
        titleView.detailsTextView.isHidden = listTopic.owner.isEmpty
    }
}
