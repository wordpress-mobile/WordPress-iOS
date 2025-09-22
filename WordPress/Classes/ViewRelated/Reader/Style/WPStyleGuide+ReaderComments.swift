import UIKit
import WordPressShared
import WordPressUI

extension WPStyleGuide {
    public struct ReaderCommentsNotificationSheet {
        static let textColor = UIColor.label
        static let descriptionLabelFont = fontForTextStyle(.subheadline)
        static let switchLabelFont = fontForTextStyle(.body)
        static let buttonTitleLabelFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        static let buttonBorderColor = UIColor.systemGray3
        static let switchOnTintColor = UIColor.systemGreen
        static let switchInProgressTintColor = UIAppColor.primary
    }
}
