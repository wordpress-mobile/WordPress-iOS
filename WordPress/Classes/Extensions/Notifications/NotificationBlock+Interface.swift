import Foundation
import WordPressShared.WPStyleGuide



/// This class extension implements helper methods to aid formatting a NotificationBlock's payload,
/// for usage in several different spots of the app.
///
/// The main goal of this helper Extension is to encapsulate presentation details into a single piece of
/// code, while preserving a clear sepparation with the Model itself.
/// We rely on a cache mechanism, implemented for performance purposes, that will get nuked whenever the
/// related Notification object gets updated.
///
extension NotificationBlock {

    // MARK: - Public Methods
    //

    /// Formats a NotificationBlock for usage in NoteTableViewCell, in the subject field
    ///
    var attributedSubjectText: NSAttributedString {
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.subjectRegularStyle,
                quoteStyles:    Styles.subjectItalicsStyle,
                rangeStylesMap: Constants.subjectRangeStylesMap,
                linksColor:     nil)
        }

        return attributedText(Constants.richSubjectCacheKey)
    }

    /// Formats a NotificationBlock for usage in NoteTableViewCell, in the snippet field
    ///
    var attributedSnippetText: NSAttributedString {
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.snippetRegularStyle,
                quoteStyles:    nil,
                rangeStylesMap: nil,
                linksColor:     nil)
        }

        return attributedText(Constants.richSnippetCacheKey)
    }

    /// Formats a NotificationBlock for usage in NoteBlockHeaderTableViewCell
    ///
    var attributedHeaderTitleText: NSAttributedString {
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.headerTitleRegularStyle,
                quoteStyles:    nil,
                rangeStylesMap: Constants.headerTitleRangeStylesMap,
                linksColor:     nil)
        }

        return attributedText(Constants.richHeaderTitleCacheKey)
    }

    /// Formats a NotificationBlock for usage in NoteBlockFooterTableViewCell
    ///
    var attributedFooterText: NSAttributedString {
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.footerRegularStyle,
                quoteStyles:    nil,
                rangeStylesMap: Constants.footerStylesMap,
                linksColor:     nil)
        }

        return attributedText(Constants.richHeaderTitleCacheKey)
    }

    /// Formats a NotificationBlock for usage into both, NoteBlockTextTableViewCell and NoteBlockCommentTableViewCell.
    ///
    var attributedRichText: NSAttributedString {
        //  Operations such as editing a comment cause a lag between the REST and Simperium update.
        //  TextOverride is a transient property meant to store, temporarily, the edited text
        if let textOverride = textOverride {
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

    /// Formats a NotificationBlock for usage into Badge-Type notifications. This contains custom
    /// formatting that differs from regular notifications, such as centered texts.
    ///
    var attributedBadgeText: NSAttributedString {
        let attributedText = memoize { () -> NSAttributedString in
            return self.textWithStyles(Styles.badgeRegularStyle,
                quoteStyles:    Styles.badgeBoldStyle,
                rangeStylesMap: Constants.badgeRangeStylesMap,
                linksColor:     Styles.badgeLinkColor)
        }

        return attributedText(Constants.richBadgeCacheKey)
    }


    /// Given a set of URL's and the Images they reference to, this method will return a Dictionary
    /// with the NSRange's in which the given UIImage's should be injected.
    ///
    /// This is used to build an Attributed String containing inline images.
    ///
    /// - Parameter mediaMap: A Dictionary mapping asset URL's to the already-downloaded assets
    ///
    /// - Returns: A Dictionary mapping Text-Ranges in which the UIImage's should be applied
    ///
    func buildRangesToImagesMap(mediaMap: [NSURL: UIImage]) -> [NSValue: UIImage]? {
        // If we've got a text override: Ranges may not match, and the new text may not even contain ranges!
        if textOverride != nil {
            return nil
        }

        var ranges = [NSValue: UIImage]()

        for theMedia in media {
            // Failsafe: if the mediaURL couldn't be parsed, don't proceed
            guard let mediaURL = theMedia.mediaURL, range = theMedia.range else {
                continue
            }

            if let image = mediaMap[mediaURL] {
                let rangeValue      = NSValue(range: range)
                ranges[rangeValue]  = image
            }
        }

        return ranges
    }


    // MARK: - Private Helpers
    //

    /// This method is meant to aid cache-implementation into all of the AttriutedString getters introduced
    /// in this extension.
    ///
    /// - Parameter fn: A Closure that, on execution, returns an attributed string.
    ///
    /// - Returns: A new Closure that on execution will either hit the cache, or execute the closure `fn`
    ///            and store its return value in the cache.
    ///
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

    /// This method is an all-purpose helper to aid formatting the NotificationBlock's payload text.
    ///
    /// - Parameters:
    ///     - attributes: Represents the attributes to be applied, initially, to the Text.
    ///     - quoteStyles: The Styles to be applied to "any quoted text"
    ///     - rangeStylesMap: A Dictionary object mapping NotificationBlock types to a dictionary of styles
    ///                       to be applied.
    ///     - linksColor: The color that should be used on any links contained.
    ///
    /// - Returns: A NSAttributedString instance, formatted with all of the specified parameters
    ///
    private func textWithStyles(attributes  : [String: AnyObject],
                                quoteStyles : [String: AnyObject]?,
                             rangeStylesMap : [NotificationRange.Kind: [String: AnyObject]]?,
                                 linksColor : UIColor?) -> NSAttributedString
    {
        // Is it empty?
        guard let text = text else {
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

        for range in ranges {
            var shiftedRange        = range.range
            shiftedRange.location   += lengthShift

            if range.kind == .Noticon {
                let noticon         = (range.value ?? String()) + " "
                theString.replaceCharactersInRange(shiftedRange, withString: noticon)
                lengthShift         += noticon.characters.count
                shiftedRange.length += noticon.characters.count
            }

            if let unwrappedRangeStyle = rangeStylesMap?[range.kind] {
                theString.addAttributes(unwrappedRangeStyle, range: shiftedRange)
            }

            if let rangeURL = range.url, let linksColor = linksColor {
                theString.addAttribute(NSLinkAttributeName, value: rangeURL, range: shiftedRange)
                theString.addAttribute(NSForegroundColorAttributeName, value: linksColor, range: shiftedRange)
            }
        }

        return theString
    }


    // MARK: - Constants
    //
    private struct Constants {
        static let subjectRangeStylesMap: [NotificationRange.Kind: [String: AnyObject]] = [
            .User               : Styles.subjectBoldStyle,
            .Post               : Styles.subjectItalicsStyle,
            .Comment            : Styles.subjectItalicsStyle,
            .Blockquote         : Styles.subjectQuotedStyle,
            .Noticon            : Styles.subjectNoticonStyle
        ]

        static let headerTitleRangeStylesMap: [NotificationRange.Kind: [String: AnyObject]] = [
            .User               : Styles.headerTitleBoldStyle,
            .Post               : Styles.headerTitleContextStyle,
            .Comment            : Styles.headerTitleContextStyle
        ]

        static let footerStylesMap: [NotificationRange.Kind: [String: AnyObject]] = [
            .Noticon            : Styles.blockNoticonStyle
        ]

        static let richRangeStylesMap: [NotificationRange.Kind: [String: AnyObject]] = [
            .Blockquote         : Styles.contentBlockQuotedStyle,
            .Noticon            : Styles.blockNoticonStyle,
            .Match              : Styles.contentBlockMatchStyle
        ]

        static let badgeRangeStylesMap: [NotificationRange.Kind: [String: AnyObject]] = [
            .User               : Styles.badgeBoldStyle,
            .Post               : Styles.badgeItalicsStyle,
            .Comment            : Styles.badgeItalicsStyle,
            .Blockquote         : Styles.badgeQuotedStyle
        ]

        static let richSubjectCacheKey      = "richSubjectCacheKey"
        static let richSnippetCacheKey      = "richSnippetCacheKey"
        static let richHeaderTitleCacheKey  = "richHeaderTitleCacheKey"
        static let richTextCacheKey         = "richTextCacheKey"
        static let richBadgeCacheKey        = "richBadgeCacheKey"
    }

    private typealias Styles                = WPStyleGuide.Notifications
}
