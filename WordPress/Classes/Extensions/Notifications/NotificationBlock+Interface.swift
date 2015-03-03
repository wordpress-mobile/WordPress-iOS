import Foundation


extension NotificationBlock
{
    // MARK: - Text Formatting Helpers
    //
    public func attributedSubjectText() -> NSAttributedString {
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.subjectRegularStyle,
                quoteStyles:    Styles.subjectItalicsStyle,
                rangeStylesMap: Constants.subjectRangeStylesMap,
                linksColor:     nil)
        }
        
        return attributedText(Constants.richSubjectCacheKey)
    }

    public func attributedSnippetText() -> NSAttributedString {
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.snippetRegularStyle,
                quoteStyles:    nil,
                rangeStylesMap: nil,
                linksColor:     nil)
        }
        
        return attributedText(Constants.richSnippetCacheKey)
    }

    public func attributedHeaderTitleText() -> NSAttributedString {
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.headerTitleRegularStyle,
                quoteStyles:    nil,
                rangeStylesMap: Constants.headerTitleRangeStylesMap,
                linksColor:     nil)
        }
                
        return attributedText(Constants.richHeaderTitleCacheKey)
    }

    public func attributedRichText() -> NSAttributedString {
        //  Operations such as editing a comment cause a lag between the REST and Simperium update.
        //  TextOverride is a transient property meant to store, temporarily, the edited text
        if textOverride != nil {
            return NSAttributedString(string: textOverride, attributes: Styles.blockRegularStyle)
        }
        
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.blockRegularStyle,
                quoteStyles:    Styles.blockBoldStyle,
                rangeStylesMap: Constants.richRangeStylesMap,
                linksColor:     Styles.blockLinkColor)
        }

        return attributedText(Constants.richTextCacheKey)
    }
    
    public func attributedBadgeText() -> NSAttributedString {
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.badgeRegularStyle,
                quoteStyles:    Styles.badgeBoldStyle,
                rangeStylesMap: Constants.badgeRangeStylesMap,
                linksColor:     Styles.badgeLinkColor)
        }
        
        return attributedText(Constants.richBadgeCacheKey)
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
    private func memoize(fn: () -> NSAttributedString) -> String -> NSAttributedString {
        return {
            (cacheKey : String) -> NSAttributedString in
            
            // Is it already cached?
            if let cachedSubject = self.cacheValueForKey(cacheKey) as? NSAttributedString {
                return cachedSubject
            }

            // Store in Cache
            let newValue = fn()
            self.setCacheValue(newValue, forKey: cacheKey)
            return newValue
        }
    }
    
    private func textWithStyles(attributes  : [NSString: AnyObject],
                                quoteStyles : [NSString: AnyObject]?,
                             rangeStylesMap : [NSString: AnyObject]?,
                                 linksColor : UIColor?) -> NSAttributedString
    {
        // Is it empty?
        if text == nil {
            return NSAttributedString()
        }
        
        // Format the String
        let theString = NSMutableAttributedString(string: text, attributes: attributes)

        // Apply Quotes Styles
        if let unwrappedQuoteStyles = quoteStyles {
            theString.applyAttributesToQuotes(unwrappedQuoteStyles)
        }
        
        // Apply the Ranges
        var lengthShift = 0
        
        for range in ranges as [NotificationRange] {
            var shiftedRange        = range.range
            shiftedRange.location   += lengthShift

            if let unwrappedRangeStyle = rangeStylesMap?[range.type] as? [NSString: AnyObject] {
                theString.addAttributes(unwrappedRangeStyle, range: shiftedRange)
            }
            
            if range.isNoticon {
                let noticon = NSAttributedString(string: "\(range.value) ", attributes: Styles.subjectNoticonStyle)
                theString.replaceCharactersInRange(shiftedRange, withAttributedString: noticon)
                lengthShift += noticon.length
            }
            
            if range.url != nil && linksColor != nil {
                theString.addAttribute(NSLinkAttributeName, value: range.url, range: shiftedRange)
                theString.addAttribute(NSForegroundColorAttributeName, value: linksColor!, range: shiftedRange)
            }
        }
        
        return theString
    }
    
    
    // MARK: - Constants
    //
    private struct Constants {
        static let subjectRangeStylesMap = [
            NoteRangeTypeUser               : Styles.subjectBoldStyle,
            NoteRangeTypePost               : Styles.subjectItalicsStyle,
            NoteRangeTypeComment            : Styles.subjectItalicsStyle,
            NoteRangeTypeBlockquote         : Styles.subjectQuotedStyle
        ]

        static let headerTitleRangeStylesMap = [
            NoteRangeTypeUser               : Styles.headerTitleBoldStyle,
            NoteRangeTypePost               : Styles.headerTitleContextStyle,
            NoteRangeTypeComment            : Styles.headerTitleContextStyle
        ]
        
        static let richRangeStylesMap = [
            NoteRangeTypeUser               : Styles.blockBoldStyle,
            NoteRangeTypePost               : Styles.blockItalicsStyle,
            NoteRangeTypeComment            : Styles.blockItalicsStyle,
            NoteRangeTypeBlockquote         : Styles.blockQuotedStyle
        ]
        
        static let badgeRangeStylesMap = [
            NoteRangeTypeUser               : Styles.badgeBoldStyle,
            NoteRangeTypePost               : Styles.badgeItalicsStyle,
            NoteRangeTypeComment            : Styles.badgeItalicsStyle,
            NoteRangeTypeBlockquote         : Styles.badgeQuotedStyle
        ]
        
        static let richSubjectCacheKey      = "richSubjectCacheKey"
        static let richSnippetCacheKey      = "richSnippetCacheKey"
        static let richHeaderTitleCacheKey  = "richHeaderTitleCacheKey"
        static let richTextCacheKey         = "richTextCacheKey"
        static let richBadgeCacheKey        = "richBadgeCacheKey"
    }
    
    private typealias Styles                = WPStyleGuide.Notifications
}
