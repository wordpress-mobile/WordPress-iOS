import UIKit
import WordPressShared

/// A WPStyleGuide extension with styles and methods specific to the Posts feature.
///
extension WPStyleGuide {
    /// Styles `view` as a one-pixel separator and keeps its height in sync with the display scale.
    ///
    @MainActor
    class func applyBorderStyle(_ view: UIView) {
        view.updateConstraint(
            for: .height,
            withRelation: .equal,
            setConstant: .hairlineBorderWidth(traitCollection: view.traitCollection),
            setActive: true
        )
        view.backgroundColor = .separator
        view.registerForTraitChanges([UITraitDisplayScale.self]) { (view: UIView, _) in
            view.updateConstraint(
                for: .height,
                withRelation: .equal,
                setConstant: .hairlineBorderWidth(traitCollection: view.traitCollection),
                setActive: true
            )
        }
    }

    // MARK: - Font Styles

    static func configureLabelForRegularFontStyle(_ label: UILabel?) {
        guard let label else {
            return
        }

        WPStyleGuide.configureLabel(label, textStyle: .subheadline)
    }
}
