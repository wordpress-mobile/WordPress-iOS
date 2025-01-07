import UIKit
import WordPressUI

/// A custom replacement for a navigation bar title view.
final class ReaderNavigationCustomTitleView: UIView {
    let textLabel = UILabel()
    let detailsLabel = UILabel()
    private lazy var stackView = UIStackView(axis: .vertical, alignment: .center, [textLabel, detailsLabel])

    override init(frame: CGRect) {
        super.init(frame: frame)

        textLabel.font = WPStyleGuide.navigationBarStandardFont

        detailsLabel.font = .preferredFont(forTextStyle: .footnote)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.isHidden = true

        addSubview(stackView)
        stackView.pinEdges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // The label has to be a subview of the title view because
    // navigation bar doesn't seem to allow you to change the alpha
    // of `navigationItem.titleView` itself.
    func updateAlpha(in scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        if offsetY < 16 {
            stackView.alpha = 0
        } else {
            let alpha = (offsetY - 16) / 24
            stackView.alpha = max(0, min(1, alpha))
        }
    }
}
