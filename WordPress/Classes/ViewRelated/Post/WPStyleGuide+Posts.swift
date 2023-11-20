import UIKit
import WordPressShared

/// A WPStyleGuide extension with styles and methods specific to the Posts feature.
///
extension WPStyleGuide {

    class func applyPostCardStyle(_ cell: UITableViewCell) {
        cell.backgroundColor = .listBackground
        cell.contentView.backgroundColor = .listBackground
    }

    class func applyPostTitleStyle(_ label: UILabel) {
        label.textColor = .text
    }

    class func applyPostProgressViewStyle(_ progressView: UIProgressView) {
        progressView.trackTintColor = .divider
        progressView.progressTintColor = .primary
        progressView.tintColor = .primary
    }

    class func applyBorderStyle(_ view: UIView) {
        view.updateConstraint(for: .height, withRelation: .equal, setConstant: .hairlineBorderWidth, setActive: true)
        view.backgroundColor = .divider
    }

    // MARK: - Font Styles

    static func configureLabelForRegularFontStyle(_ label: UILabel?) {
        guard let label = label else {
            return
        }

        WPStyleGuide.configureLabel(label, textStyle: .subheadline)
    }

}
