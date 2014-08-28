import Foundation


extension NotificationBlock
{
    public func subjectFormattedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }
        
        let theString = NSMutableAttributedString(string: text, attributes: WPStyleGuide.Notifications.Styles.subjectRegular)

        theString.applyAttributesToQuotes(WPStyleGuide.Notifications.Styles.subjectItalics)

        for range in ranges as [NotificationRange] {
            if range.isUser {
                theString.addAttributes(WPStyleGuide.Notifications.Styles.subjectBold, range: range.range)
            } else if range.isPost {
                theString.addAttributes(WPStyleGuide.Notifications.Styles.subjectItalics, range: range.range)
            }
        }

        return theString;
    }

    public func snippetFormattedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }

        return NSMutableAttributedString(string: text, attributes: WPStyleGuide.Notifications.Styles.snippetItalics)
    }

    public func regularFormattedText() -> NSAttributedString {
        if textOverride != nil {
            return NSMutableAttributedString(string: textOverride, attributes: WPStyleGuide.Notifications.Styles.blockRegular)
        }

        if text == nil {
            return NSAttributedString()
        }
        
        let theString = NSMutableAttributedString(string: text, attributes: WPStyleGuide.Notifications.Styles.blockRegular)
        
        theString.applyAttributesToQuotes(WPStyleGuide.Notifications.Styles.blockBold)
        
        //  Note: CoreText doesn't work with NSLinkAttributeName
        //      DTLinkAttribute     = "NSLinkAttributeName"
        //      NSLinkAttributeName = "NSLink"
        //
        for range in ranges as [NotificationRange] {
            if range.isPost {
                theString.addAttributes(WPStyleGuide.Notifications.Styles.blockItalics, range: range.range)
            }
            
            if range.url != nil {
                theString.addAttribute(DTLinkAttribute, value: range.url, range: range.range)
                theString.addAttribute(NSForegroundColorAttributeName, value: WPStyleGuide.Notifications.Colors.blockLink, range: range.range)
            }
        }

        return theString
    }
}
