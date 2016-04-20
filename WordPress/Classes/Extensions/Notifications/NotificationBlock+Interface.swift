import Foundation
import WordPressShared.WPStyleGuide

/**
*  @extension       NotificationBlock
*
*  @brief           This class extension implements helper methods to aid formatting a NotificationBlock's
*                   payload, for usage in several different spots of the app.
*
*  @details         The main goal of this helper Extension is to encapsulate presentation details into a 
                    single piece of code, while preserving a clear sepparation with the Model itself.
                    We rely on a cache mechanism, implemented for performance purposes, that will get nuked
                    whenever the related Notification object gets updated.
*/
extension NotificationBlock
{
    // MARK: - Public Methods
    //
    
    /**
    *	@brief      Formats a NotificationBlock for usage in NoteTableViewCell, in the subject field
    *
    *	@returns	A Subject Attributed String
    */
    public func attributedSubjectText() -> NSAttributedString {
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.subjectRegularStyle,
                quoteStyles:    Styles.subjectItalicsStyle,
                rangeStylesMap: Constants.subjectRangeStylesMap,
                linksColor:     nil)
        }
        
        return attributedText(Constants.richSubjectCacheKey)
    }

    /**
    *	@brief      Formats a NotificationBlock for usage in NoteTableViewCell, in the snippet field
    *
    *	@returns	A Snippet Attributed String
    */
    public func attributedSnippetText() -> NSAttributedString {
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.snippetRegularStyle,
                quoteStyles:    nil,
                rangeStylesMap: nil,
                linksColor:     nil)
        }
        
        return attributedText(Constants.richSnippetCacheKey)
    }

    /**
    *	@brief      Formats a NotificationBlock for usage in NoteBlockHeaderTableViewCell
    *
    *	@returns	A Header Attributed String
    */
    public func attributedHeaderTitleText() -> NSAttributedString {
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.headerTitleRegularStyle,
                quoteStyles:    nil,
                rangeStylesMap: Constants.headerTitleRangeStylesMap,
                linksColor:     nil)
        }
                
        return attributedText(Constants.richHeaderTitleCacheKey)
    }

    /**
    *	@brief      Formats a NotificationBlock for usage in NoteBlockFooterTableViewCell
    *
    *	@returns	A Header Attributed String
    */
    public func attributedFooterText() -> NSAttributedString {
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.footerRegularStyle,
                quoteStyles:    nil,
                rangeStylesMap: Constants.footerStylesMap,
                linksColor:     nil)
        }
        
        return attributedText(Constants.richHeaderTitleCacheKey)
    }
    
    /**
    *	@brief      Formats a NotificationBlock for usage into both, NoteBlockTextTableViewCell 
    *               and NoteBlockCommentTableViewCell.
    *
    *	@returns	An Attributed String for usage in both, comments and cell cells
    */
    public func attributedRichText() -> NSAttributedString {
        //  Operations such as editing a comment cause a lag between the REST and Simperium update.
        //  TextOverride is a transient property meant to store, temporarily, the edited text
        if textOverride != nil {
            return NSAttributedString(string: textOverride, attributes: Styles.contentBlockRegularStyle)
        }
        
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.contentBlockRegularStyle,
                quoteStyles:    Styles.contentBlockBoldStyle,
                rangeStylesMap: Constants.richRangeStylesMap,
                linksColor:     Styles.blockLinkColor)
        }

        return attributedText(Constants.richTextCacheKey)
    }
    
    /**
    *	@brief      Formats a NotificationBlock for usage into Badge-Type notifications. This contains
    *               custom formatting that differs from regular notifications, such as centered texts.
    *
    *	@returns	An Attributed String for usage in Badge Notifications
    */
    public func attributedBadgeText() -> NSAttributedString {
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.badgeRegularStyle,
                quoteStyles:    Styles.badgeBoldStyle,
                rangeStylesMap: Constants.badgeRangeStylesMap,
                linksColor:     Styles.badgeLinkColor)
        }
        
        return attributedText(Constants.richBadgeCacheKey)
    }

    
    /**
    *	@brief      Given a set of URL's and the Images they reference to, this method will return a Dictionary
    *               with the NSRange's in which the given UIImage's should be injected
    *   @details    This is used to build an Attributed String containing inline images.
    *
    *   @param      mediaMap    A Dictionary mapping asset URL's to the already-downloaded assets
    *
    *	@returns	A Dictionary mapping Text-Ranges in which the UIImage's should be applied
    */
    public func buildRangesToImagesMap(mediaMap: [NSURL: UIImage]?) -> [NSValue: UIImage]? {
        // If we've got a text override: Ranges may not match, and the new text may not even contain ranges!
        if mediaMap == nil || textOverride != nil {
            return nil
        }
        
        var ranges = [NSValue: UIImage]()
        
        for theMedia in media as! [NotificationMedia] {
            // Failsafe: if the mediaURL couldn't be parsed, don't proceed
            if theMedia.mediaURL == nil {
                continue
            }
            
            if let image = mediaMap![theMedia.mediaURL] {
                let rangeValue      = NSValue(range: theMedia.range)
                ranges[rangeValue]  = image
            }
        }
        
        return ranges
    }
    
    
    // MARK: - Private Helpers
    //
    
    /**
    *	@brief      This method is meant to aid cache-implementation into all of the AttriutedString getters
    *               introduced in this extension.
    *
    *   @param      fn  A Closure that, on execution, returns an attributed string.
    *	@returns	A new Closure that on execution will either hit the cache, or execute the closure `fn`
    *               and store its return value in the cache.
    */
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
    
    /**
    *	@brief      This method is an all-purpose helper to aid formatting the NotificationBlock's payload text.
    *
    *   @param      attributes      Represents the attributes to be applied, initially, to the Text.
    *   @param      quoteStyles     The Styles to be applied to "any quoted text"
    *   @param      rangeStylesMap  A Dictionary object mapping NotificationBlock types to a dictionary of styles
    *                               to be applied.
    *   @param      linksColor      The color that should be used on any links contained.
    *	@returns	A NSAttributedString instance, formatted with all of the specified parameters
    */
    private func textWithStyles(attributes  : [String: AnyObject],
                                quoteStyles : [String: AnyObject]?,
                             rangeStylesMap : [String: AnyObject]?,
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
        
        for range in ranges as! [NotificationRange] {
            var shiftedRange        = range.range
            shiftedRange.location   += lengthShift

            if range.isNoticon {
                let noticon         = "\(range.value) "
                theString.replaceCharactersInRange(shiftedRange, withString: noticon)
                lengthShift         += noticon.characters.count
                shiftedRange.length += noticon.characters.count
            }
            
            if let unwrappedRangeStyle = rangeStylesMap?[range.type] as? [String: AnyObject] {
                theString.addAttributes(unwrappedRangeStyle, range: shiftedRange)
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
            NoteRangeTypeBlockquote         : Styles.subjectQuotedStyle,
            NoteRangeTypeNoticon            : Styles.subjectNoticonStyle
        ]

        static let headerTitleRangeStylesMap = [
            NoteRangeTypeUser               : Styles.headerTitleBoldStyle,
            NoteRangeTypePost               : Styles.headerTitleContextStyle,
            NoteRangeTypeComment            : Styles.headerTitleContextStyle
        ]

        static let footerStylesMap = [
            NoteRangeTypeNoticon            : Styles.blockNoticonStyle
        ]
        
        static let richRangeStylesMap = [
            NoteRangeTypeBlockquote         : Styles.contentBlockQuotedStyle,
            NoteRangeTypeNoticon            : Styles.blockNoticonStyle,
            NoteRangeTypeMatch              : Styles.contentBlockMatchStyle
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
