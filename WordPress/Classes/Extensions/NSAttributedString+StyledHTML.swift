import UIKit

extension NSAttributedString {
    /// Creates an `NSAttributedString` with the styles defined in `attributes` applied.
    /// - parameter htmlString: The string to be styled. This can contain HTML
    ///    tags to markup sections of the text to style, but should not be wrapped
    ///    with `<html>`, `<body>` or `<p>` tags. See `HTMLAttributeType` for supported tags.
    /// - parameter attributes: A collection of style attributes to apply to `htmlString`.
    ///    See `HTMLAttributeType` for supported attributes. To set text alignment,
    ///    add an `NSParagraphStyle` to the `BodyAttribute` type, using the key
    ///    `NSParagraphStyleAttributeName`.
    ///
    /// - note:
    ///    - Font sizes will be interpreted as pixel sizes, not points.
    ///    - Font family / name will be discarded (generated strings will always
    ///      use the system font), but font size and bold / italic information
    ///      will be applied.
    ///
    class func attributedStringWithHTML(_ htmlString: String, attributes: StyledHTMLAttributes?) -> NSAttributedString {
        let styles = styleTagTextForAttributes(attributes)
        let styledString = styles + htmlString
        guard let data = styledString.data(using: .utf8),
            let attributedString = try? NSMutableAttributedString(
            data: data,
            options: [ .documentType: NSAttributedString.DocumentType.html.rawValue, .characterEncoding: String.Encoding.utf8.rawValue ],
            documentAttributes: nil) else {
                // if creating the html-ed string fails (and it has, thus this change) we return the string without any styling
                return NSAttributedString(string: htmlString)
        }

        // We can't apply text alignment through CSS, as we need to add a paragraph
        // style to set paragraph spacing (which will override any text alignment
        // set via CSS). So we'll look for a paragraph style specified for the
        // body of the text, so we can copy it use its text alignment.
        let paragraphStyle = NSMutableParagraphStyle()
        if let attributes = attributes,
            let bodyAttributes = attributes[.BodyAttribute],
            let pStyle = bodyAttributes[.paragraphStyle] as? NSParagraphStyle {
                paragraphStyle.setParagraphStyle(pStyle)
        }

        // Remove extra padding at the top and bottom of the text.
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.paragraphSpacingBefore = 0

        attributedString.addAttribute(.paragraphStyle,
                                      value: paragraphStyle,
                                      range: NSMakeRange(0, attributedString.string.count - 1))

        return NSAttributedString(attributedString: attributedString)
    }

    fileprivate class func styleTagTextForAttributes(_ attributes: StyledHTMLAttributes?) -> String {
        let styles: [String]? = attributes?.map { attributeType, attributes in
            var style = attributeType.tag + " { "
            for (attributeName, attribute) in attributes {
                if let attributeStyle = cssStyleForAttributeName(attributeName, attribute: attribute) {
                    style += attributeStyle
                }
            }

            return style + " }"
        }

        let joinedStyles = styles?.joined(separator: "") ?? ""
        return "<style>" + joinedStyles + "</style>"
    }

    /// Converts a limited set of `NSAttributedString` attribute types from their
    /// raw objects (e.g. `UIColor`) into CSS text.
    fileprivate class func cssStyleForAttributeName(_ attributeKey: NSAttributedString.Key, attribute: Any) -> String? {
        switch attributeKey {
        case .font:
            if let font = attribute as? UIFont {
                let size = font.pointSize
                let boldStyle = "font-weight: " + (font.isBold ? "bold;" : "normal;")
                let italicStyle = "font-style: " + (font.isItalic ? "italic;" : "normal;")
                return "font-family: -apple-system; font-size: \(size)px; " + boldStyle + italicStyle
            }
        case .foregroundColor:
            if let color = attribute as? UIColor,
                let colorHex = color.hexString() {
                return "color: #\(colorHex);"
            }
        case .underlineStyle:
            if let style = attribute as? Int {
                if style == NSUnderlineStyle([]).rawValue {
                    return "text-decoration: none;"
                } else {
                    return "text-decoration: underline;"
                }
            }
        default: break
        }

        return nil
    }
}

public typealias StyledHTMLAttributes = [HTMLAttributeType: [NSAttributedString.Key: Any]]

public enum HTMLAttributeType: String {
    case BodyAttribute
    case ATagAttribute
    case EmTagAttribute
    case StrongTagAttribute

    var tag: String {
        switch self {
        case .BodyAttribute: return "body"
        case .ATagAttribute: return "a"
        case .EmTagAttribute: return "em"
        case .StrongTagAttribute: return "strong"
        }
    }
}

public extension UIFont {
    var isBold: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }

    var isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }
}
