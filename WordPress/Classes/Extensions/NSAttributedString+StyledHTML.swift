import UIKit

extension NSAttributedString {
    /// Creates an `NSAttributedString` with the styles defined in `attributes` applied.
    /// - parameter htmlString: The string to be styled. This can contain HTML
    ///    tags to markup sections of the text to style, but should not be wrapped
    ///    with `<html>`, `<body>` or `<p>` tags. See `HTMLAttributeType` for supported tags.
    /// - parameter attributes: A collection of style attributes to apply to `htmlString`.
    ///    See `HTMLAttributeType` for supported attributes.
    ///
    ///    **Notes:**
    ///
    ///    - Font sizes will be interpreted as pixel sizes, not points.
    ///    - Font family / name will be discarded (generated strings will always
    ///      use the system font), but font size and bold / italic information
    ///      will be applied.
    ///
    class func attributedStringWithHTML(htmlString: String, attributes: StyledHTMLAttributes?) -> NSAttributedString {
        let styles = styleTagTextForAttributes(attributes)
        let styledString = styles + htmlString
        let attributedString = try! NSMutableAttributedString(
            data: styledString.dataUsingEncoding(NSUTF8StringEncoding)!,
            options: [ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding ],
            documentAttributes: nil)

        // Apply a paragaraph style to remove extra padding at the top and bottom
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.paragraphSpacingBefore = 0

        attributedString.addAttribute(NSParagraphStyleAttributeName,
                                   value: paragraphStyle,
                                   range: NSMakeRange(0, attributedString.string.characters.count - 1))

        return attributedString.copy() as! NSAttributedString
    }

    private class func styleTagTextForAttributes(attributes: StyledHTMLAttributes?) -> String {
        let styles: [String]? = attributes?.map { attributeType, attributes in
            var style = attributeType.tag + " { "
            for (attributeName, attribute) in attributes {
                if let attributeStyle = cssStyleForAttributeName(attributeName, attribute: attribute) {
                    style += attributeStyle
                }
            }

            return style + " }"
        }

        let joinedStyles = styles?.joinWithSeparator("") ?? ""
        return "<style>" + joinedStyles + "</style>"
    }

    /// Converts a limited set of `NSAttributedString` attribute types from their
    /// raw objects (e.g. `UIColor`) into CSS text.
    private class func cssStyleForAttributeName(attributeName: String, attribute: AnyObject) -> String? {
        switch attributeName {
        case NSFontAttributeName:
            if let font = attribute as? UIFont {
                let size = font.pointSize
                let boldStyle = "font-weight: " + (font.isBold ? "bold;" : "normal;")
                let italicStyle = "font-style: " + (font.isItalic ? "italic;" : "normal;")
                return "font-family: -apple-system; font-size: \(size)px; " + boldStyle + italicStyle
            }
        case NSForegroundColorAttributeName:
            if let color = attribute as? UIColor {
                let colorHex = color.hexString()
                return "color: #\(colorHex);"
            }
        case NSUnderlineStyleAttributeName:
            if let style = attribute as? Int {
                if style == NSUnderlineStyle.StyleNone.rawValue {
                    return "text-decoration: none;"
                } else {
                    return "text-decoration: underline;"
                }
            }
        case NSTextAlignmentAttributeName:
            if let intValue = attribute as? Int,
                let alignment = NSTextAlignment(rawValue: intValue) {
                let direction: String

                switch alignment {
                case .Left: direction = "left"
                case .Right: direction = "right"
                case .Center: direction = "center"
                default: return nil
                }

                return "text-align: \(direction);"
            }

        default: break
        }

        return nil
    }
}

/// NSTextAlignment is usually set via an NSParagraphStyle. This constant has
/// been added so that it can be set alongside other attributes with a
/// consistent name.
public let NSTextAlignmentAttributeName = "NSTextAlignmentAttributeName"

public typealias StyledHTMLAttributes = [HTMLAttributeType : [String : AnyObject]]

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

private extension UIFont {
    var isBold: Bool {
        return fontDescriptor().symbolicTraits.contains(.TraitBold)
    }

    var isItalic: Bool {
        return fontDescriptor().symbolicTraits.contains(.TraitItalic)
    }
}
