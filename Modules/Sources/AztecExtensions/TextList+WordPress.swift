import Foundation
import Aztec
import UIKit
import WordPressShared

// MARK: - TextList.Style
//
extension TextList.Style {

    public var formattingIdentifier: FormattingIdentifier {
        switch self {
        case .ordered:   return FormattingIdentifier.orderedlist
        case .unordered: return FormattingIdentifier.unorderedlist
        @unknown default: fatalError()
        }
    }

    public var description: String {
        switch self {
        case .ordered: return "Ordered List"
        case .unordered: return "Unordered List"
        @unknown default: fatalError()
        }
    }

    public var accessibilityLabel: String {
        switch self {
        case .ordered: return AppLocalizedString("Toggles the ordered list style", comment: "Accessibility Identifier for the Aztec Ordered List Style.")
        case .unordered: return AppLocalizedString("Toggles the unordered list style", comment: "Accessibility Identifier for the Aztec Unordered List Style")
        @unknown default: fatalError()
        }
    }

    public var iconImage: UIImage? {
        return formattingIdentifier.iconImage
    }
}
