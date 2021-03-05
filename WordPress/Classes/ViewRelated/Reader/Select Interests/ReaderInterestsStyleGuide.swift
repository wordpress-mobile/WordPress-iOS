import Foundation
import WordPressShared

class ReaderInterestsStyleGuide {
    // MARK: - View Styles
    public class func applyTitleLabelStyles(label: UILabel) {
        label.font = WPStyleGuide.serifFontForTextStyle(.largeTitle, fontWeight: .medium)
        label.textColor = .text
    }

    public class func applySubtitleLabelStyles(label: UILabel) {
        label.font = WPStyleGuide.fontForTextStyle(.body)
        label.textColor = .text
    }

    // MARK: - Collection View Cell Styles
    public class var cellLabelTitleFont: UIFont {
        return WPStyleGuide.fontForTextStyle(.body)
    }

    public class func applyCellLabelStyle(label: UILabel, isSelected: Bool) {
        label.font = WPStyleGuide.fontForTextStyle(.body)
        label.textColor = isSelected ? .white : .text
        label.backgroundColor = isSelected ? .muriel(color: .primary, .shade40) : .quaternaryBackground
    }

    // MARK: - Compact Collection View Cell Styles
    public class var compactCellLabelTitleFont: UIFont {
        return WPStyleGuide.fontForTextStyle(.footnote)
    }

    public class func applyCompactCellLabelStyle(label: UILabel) {
        label.font = Self.compactCellLabelTitleFont
        label.textColor = .text
        label.backgroundColor = .quaternaryBackground
    }

    // MARK: - Next Button
    public class var buttonContainerViewBackgroundColor: UIColor {
        if #available(iOS 13, *) {
            return .tertiarySystemBackground
        }

        return .white
    }

    public class func applyNextButtonStyle(button: FancyButton) {
        let disabledBackgroundColor: UIColor
        let titleColor: UIColor

        disabledBackgroundColor = UIColor(light: .systemGray4, dark: .systemGray3)
        titleColor = .textTertiary

        button.disabledTitleColor = titleColor
        button.disabledBorderColor = disabledBackgroundColor
        button.disabledBackgroundColor = disabledBackgroundColor
    }

    // MARK: - Loading
    public class func applyLoadingLabelStyles(label: UILabel) {
        label.font = WPStyleGuide.fontForTextStyle(.body)
        label.textColor = .textSubtle
    }

    public class func applyActivityIndicatorStyles(indicator: UIActivityIndicatorView) {
        indicator.color = UIColor(light: .black, dark: .white)
    }
}

class ReaderSuggestedTopicsStyleGuide {
    /// The array of colors from the designs
    /// Note: I am explictly using the MurielColor names instead of using the semantic ones
    ///       since these are explicit and not semantic colors.
    static let colors: [TopicStyle] = [
        // Green
        .init(textColor: .init(colorName: .green, section: .text),
              backgroundColor: .init(colorName: .green, section: .background),
              borderColor: .init(colorName: .green, section: .border)),

        // Purple
        .init(textColor: .init(colorName: .purple, section: .text),
              backgroundColor: .init(colorName: .purple, section: .background),
              borderColor: .init(colorName: .purple, section: .border)),


        // Yellow
        .init(textColor: .init(colorName: .yellow, section: .text),
              backgroundColor: .init(colorName: .yellow, section: .background),
              borderColor: .init(colorName: .yellow, section: .border)),

        // Orange
        .init(textColor: .init(colorName: .orange, section: .text),
              backgroundColor: .init(colorName: .orange, section: .background),
              borderColor: .init(colorName: .orange, section: .border)),
    ]

    private class func topicStyle(for index: Int) -> TopicStyle {
        let colorCount = Self.colors.count

        // Safety feature if for some reason the count of returned topics ever increases past 4 we will
        // loop through the list colors again. 
        return Self.colors[index % colorCount]
    }

    public static var topicFont: UIFont = WPStyleGuide.fontForTextStyle(.footnote)

    public class func applySuggestedTopicStyle(label: UILabel, with index: Int) {
        let style = Self.topicStyle(for: index)

        label.font = Self.topicFont
        label.textColor = style.textColor.color()

        label.layer.borderColor = style.borderColor.color().cgColor
        label.layer.borderWidth = .hairlineBorderWidth
        label.layer.backgroundColor = style.backgroundColor.color().cgColor
    }

    // MARK: - Color Representation
    struct TopicStyle {
        let textColor: TopicColor
        let backgroundColor: TopicColor
        let borderColor: TopicColor

        struct TopicColor {
            enum StyleSection {
                case text, background, border
            }

            let colorName: MurielColorName
            let section: StyleSection

            func color() -> UIColor {
                let lightShade: MurielColorShade
                let darkShade: MurielColorShade

                switch section {
                    case .text:
                        lightShade = .shade50
                        darkShade = .shade40

                    case .border:
                        lightShade = .shade5
                        darkShade = .shade100

                    case .background:
                        lightShade = .shade0
                        darkShade = .shade90
                }

                return UIColor(light: .muriel(color: MurielColor(name: colorName, shade: lightShade)),
                               dark: .muriel(color: MurielColor(name: colorName, shade: darkShade)))
            }
        }
    }
}
