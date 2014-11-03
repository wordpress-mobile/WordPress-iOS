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

        return NSAttributedString(string: text, attributes: Styles.snippetRegularStyle)
    }

    public func regularAttributedText() -> NSAttributedString {
        //  Operations such as editing a comment cause a lag between the REST and Simperium update.
        //  TextOverride is a transient property meant to store, temporarily, the edited text
        if textOverride != nil {
            return NSAttributedString(string: textOverride, attributes: Styles.blockRegularStyle)
        }
        
        return textWithRangeStyles(isSubject: false)
    }
    
    
    // MARK: - Private Helpers
    private func textWithRangeStyles(#isSubject: Bool) -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }
        
        // Setup the styles
        let regularStyle    = isSubject ? Styles.subjectRegularStyle : (isBadge ? Styles.blockBadgeStyle : Styles.blockRegularStyle)
        let quotesStyle     = isSubject ? Styles.subjectItalicsStyle : Styles.blockBoldStyle
        let userStyle       = isSubject ? Styles.subjectBoldStyle    : Styles.blockBoldStyle
        let postStyle       = isSubject ? Styles.subjectItalicsStyle : Styles.blockItalicsStyle
        let commentStyle    = postStyle
        let blockStyle      = Styles.blockQuotedStyle
        
        // Apply the metadata to the text itself
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
                theString.addAttribute(NSForegroundColorAttributeName, value: Styles.blockLinkColor, range: range.range)
            }
        }
        
        return theString;
    }
    
    private typealias Styles = WPStyleGuide.Notifications
}
