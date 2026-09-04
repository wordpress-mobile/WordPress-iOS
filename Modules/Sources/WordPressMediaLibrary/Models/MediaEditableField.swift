import Foundation

/// Editable metadata fields on the V2 detail screen. Each case maps to one
/// `MediaUpdateParams` slot. Alt-text visibility is gated at the
/// `MediaDetailViewModel.visibleEditableFields` layer, not on this enum.
enum MediaEditableField: Hashable {
    case title
    case caption
    case description
    case altText

    var localizedTitle: String {
        switch self {
        case .title: return Strings.detailFieldTitle
        case .caption: return Strings.detailFieldCaption
        case .description: return Strings.detailFieldDescription
        case .altText: return Strings.detailFieldAltText
        }
    }

    var placeholder: String {
        switch self {
        case .title: return Strings.detailFieldTitlePlaceholder
        case .caption: return Strings.detailFieldCaptionPlaceholder
        case .description: return Strings.detailFieldDescriptionPlaceholder
        case .altText: return Strings.detailFieldAltTextPlaceholder
        }
    }

    var hint: String {
        switch self {
        case .title: return Strings.detailFieldTitleHint
        case .caption: return Strings.detailFieldCaptionHint
        case .description: return Strings.detailFieldDescriptionHint
        case .altText: return Strings.detailFieldAltTextHint
        }
    }

    func value(in display: MediaDetailDisplayModel) -> String {
        switch self {
        case .title: return display.title ?? ""
        case .caption: return display.caption
        case .description: return display.description
        case .altText: return display.altText
        }
    }
}
