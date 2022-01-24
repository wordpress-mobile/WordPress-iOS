import Foundation
import Gridicons
import Aztec

protocol FormatBarItemProvider {
    var iconImage: UIImage { get }
    var accessibilityIdentifier: String { get }
    var accessibilityLabel: String { get }
}

// MARK: - FormattingIdentifier
//
extension FormattingIdentifier: FormatBarItemProvider {
    var iconImage: UIImage {
        switch self {
        case .media:
            return .gridicon(.addOutline)
        case .p:
            return .gridicon(.heading)
        case .bold:
            return .gridicon(.bold)
        case .italic:
            return .gridicon(.italic)
        case .underline:
            return .gridicon(.underline)
        case .strikethrough:
            return .gridicon(.strikethrough)
        case .blockquote:
            return .gridicon(.quote)
        case .orderedlist:
            if layoutDirection == .leftToRight {
                return .gridicon(.listOrdered)
            } else {
                return .gridicon(.listOrderedRtl)
            }
        case .unorderedlist:
            return UIImage.gridicon(.listUnordered).imageFlippedForRightToLeftLayoutDirection()
        case .link:
            return .gridicon(.link)
        case .horizontalruler:
            return .gridicon(.minusSmall)
        case .sourcecode:
            return .gridicon(.code)
        case .more:
            return .gridicon(.readMore)
        case .header1:
            return .gridicon(.headingH1)
        case .header2:
            return .gridicon(.headingH2)
        case .header3:
            return .gridicon(.headingH3)
        case .header4:
            return .gridicon(.headingH4)
        case .header5:
            return .gridicon(.headingH5)
        case .header6:
            return .gridicon(.headingH6)
        case .code:
            return .gridicon(.posts)
        default:
            return .gridicon(.help)
        }
    }

    private var layoutDirection: UIUserInterfaceLayoutDirection {
        return UIView.userInterfaceLayoutDirection(for: .unspecified)
    }

    var accessibilityIdentifier: String {
        switch self {
        case .media:
            return "format_toolbar_insert_media"
        case .p:
            return "format_toolbar_select_paragraph_style"
        case .bold:
            return "format_toolbar_toggle_bold"
        case .italic:
            return "format_toolbar_toggle_italic"
        case .underline:
            return "format_toolbar_toggle_underline"
        case .strikethrough:
            return "format_toolbar_toggle_strikethrough"
        case .blockquote:
            return "format_toolbar_toggle_blockquote"
        case .orderedlist:
            return "format_toolbar_toggle_list_ordered"
        case .unorderedlist:
            return "format_toolbar_toggle_list_unordered"
        case .link:
            return "format_toolbar_insert_link"
        case .horizontalruler:
            return "format_toolbar_insert_horizontal_ruler"
        case .sourcecode:
            return "format_toolbar_toggle_html_view"
        case .more:
            return "format_toolbar_insert_more"
        case .header1:
            return "format_toolbar_toggle_h1"
        case .header2:
            return "format_toolbar_toggle_h2"
        case .header3:
            return "format_toolbar_toggle_h3"
        case .header4:
            return "format_toolbar_toggle_h4"
        case .header5:
            return "format_toolbar_toggle_h5"
        case .header6:
            return "format_toolbar_toggle_h6"
        case .code:
            return "format_toolbar_toggle_code"
        default:
            return ""
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .media:
            return AppLocalizedString("Insert media", comment: "Accessibility label for insert media button on formatting toolbar.")
        case .p:
            return AppLocalizedString("Select paragraph style", comment: "Accessibility label for selecting paragraph style button on formatting toolbar.")
        case .bold:
            return AppLocalizedString("Bold", comment: "Accessibility label for bold button on formatting toolbar.")
        case .italic:
            return AppLocalizedString("Italic", comment: "Accessibility label for italic button on formatting toolbar.")
        case .underline:
            return AppLocalizedString("Underline", comment: "Accessibility label for underline button on formatting toolbar.")
        case .strikethrough:
            return AppLocalizedString("Strike Through", comment: "Accessibility label for strikethrough button on formatting toolbar.")
        case .blockquote:
            return AppLocalizedString("Block Quote", comment: "Accessibility label for block quote button on formatting toolbar.")
        case .orderedlist:
            return AppLocalizedString("Ordered List", comment: "Accessibility label for Ordered list button on formatting toolbar.")
        case .unorderedlist:
            return AppLocalizedString("Unordered List", comment: "Accessibility label for unordered list button on formatting toolbar.")
        case .link:
            return AppLocalizedString("Insert Link", comment: "Accessibility label for insert link button on formatting toolbar.")
        case .horizontalruler:
            return AppLocalizedString("Insert Horizontal Ruler", comment: "Accessibility label for insert horizontal ruler button on formatting toolbar.")
        case .sourcecode:
            return AppLocalizedString("HTML", comment: "Accessibility label for HTML button on formatting toolbar.")
        case .more:
            return AppLocalizedString("More", comment: "Accessibility label for the More button on formatting toolbar.")
        case .header1:
            return AppLocalizedString("Header 1", comment: "Accessibility label for selecting h1 paragraph style button on the formatting toolbar.")
        case .header2:
            return AppLocalizedString("Header 2", comment: "Accessibility label for selecting h2 paragraph style button on the formatting toolbar.")
        case .header3:
            return AppLocalizedString("Header 3", comment: "Accessibility label for selecting h3 paragraph style button on the formatting toolbar.")
        case .header4:
            return AppLocalizedString("Header 4", comment: "Accessibility label for selecting h4 paragraph style button on the formatting toolbar.")
        case .header5:
            return AppLocalizedString("Header 5", comment: "Accessibility label for selecting h5 paragraph style button on the formatting toolbar.")
        case .header6:
            return AppLocalizedString("Header 6", comment: "Accessibility label for selecting h6 paragraph style button on the formatting toolbar.")
        case .code:
            return AppLocalizedString("Code", comment: "Accessibility label for selecting code style button on the formatting toolbar.")
        default:
            return ""
        }
    }
}

enum FormatBarMediaIdentifier: String {
    case deviceLibrary
    case camera
    case mediaLibrary
    case otherApplications
}

extension FormatBarMediaIdentifier: FormatBarItemProvider {
    var iconImage: UIImage {
        switch self {
        case .deviceLibrary:
            return .gridicon(.imageMultiple)
        case .camera:
            return .gridicon(.camera)
        case .mediaLibrary:
            return .gridicon(.mySites)
        case .otherApplications:
            return .gridicon(.ellipsis)
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .deviceLibrary:
            return "format_toolbar_media_photo_library"
        case .camera:
            return "format_toolbar_media_camera"
        case .mediaLibrary:
            return "format_toolbar_media_wordpress_media_library"
        case .otherApplications:
            return "format_toolbar_media_other_applications"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .deviceLibrary:
            return AppLocalizedString("Photo Library", comment: "Accessibility label for selecting an image or video from the device's photo library on formatting toolbar.")
        case .camera:
            return AppLocalizedString("Camera", comment: "Accessibility label for taking an image or video with the camera on formatting toolbar.")
        case .mediaLibrary:
            return AppLocalizedString("WordPress Media Library", comment: "Accessibility label for selecting an image or video from the user's WordPress media library on formatting toolbar.")
        case .otherApplications:
            return AppLocalizedString("Other Apps", comment: "Accessibility label for selecting an image or video from other applications on formatting toolbar.")
        }
    }
}
