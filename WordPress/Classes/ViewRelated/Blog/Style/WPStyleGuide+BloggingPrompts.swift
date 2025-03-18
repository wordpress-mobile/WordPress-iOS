import UIKit
import WordPressUI

/// This class groups styles used by blogging prompts
///
extension WPStyleGuide {
    public struct BloggingPrompts {
        static let promptContentFont = AppStyleGuide.prominentFont(textStyle: .headline, weight: .semibold)
        static let answerInfoButtonFont = WPStyleGuide.fontForTextStyle(.caption1)
        static let answerInfoButtonColor = UIColor.secondaryLabel
        static let buttonTitleFont = WPStyleGuide.fontForTextStyle(.subheadline)
        static let buttonTitleColor = UIAppColor.primary
        static let answeredLabelColor = UIAppColor.green(.shade50)
    }
}
