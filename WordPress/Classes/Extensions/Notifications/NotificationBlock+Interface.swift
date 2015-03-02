import Foundation


extension NotificationBlock
{
    // MARK: - Text Formatting Helpers
    //
    public func attributedSubjectText() -> NSAttributedString {
        return textWithRangeStyles(Constants.subjectStyles, cacheKey: Constants.richSubjectCacheKey)
    }

    public func attributedSnippetText() -> NSAttributedString {
        return textWithRangeStyles(Constants.snippetStyles, cacheKey: Constants.richSnippetCacheKey)
    }

    public func attributedHeaderTitleText() -> NSAttributedString {
        return textWithRangeStyles(Constants.headerTitleStyles, cacheKey: Constants.richHeaderTitleCacheKey)
    }

    public func attributedRichText() -> NSAttributedString {
        //  Operations such as editing a comment cause a lag between the REST and Simperium update.
        //  TextOverride is a transient property meant to store, temporarily, the edited text
        if textOverride != nil {
            return NSAttributedString(string: textOverride, attributes: Styles.blockRegularStyle)
        }
        
        let styles = isBadge ? Constants.richBadgeStyles : Constants.richNormalStyles
        return textWithRangeStyles(styles, cacheKey: Constants.richTextCacheKey)
    }
    
    
    // MARK: - Media Helpers
    //
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
    private func textWithRangeStyles(styles: [String: AnyObject], cacheKey: String) -> NSAttributedString {
        // Is it cached?
        if let cachedSubject = cacheValueForKey(cacheKey) as? NSAttributedString {
            return cachedSubject
        }
        
        // Is it empty?
        if text == nil {
            return NSAttributedString()
        }
        
        // Format the String
        let regularStyle = styles[Constants.regularStyleKey] as [NSString: AnyObject]
        let theString = NSMutableAttributedString(string: text, attributes: regularStyle)
        
        // Apply Quotes Styles
        if let unwrappedQuoteStyle = styles[Constants.quoteStyleKey] as? [NSString: AnyObject] {
            theString.applyAttributesToQuotes(unwrappedQuoteStyle)
        }
        
        // Apply the Ranges
        var lengthShift = 0
        
        for range in ranges as [NotificationRange] {
            var shiftedRange        = range.range
            shiftedRange.location   += lengthShift
            
            if let unwrappedRangeStyle = styles[range.type] as? [NSString: AnyObject] {
                theString.addAttributes(unwrappedRangeStyle, range: shiftedRange)
            }
                
            if range.isNoticon {
                let noticon = NSAttributedString(string: "\(range.value) ", attributes: Styles.subjectNoticonStyle)
                theString.replaceCharactersInRange(shiftedRange, withAttributedString: noticon)
                lengthShift += noticon.length
            }
            
//            if range.url != nil && styles.linkColor != nil {
//                theString.addAttribute(NSLinkAttributeName, value: range.url, range: shiftedRange)
//                theString.addAttribute(NSForegroundColorAttributeName, value: styles.linkColor!, range: shiftedRange)
//            }
        }
        
        // Store in Cache
        setCacheValue(theString, forKey: cacheKey)
        
        return theString
    }
    
    
    // MARK: - NotificationBlock+Interface Constants
    //
    private struct Constants
    {
        static let richSubjectCacheKey      = "richSubjectCacheKey"
        static let richSnippetCacheKey      = "richSnippetCacheKey"
        static let richHeaderTitleCacheKey  = "richHeaderTitleCacheKey"
        static let richTextCacheKey         = "richTextCacheKey"
        
        static let userStyleKey             = NoteRangeTypeUser
        static let postStyleKey             = NoteRangeTypePost
        static let commentStyleKey          = NoteRangeTypeComment
        static let bockquoteKey             = NoteRangeTypeBlockquote
        static let regularStyleKey          = "regularStyleKey"
        static let quoteStyleKey            = "quoteStyleKey"
        static let linkStyleKey             = "linkStyleKey"
        
        // Mark: - NotificationsViewController Styles
        static let subjectStyles = [
            regularStyleKey                 : Styles.subjectRegularStyle,
            quoteStyleKey                   : Styles.subjectItalicsStyle,
            
            userStyleKey                    : Styles.subjectBoldStyle,
            postStyleKey                    : Styles.subjectItalicsStyle,
            commentStyleKey                 : Styles.subjectItalicsStyle,
            bockquoteKey                    : Styles.subjectQuotedStyle
        ]

        static let snippetStyles = [
            regularStyleKey                 : Styles.snippetRegularStyle
        ]

        // Mark: - NotificationDetailsViewController Styles
        static let headerTitleStyles = [
            regularStyleKey                 : Styles.snippetRegularStyle
        ]
        
        static let richNormalStyles = [
            regularStyleKey                 : Styles.blockRegularStyle,
            quoteStyleKey                   : Styles.blockBoldStyle,
            linkStyleKey                    : Styles.blockLinkColor,
            
            userStyleKey                    : Styles.blockBoldStyle,
            postStyleKey                    : Styles.blockItalicsStyle,
            commentStyleKey                 : Styles.blockItalicsStyle,
            bockquoteKey                    : Styles.blockQuotedStyle
        ]
        
        static let richBadgeStyles = [
            regularStyleKey                 : Styles.badgeRegularStyle,
            quoteStyleKey                   : Styles.badgeBoldStyle,
            linkStyleKey                    : Styles.badgeLinkColor,
            
            userStyleKey                    : Styles.badgeBoldStyle,
            postStyleKey                    : Styles.badgeItalicsStyle,
            commentStyleKey                 : Styles.badgeItalicsStyle,
            bockquoteKey                    : Styles.badgeQuotedStyle
        ]
    }
    
    private typealias Styles = WPStyleGuide.Notifications
}
