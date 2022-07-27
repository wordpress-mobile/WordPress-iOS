import Foundation
import Aztec


// MARK: - TextList.Style
//
extension TextList.Style {

    var formattingIdentifier: FormattingIdentifier {
        switch self {
        case .ordered:   return FormattingIdentifier.orderedlist
        case .unordered: return FormattingIdentifier.unorderedlist
        }
    }

    var description: String {
        switch self {
        case .ordered: return "Ordered List"
        case .unordered: return "Unordered List"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .ordered: return AppLocalizedString("Toggles the ordered list style", comment: "Accessibility Identifier for the Aztec Ordered List Style.")
        case .unordered: return AppLocalizedString("Toggles the unordered list style", comment: "Accessibility Identifier for the Aztec Unordered List Style")
        }
    }

    var iconImage: UIImage? {
        return formattingIdentifier.iconImage
    }
}
