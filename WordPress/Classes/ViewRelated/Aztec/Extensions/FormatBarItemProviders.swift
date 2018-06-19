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
            return Gridicon.iconOfType(.addOutline)
        case .p:
            return Gridicon.iconOfType(.heading)
        case .bold:
            return Gridicon.iconOfType(.bold)
        case .italic:
            return Gridicon.iconOfType(.italic)
        case .underline:
            return Gridicon.iconOfType(.underline)
        case .strikethrough:
            return Gridicon.iconOfType(.strikethrough)
        case .blockquote:
            return Gridicon.iconOfType(.quote)
        case .orderedlist:
            if layoutDirection == .leftToRight {
                return Gridicon.iconOfType(.listOrdered)
            } else {
                return Gridicon.iconOfType(.listOrderedRTL)
            }
        case .unorderedlist:
            return Gridicon.iconOfType(.listUnordered).imageFlippedForRightToLeftLayoutDirection()
        case .link:
            return Gridicon.iconOfType(.link)
        case .horizontalruler:
            return Gridicon.iconOfType(.minusSmall)
        case .sourcecode:
            return Gridicon.iconOfType(.code)
        case .more:
            return Gridicon.iconOfType(.readMore)
        case .header1:
            return Gridicon.iconOfType(.headingH1)
        case .header2:
            return Gridicon.iconOfType(.headingH2)
        case .header3:
            return Gridicon.iconOfType(.headingH3)
        case .header4:
            return Gridicon.iconOfType(.headingH4)
        case .header5:
            return Gridicon.iconOfType(.headingH5)
        case .header6:
            return Gridicon.iconOfType(.headingH6)
        case .code:
            return Gridicon.iconOfType(.posts)
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
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .media:
            return NSLocalizedString("Insert media", comment: "Accessibility label for insert media button on formatting toolbar.")
        case .p:
            return NSLocalizedString("Select paragraph style", comment: "Accessibility label for selecting paragraph style button on formatting toolbar.")
        case .bold:
            return NSLocalizedString("Bold", comment: "Accessibility label for bold button on formatting toolbar.")
        case .italic:
            return NSLocalizedString("Italic", comment: "Accessibility label for italic button on formatting toolbar.")
        case .underline:
            return NSLocalizedString("Underline", comment: "Accessibility label for underline button on formatting toolbar.")
        case .strikethrough:
            return NSLocalizedString("Strike Through", comment: "Accessibility label for strikethrough button on formatting toolbar.")
        case .blockquote:
            return NSLocalizedString("Block Quote", comment: "Accessibility label for block quote button on formatting toolbar.")
        case .orderedlist:
            return NSLocalizedString("Ordered List", comment: "Accessibility label for Ordered list button on formatting toolbar.")
        case .unorderedlist:
            return NSLocalizedString("Unordered List", comment: "Accessibility label for unordered list button on formatting toolbar.")
        case .link:
            return NSLocalizedString("Insert Link", comment: "Accessibility label for insert link button on formatting toolbar.")
        case .horizontalruler:
            return NSLocalizedString("Insert Horizontal Ruler", comment: "Accessibility label for insert horizontal ruler button on formatting toolbar.")
        case .sourcecode:
            return NSLocalizedString("HTML", comment: "Accessibility label for HTML button on formatting toolbar.")
        case .more:
            return NSLocalizedString("More", comment: "Accessibility label for the More button on formatting toolbar.")
        case .header1:
            return NSLocalizedString("Header 1", comment: "Accessibility label for selecting h1 paragraph style button on the formatting toolbar.")
        case .header2:
            return NSLocalizedString("Header 2", comment: "Accessibility label for selecting h2 paragraph style button on the formatting toolbar.")
        case .header3:
            return NSLocalizedString("Header 3", comment: "Accessibility label for selecting h3 paragraph style button on the formatting toolbar.")
        case .header4:
            return NSLocalizedString("Header 4", comment: "Accessibility label for selecting h4 paragraph style button on the formatting toolbar.")
        case .header5:
            return NSLocalizedString("Header 5", comment: "Accessibility label for selecting h5 paragraph style button on the formatting toolbar.")
        case .header6:
            return NSLocalizedString("Header 6", comment: "Accessibility label for selecting h6 paragraph style button on the formatting toolbar.")
        case .code:
            return NSLocalizedString("Code", comment: "Accessibility label for selecting code style button on the formatting toolbar.")
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
            return Gridicon.iconOfType(.imageMultiple)
        case .camera:
            return Gridicon.iconOfType(.camera)
        case .mediaLibrary:
            return Gridicon.iconOfType(.mySites)
        case .otherApplications:
            return Gridicon.iconOfType(.ellipsis)
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
            return NSLocalizedString("Photo Library", comment: "Accessibility label for selecting an image or video from the device's photo library on formatting toolbar.")
        case .camera:
            return NSLocalizedString("Camera", comment: "Accessibility label for taking an image or video with the camera on formatting toolbar.")
        case .mediaLibrary:
            return NSLocalizedString("WordPress Media Library", comment: "Accessibility label for selecting an image or video from the user's WordPress media library on formatting toolbar.")
        case .otherApplications:
            return NSLocalizedString("Other Apps", comment: "Accessibility label for selecting an image or video from other applications on formatting toolbar.")
        }
    }
}
