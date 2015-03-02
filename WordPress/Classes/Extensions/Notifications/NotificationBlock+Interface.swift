import Foundation


extension NotificationBlock
{
    private struct Constants
    {
        static let richSubjectCacheKey  = "richSubjectCacheKey"
        static let richSnippetCacheKey  = "richSnippetCacheKey"
        static let richHeaderCacheKey   = "richHeaderCacheKey"
        static let richTextCacheKey     = "richTextCacheKey"
    }

    // MARK: - Helpers used in NotificationsViewController
    //
    public func subjectAttributedText() -> NSAttributedString {
        if let cachedSubject = cacheValueForKey(Constants.richSubjectCacheKey) as? NSAttributedString {
            return cachedSubject
        }
        
        let richSubject = textWithRangeStyles(isSubject: true)
        setCacheValue(richSubject, forKey: Constants.richSubjectCacheKey)
        
        return richSubject
    }

    public func snippetAttributedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }

        if let cachedSnippet = cacheValueForKey(Constants.richSnippetCacheKey) as? NSAttributedString {
            return cachedSnippet
        }
        
        let richSnippet = NSAttributedString(string: text, attributes: Styles.snippetRegularStyle)
        setCacheValue(richSnippet, forKey: Constants.richSnippetCacheKey)
        
        return richSnippet
    }

    
    // MARK: - Helpers used in NotificationsDetailsViewController
    //
    public func headerAttributedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }
        
        return NSAttributedString()
    }

    public func richAttributedText() -> NSAttributedString {
        //  Operations such as editing a comment cause a lag between the REST and Simperium update.
        //  TextOverride is a transient property meant to store, temporarily, the edited text
        if textOverride != nil {
            return NSAttributedString(string: textOverride, attributes: Styles.blockRegularStyle)
        }
        
        if let cachedText = cacheValueForKey(Constants.richTextCacheKey) as? NSAttributedString {
            return cachedText
        }
        
        let richText = textWithRangeStyles(isSubject: false)
        setCacheValue(richText, forKey: Constants.richTextCacheKey)
        
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
    //
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
        
        // Apply the Ranges
        var lengthShift = 0
        
        for range in ranges as [NotificationRange] {
            var shiftedRange        = range.range
            shiftedRange.location   += lengthShift
            
            if range.isUser {
                theString.addAttributes(userStyle, range: shiftedRange)
            } else if range.isPost {
                theString.addAttributes(postStyle, range: shiftedRange)
            } else if range.isComment {
                theString.addAttributes(commentStyle, range: shiftedRange)
            } else if range.isBlockquote {
                theString.addAttributes(blockStyle, range: shiftedRange)
            } else if range.isNoticon {
                let noticon = NSAttributedString(string: "\(range.value) ", attributes: Styles.subjectNoticonStyle)
                theString.replaceCharactersInRange(shiftedRange, withAttributedString: noticon)
                lengthShift += noticon.length
            }
            
            // Don't Highlight Links in the subject
            if isSubject == false && range.url != nil {
                theString.addAttribute(NSLinkAttributeName, value: range.url, range: shiftedRange)
                theString.addAttribute(NSForegroundColorAttributeName, value: Styles.blockLinkColor, range: shiftedRange)
            }
        }
        
        return theString
    }
    
    private typealias Styles = WPStyleGuide.Notifications
}
