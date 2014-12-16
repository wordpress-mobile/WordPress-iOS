import Foundation


extension NotificationBlock
{
    public func subjectAttributedText() -> NSAttributedString {
        let richSubjectCacheKey = "richSubject"
        
        if let cachedSubject = cacheValueForKey(richSubjectCacheKey) as? NSAttributedString {
            return cachedSubject
        }
        
        let richSubject = textWithRangeStyles(isSubject: true)
        setCacheValue(richSubject, forKey: richSubjectCacheKey)
        
        return richSubject
    }

    public func snippetAttributedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }

        let richSnippetCacheKey = "richSnippet"
        if let cachedSnippet = cacheValueForKey(richSnippetCacheKey) as? NSAttributedString {
            return cachedSnippet
        }
        
        let richSnippet = NSAttributedString(string: text, attributes: Styles.snippetRegularStyle)
        setCacheValue(richSnippet, forKey: richSnippetCacheKey)
        
        return richSnippet
    }

    public func richAttributedText() -> NSAttributedString {
        //  Operations such as editing a comment cause a lag between the REST and Simperium update.
        //  TextOverride is a transient property meant to store, temporarily, the edited text
        if textOverride != nil {
            return NSAttributedString(string: textOverride, attributes: Styles.blockRegularStyle)
        }
        
        let richTextCacheKey = "richText"
        if let cachedText = cacheValueForKey(richTextCacheKey) as? NSAttributedString {
            return cachedText
        }
        
        let richText = textWithRangeStyles(isSubject: false)
        setCacheValue(richText, forKey: richTextCacheKey)
        
        return richText
    }
    
    public func buildRangesToImagesMap(mediaMap: [NSURL: UIImage]?) -> [NSValue: UIImage]? {
        // If we've got a text override: Ranges may not match, and the new text may not even contain ranges!
        if mediaMap == nil || textOverride != nil {
            return nil
        }
        
        var ranges = [NSValue: UIImage]()
        
        for theMedia in media as [NotificationMedia] {
            if let image = mediaMap![theMedia.mediaURL] {
                let rangeValue      = NSValue(range: theMedia.range)
                ranges[rangeValue]  = image
            }
        }
        
        return ranges
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
        
        // Format the String
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

            // Don't Highlight Links in the subject
            if isSubject == false && range.url != nil {
                theString.addAttribute(NSLinkAttributeName, value: range.url, range: range.range)
                theString.addAttribute(NSForegroundColorAttributeName, value: Styles.blockLinkColor, range: range.range)
            }
        }

        return theString
    }
    
    private typealias Styles = WPStyleGuide.Notifications
}
