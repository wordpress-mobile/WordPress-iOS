import UIKit
import WordPressUI

/// A custom replacement for a navigation bar title view.
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
