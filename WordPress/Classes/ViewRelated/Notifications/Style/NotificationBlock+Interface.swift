import Foundation


extension NotificationBlock
{
    public func attributedSubject() -> NSAttributedString {
        if !text {
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
    
    public func attributedTextRegular() -> NSAttributedString {
        if !text {
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
            
            if url.url {
                theString.addAttribute(DTLinkAttribute, value: url.url, range: url.range)
                theString.addAttribute(NSForegroundColorAttributeName, value: Notification.Colors.blockLink, range: url.range)
            }
        }

        // Failsafe: Sometimes the backend won't linkify URL's 
        let range       = NSMakeRange(0, countElements(text!))
        let detector    = NSDataDetector(types: NSTextCheckingType.Link.toRaw(), error: nil)

        detector.enumerateMatchesInString(text, options: nil, range: range) {
            (result: NSTextCheckingResult!, flags: NSMatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            theString.addAttribute(DTLinkAttribute, value: result.URL, range: result.range)
            theString.addAttribute(NSForegroundColorAttributeName, value: Notification.Colors.blockLink, range: result.range)
        }
        
        return theString
    }

    public func attributedTextQuoted() -> NSAttributedString {
        if !text {
            return NSAttributedString()
        }

        return NSMutableAttributedString(string: text, attributes: Notification.Styles.quotedItalics)
    }
}
