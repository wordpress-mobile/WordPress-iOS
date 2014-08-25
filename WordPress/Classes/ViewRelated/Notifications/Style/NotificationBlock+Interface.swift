import Foundation


extension NotificationBlock
{
    public func subjectFormattedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }
        
        let theString = NSMutableAttributedString(string: text, attributes: Notification.Styles.subjectRegular)

        theString.applyAttributesToQuotes(Notification.Styles.subjectItalics)

        for url in urls as [NotificationURL] {
            if url.isUser {
                theString.addAttributes(Notification.Styles.subjectBold, range: url.range)
            } else if url.isPost {
                theString.addAttributes(Notification.Styles.subjectItalics, range: url.range)
            }
        }

        return theString;
    }

    public func regularFormattedOverride() -> NSAttributedString? {
        if textOverride == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: textOverride, attributes: Notification.Styles.blockRegular)
    }

    public func regularFormattedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }
        
        let theString = NSMutableAttributedString(string: text, attributes: Notification.Styles.blockRegular)
        
        theString.applyAttributesToQuotes(Notification.Styles.blockBold)
        
        //  Note: CoreText doesn't work with NSLinkAttributeName
        //      DTLinkAttribute     = "NSLinkAttributeName"
        //      NSLinkAttributeName = "NSLink"
        for url in urls as [NotificationURL] {
            if url.isPost {
                theString.addAttributes(Notification.Styles.blockItalics, range: url.range)
            }
            
            if url.url != nil {
                theString.addAttribute(DTLinkAttribute, value: url.url, range: url.range)
                theString.addAttribute(NSForegroundColorAttributeName, value: Notification.Colors.blockLink, range: url.range)
            }
        }
        
        return theString
    }

    public func quotedFormattedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }

        return NSMutableAttributedString(string: text, attributes: Notification.Styles.quotedItalics)
    }
}
