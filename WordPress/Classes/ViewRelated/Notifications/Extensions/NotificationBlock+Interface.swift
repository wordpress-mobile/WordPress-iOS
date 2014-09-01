import Foundation


extension NotificationBlock
{
    public func subjectFormattedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }
        
        let theString = NSMutableAttributedString(string: text, attributes: WPStyleGuide.Notifications.subjectRegularStyle)

        theString.applyAttributesToQuotes(WPStyleGuide.Notifications.subjectItalicsStyle)

        for range in ranges as [NotificationRange] {
            if range.isUser {
                theString.addAttributes(WPStyleGuide.Notifications.subjectBoldStyle, range: range.range)
            } else if range.isPost || range.isComment {
                theString.addAttributes(WPStyleGuide.Notifications.subjectItalicsStyle, range: range.range)
            }
        }

        return theString;
    }

    public func snippetFormattedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }

        return NSMutableAttributedString(string: text, attributes: WPStyleGuide.Notifications.snippetRegularStyle)
    }

    public func regularFormattedText() -> NSAttributedString {
        if textOverride != nil {
            return NSMutableAttributedString(string: textOverride, attributes: WPStyleGuide.Notifications.blockRegularStyle)
        }

        if text == nil {
            return NSAttributedString()
        }
        
        let theString = NSMutableAttributedString(string: text, attributes: WPStyleGuide.Notifications.blockRegularStyle)
        
        theString.applyAttributesToQuotes(WPStyleGuide.Notifications.blockBoldStyle)
        
        //  Note: CoreText doesn't work with NSLinkAttributeName
        //      DTLinkAttribute     = "NSLinkAttributeName"
        //      NSLinkAttributeName = "NSLink"
        //
        for range in ranges as [NotificationRange] {
            if range.isPost {
                theString.addAttributes(WPStyleGuide.Notifications.blockItalicsStyle, range: range.range)
            } else if range.isBlockquote {
                theString.addAttributes(WPStyleGuide.Notifications.blockQuotedStyle, range: range.range)
            }

            if range.url != nil {
                theString.addAttribute(DTLinkAttribute, value: range.url, range: range.range)
                theString.addAttribute(NSForegroundColorAttributeName, value: WPStyleGuide.Notifications.blockLinkColor, range: range.range)
            }
        }

        return theString
    }
}
