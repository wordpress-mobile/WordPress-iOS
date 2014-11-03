import Foundation


extension NotificationBlock
{
    public func subjectAttributedText() -> NSAttributedString {
        return textWithRangeStyles(isSubject: true)
    }

    public func snippetAttributedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }

        return NSAttributedString(string: text, attributes: WPStyleGuide.Notifications.snippetRegularStyle)
    }

    public func regularAttributedText() -> NSAttributedString {
        //  Operations such as editing a comment cause a lag between the REST and Simperium update.
        //  TextOverride is a transient property meant to store, temporarily, the edited text
        if textOverride != nil {
            return NSAttributedString(string: textOverride, attributes: WPStyleGuide.Notifications.blockRegularStyle(false))
        }
        
        return textWithRangeStyles(isSubject: false)
    }
    
    
    // MARK: - Private Helpers
    private func textWithRangeStyles(#isSubject: Bool) -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }
        
        let regularStyle    = WPStyleGuide.Notifications.blockRegularStyle(isSubject)
        let quotesStyle     = WPStyleGuide.Notifications.blockQuotesStyle(isSubject)
        let userStyle       = WPStyleGuide.Notifications.blockUserStyle(isSubject)
        let postStyle       = WPStyleGuide.Notifications.blockPostStyle(isSubject)
        let commentStyle    = WPStyleGuide.Notifications.blockCommentStyle(isSubject)
        let blockStyle      = WPStyleGuide.Notifications.blockBlockquotedStyle(isSubject)
        let linkColor       = WPStyleGuide.Notifications.blockLinkColor
        
        let theString = NSMutableAttributedString(string: text, attributes: regularStyle)
        theString.applyAttributesToQuotes(quotesStyle)
        
        for range in ranges as [NotificationRange] {
            if range.isUser {
                theString.addAttributes(userStyle, range: range.range)
            } else if range.isPost {
                theString.addAttributes(postStyle, range: range.range)
            } else if range.isComment {
                theString.addAttributes(commentStyle, range: range.range)
            } else if range.isBlockquote {
                theString.addAttributes(blockStyle, range: range.range)
            }

            if isSubject == false && range.url != nil {
                theString.addAttribute(NSLinkAttributeName, value: range.url, range: range.range)
                theString.addAttribute(NSForegroundColorAttributeName, value: linkColor, range: range.range)
            }
        }
        
        return theString;
    }
}
