import Foundation


extension NotificationBlock
{
    public func subjectAttributedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }
        
        let theString = NSMutableAttributedString(string: text, attributes: WPStyleGuide.Notifications.subjectRegularStyle)

        theString.applyAttributesToQuotes(WPStyleGuide.Notifications.subjectItalicsStyle)

        for notificationRange in ranges as [NotificationRange] {
            
            // Make sure this range is not ouf bounds!
            let range = notificationRange.range
            if range.location + range.length > theString.length {
                continue
            }
            
            if notificationRange.isUser {
                theString.addAttributes(WPStyleGuide.Notifications.subjectBoldStyle, range: range)
            } else if notificationRange.isPost || notificationRange.isComment {
                theString.addAttributes(WPStyleGuide.Notifications.subjectItalicsStyle, range: range)
            }
        }

        return theString;
    }

    public func snippetAttributedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }

        return NSMutableAttributedString(string: text, attributes: WPStyleGuide.Notifications.snippetRegularStyle)
    }

    public func regularAttributedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }
        
        let theString = NSMutableAttributedString(string: text, attributes: WPStyleGuide.Notifications.blockRegularStyle)
        
        theString.applyAttributesToQuotes(WPStyleGuide.Notifications.blockBoldStyle)
        
        for range in ranges as [NotificationRange] {
            if range.isPost {
                theString.addAttributes(WPStyleGuide.Notifications.blockItalicsStyle, range: range.range)
            } else if range.isBlockquote {
                theString.addAttributes(WPStyleGuide.Notifications.blockQuotedStyle, range: range.range)
            }

            if range.url != nil {
                theString.addAttribute(NSLinkAttributeName, value: range.url, range: range.range)
                theString.addAttribute(NSForegroundColorAttributeName, value: WPStyleGuide.Notifications.blockLinkColor, range: range.range)
            }
        }

        return theString
    }

    public func regularAttributedTextOverride() -> NSAttributedString? {
        //  Operations such as editing a comment cause a lag between the REST and Simperium update.
        //  TextOverride is a transient property meant to store, temporarily, the edited text
        if textOverride != nil {
            return NSAttributedString(string: textOverride, attributes: WPStyleGuide.Notifications.blockRegularStyle)
        }
        return nil
    }
}
