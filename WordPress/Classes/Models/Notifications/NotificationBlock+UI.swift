import Foundation


extension NotificationBlock
{
    public func attributedSubject() -> NSAttributedString {
        if !text {
            return NSAttributedString()
        }
        
        let theString = NSMutableAttributedString(string: text, attributes: NotificationStyles.subjectRegular)

        theString.applyAttributesToQuotes(NotificationStyles.subjectItalics)

        for url in urls as [NotificationURL] {
            if url.isUser {
                theString.addAttributes(NotificationStyles.subjectBold, range: url.range)
            } else if url.isPost {
                theString.addAttributes(NotificationStyles.subjectItalics, range: url.range)
            }
        }

        return theString;
    }
    
    public func attributedTextRegular() -> NSAttributedString {
        if !text {
            return NSAttributedString()
        }
        
        let theString = NSMutableAttributedString(string: text, attributes: NotificationStyles.blockRegular)
        
        theString.applyAttributesToQuotes(NotificationStyles.blockBold)
        
        //  Note: CoreText doesn't work with NSLinkAttributeName
        //      DTLinkAttribute     = "NSLinkAttributeName"
        //      NSLinkAttributeName = "NSLink"
        for url in urls as [NotificationURL] {
            if url.isPost {
                theString.addAttributes(NotificationStyles.blockItalics, range: url.range)
            }
            
            if url.url {
                theString.addAttribute(DTLinkAttribute, value: url.url, range: url.range)
                theString.addAttribute(NSForegroundColorAttributeName, value: NotificationColors.blockLink, range: url.range)
            }
        }

        // Failsafe: Sometimes the backend won't linkify URL's 
        let range       = NSMakeRange(0, countElements(text!))
        let detector    = NSDataDetector(types: NSTextCheckingType.Link.toRaw(), error: nil)

        detector.enumerateMatchesInString(text, options: nil, range: range) {
            (result: NSTextCheckingResult!, flags: NSMatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            theString.addAttribute(DTLinkAttribute, value: result.URL, range: result.range)
            theString.addAttribute(NSForegroundColorAttributeName, value: NotificationColors.blockLink, range: result.range)
        }
        
        return theString
    }

    public func attributedTextQuoted() -> NSAttributedString {
        if !text {
            return NSAttributedString()
        }

        return NSMutableAttributedString(string: text, attributes: NotificationStyles.quotedItalics)
    }
}
