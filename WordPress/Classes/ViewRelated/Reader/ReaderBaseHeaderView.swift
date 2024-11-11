import UIKit
import WordPressUI

// A container view for stream headers.
class ReaderBaseHeaderView: UIView {
    let contentView = UIView()

    var isCompact: Bool = true {
        didSet {
            guard oldValue != isCompact else { return }
            didUpdateIsCompact(isCompact)
        }
    }

    private var contentViewConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        NSLayoutConstraint.deactivate(contentViewConstraints)
        contentViewConstraints = []

        let insets = Self.makeInsets(isCompact: isCompact)
        contentViewConstraints += contentView.pinEdges(.horizontal, to: isCompact ? self : readableContentGuide, insets: insets)
        contentViewConstraints += contentView.pinEdges(.vertical, insets: insets)

        super.updateConstraints()
    }

    func didUpdateIsCompact(_ isCompact: Bool) {
        setNeedsUpdateConstraints()
    }

    static func makeInsets(isCompact: Bool) -> UIEdgeInsets {
        UIEdgeInsets(
            top: 4, // To align with the large title on iPad
            left: isCompact ? 16 : ReaderStreamBaseCell.insets.left, // Align with the text in the feed
            bottom: 12, // Add spacing below
            right: 0
        )
    }
}
