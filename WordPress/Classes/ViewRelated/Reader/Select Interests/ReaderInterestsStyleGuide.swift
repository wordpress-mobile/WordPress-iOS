import Foundation
import WordPressShared
import WordPressUI

class ReaderInterestsStyleGuide {

    struct Metrics {
        let interestsLabelMargin: CGFloat
        let cellCornerRadius: CGFloat
        let cellSpacing: CGFloat
        let cellHeight: CGFloat
        let maxCellWidthMultiplier: CGFloat
        let borderWidth: CGFloat
        let borderColor: UIColor

        static let latest = Metrics(
            interestsLabelMargin: 16.0,
            cellCornerRadius: 5.0,
            cellSpacing: 8.0,
            cellHeight: 34.0,
            maxCellWidthMultiplier: 0.8,
            borderWidth: 1.0,
            borderColor: .separator
        )
    }

    // MARK: - View Styles
    public class func applyTitleLabelStyles(label: UILabel) {
        label.font = .preferredFont(forTextStyle: .title1).bold()
        label.textColor = .label
    }

    public class func applySubtitleLabelStyles(label: UILabel) {
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
    }

    // MARK: - Collection View Cell Styles
    public class var cellLabelTitleFont: UIFont {
        .preferredFont(forTextStyle: .subheadline)
    }

    public class func applyCellLabelStyle(label: UILabel, isSelected: Bool) {
        label.font = cellLabelTitleFont
        label.textColor = isSelected ? UIColor.systemBackground : UIColor.label
        label.backgroundColor = isSelected ? UIColor.label : UIColor.systemBackground
    }

    // MARK: - Compact Collection View Cell Styles
    public class var compactCellLabelTitleFont: UIFont {
        .preferredFont(forTextStyle: .footnote)
    }

    public class func applyCompactCellLabelStyle(label: UILabel) {
        label.font = Self.compactCellLabelTitleFont
        label.textColor = .label
        label.backgroundColor = .clear
    }

    // MARK: - Next Button
    public static let buttonContainerViewBackgroundColor: UIColor = .systemBackground

    public class func applyNextButtonStyle(button: UIButton) {
        button.configuration = {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 12.0, leading: 0.0, bottom: 12.0, trailing: 0.0)
            config.titleTextAttributesTransformer = .transformer(with: .preferredFont(forTextStyle: .body).semibold())
            return config
        }()
        button.setTitleColor(.systemBackground, for: .normal)
        button.setTitleColor(.systemBackground, for: .disabled)
        button.setTitleColor(.systemBackground.withAlphaComponent(0.7), for: .highlighted)
        button.backgroundColor = .label
        button.layer.cornerRadius = 5.0
    }

    // MARK: - Loading
    public class func applyLoadingLabelStyles(label: UILabel) {
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
    }

    public class func applyActivityIndicatorStyles(indicator: UIActivityIndicatorView) {
        indicator.color = UIColor(light: .black, dark: .white)
    }
}
