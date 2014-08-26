import Foundation


extension NotificationBlock
{
    public func subjectFormattedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }
        
        let theString = NSMutableAttributedString(string: text, attributes: WPStyleGuide.Notifications.Styles.subjectRegular)

        theString.applyAttributesToQuotes(WPStyleGuide.Notifications.Styles.subjectItalics)

        for url in urls as [NotificationURL] {
            if url.isUser {
                theString.addAttributes(WPStyleGuide.Notifications.Styles.subjectBold, range: url.range)
            } else if url.isPost {
                theString.addAttributes(WPStyleGuide.Notifications.Styles.subjectItalics, range: url.range)
            }
        }

        return theString;
    }

    public func regularFormattedOverride() -> NSAttributedString? {
        if textOverride == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: textOverride, attributes: WPStyleGuide.Notifications.Styles.blockRegular)
    }

    public func regularFormattedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }
        
        let theString = NSMutableAttributedString(string: text, attributes: WPStyleGuide.Notifications.Styles.blockRegular)
        
        theString.applyAttributesToQuotes(WPStyleGuide.Notifications.Styles.blockBold)
        
        //  Note: CoreText doesn't work with NSLinkAttributeName
        //      DTLinkAttribute     = "NSLinkAttributeName"
        //      NSLinkAttributeName = "NSLink"
        for url in urls as [NotificationURL] {
            if url.isPost {
                theString.addAttributes(WPStyleGuide.Notifications.Styles.blockItalics, range: url.range)
            }
            
            if url.url != nil {
                theString.addAttribute(DTLinkAttribute, value: url.url, range: url.range)
                theString.addAttribute(NSForegroundColorAttributeName, value: WPStyleGuide.Notifications.Colors.blockLink, range: url.range)
            }
        }
        
        return theString
    }

    public func snippetFormattedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }

        return NSMutableAttributedString(string: text, attributes: WPStyleGuide.Notifications.Styles.snippetItalics)
    }

    public func quotedFormattedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }

        return NSMutableAttributedString(string: text, attributes: WPStyleGuide.Notifications.Styles.quotedItalics)
    }
}
