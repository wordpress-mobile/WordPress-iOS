import UIKit
import WordPressShared

/// A WPStyleGuide extension with styles and methods specific to the Posts feature.
///
extension WPStyleGuide {

    class func applyPostCardStyle(_ cell: UITableViewCell) {
        cell.backgroundColor = .systemGroupedBackground
        cell.contentView.backgroundColor = .systemGroupedBackground
    }

    class func applyBorderStyle(_ view: UIView) {
        view.updateConstraint(for: .height, withRelation: .equal, setConstant: .hairlineBorderWidth, setActive: true)
        view.backgroundColor = .separator
    }

    // MARK: - Font Styles

    static func configureLabelForRegularFontStyle(_ label: UILabel?) {
        guard let label = label else {
            return
        }

        WPStyleGuide.configureLabel(label, textStyle: .subheadline)
    }

}
