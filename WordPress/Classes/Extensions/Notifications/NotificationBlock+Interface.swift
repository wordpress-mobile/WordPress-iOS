import Foundation
import WordPressShared.WPStyleGuide



/// This Extension implements helper methods to aid formatting a NotificationBlock's payload,
/// for usage in several different spots of the app.
/// For performance purposes, Attributed Strings get temporarily cached... and will get nuked whenever the
/// related Notification object gets updated.
///
extension NotificationBlock
{
    /// Formats a NotificationBlock for usage in NoteTableViewCell, in the subject field
    ///
    var attributedSubjectText: NSAttributedString {
        let attributedText = memoize {
            let subject = self.textWithStyles(Styles.subjectRegularStyle,
                quoteStyles:    Styles.subjectItalicsStyle,
                rangeStylesMap: Constants.subjectRangeStylesMap,
                linksColor:     nil)

            return subject.trimNewlines()
        }

        return attributedText(MemoizeKeys.subject)
    }

    /// Formats a NotificationBlock for usage in NoteTableViewCell, in the snippet field
    ///
    var attributedSnippetText: NSAttributedString {
        let attributedText = memoize {
            let snippet = self.textWithStyles(Styles.snippetRegularStyle,
                quoteStyles:    nil,
                rangeStylesMap: nil,
                linksColor:     nil)

            return snippet.trimNewlines()
        }

        return attributedText(MemoizeKeys.snippet)
    }

    /// Formats a NotificationBlock for usage in NoteBlockHeaderTableViewCell
    ///
    var attributedHeaderTitleText: NSAttributedString {
        let attributedText = memoize {
            return self.textWithStyles(Styles.headerTitleRegularStyle,
                quoteStyles:    nil,
                rangeStylesMap: Constants.headerTitleRangeStylesMap,
                linksColor:     nil)
        }

        return attributedText(MemoizeKeys.headerTitle)
    }

    /// Formats a NotificationBlock for usage in NoteBlockFooterTableViewCell
    ///
    var attributedFooterText: NSAttributedString {
        let attributedText = memoize {
            return self.textWithStyles(Styles.footerRegularStyle,
                quoteStyles:    nil,
                rangeStylesMap: Constants.footerStylesMap,
                linksColor:     nil)
        }

        return attributedText(MemoizeKeys.footer)
    }

    /// Formats a NotificationBlock for usage into both, NoteBlockTextTableViewCell and NoteBlockCommentTableViewCell.
    ///
    var attributedRichText: NSAttributedString {
        // Operations such as editing a comment may complete way before the Notification is updated.
        // TextOverride is a transient property meant to store, temporarily, the edited text
        if let textOverride = textOverride {
            return NSAttributedString(string: textOverride, attributes: Styles.contentBlockRegularStyle)
        }

        let attributedText = memoize {
            return self.textWithStyles(Styles.contentBlockRegularStyle,
                quoteStyles:    Styles.contentBlockBoldStyle,
                rangeStylesMap: Constants.richRangeStylesMap,
                linksColor:     Styles.blockLinkColor)
        }

        return attributedText(MemoizeKeys.text)
    }

    /// Formats a NotificationBlock for usage into Badge-Type notifications. This contains custom
    /// formatting that differs from regular notifications, such as centered texts.
    ///
    var attributedBadgeText: NSAttributedString {
        let attributedText = memoize {
            return self.textWithStyles(Styles.badgeRegularStyle,
                quoteStyles:    Styles.badgeBoldStyle,
                rangeStylesMap: Constants.badgeRangeStylesMap,
                linksColor:     Styles.badgeLinkColor)
        }

        return attributedText(MemoizeKeys.badge)
    }


    /// Given a set of URL's and the Images they reference to, this method will return a Dictionary
    /// with the NSRange's in which the given UIImage's should be injected.
    ///
    /// **Note:** If we've got a text override: Ranges may not match, and the new text may not even contain ranges!
    ///
    /// - Parameter mediaMap: A Dictionary mapping asset URL's to the already-downloaded assets
    ///
    /// - Returns: A Dictionary mapping Text-Ranges in which the UIImage's should be applied
    ///
    func buildRangesToImagesMap(mediaMap: [NSURL: UIImage]) -> [NSValue: UIImage]? {
        guard textOverride == nil else {
            return nil
        }

        var ranges = [NSValue: UIImage]()

        for theMedia in media {
            guard let mediaURL = theMedia.mediaURL else {
                continue
            }

            if let image = mediaMap[mediaURL] {
                let rangeValue      = NSValue(range: theMedia.range)
                ranges[rangeValue]  = image
            }
        }

        return ranges
    }
}



// MARK: - Private Helpers
//
extension NotificationBlock
{
    /// This method is meant to aid cache-implementation into all of the AttriutedString getters introduced
    /// in this extension.
    ///
    /// - Parameter fn: A Closure that, on execution, returns an attributed string.
    ///
    /// - Returns: A new Closure that on execution will either hit the cache, or execute the closure `fn`
    ///            and store its return value in the cache.
    ///
    private func memoize(fn: () -> NSAttributedString) -> String -> NSAttributedString {
        return { cacheKey in

            if let cachedSubject = self.cacheValueForKey(cacheKey) as? NSAttributedString {
                return cachedSubject
            }

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
        guard let text = text else {
            return NSAttributedString()
        }

        let theString = NSMutableAttributedString(string: text, attributes: attributes)

        if let quoteStyles = quoteStyles {
            theString.applyAttributesToQuotes(quoteStyles)
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

            if let rangeStyle = rangeStylesMap?[range.kind] {
                theString.addAttributes(rangeStyle, range: shiftedRange)
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
    }

    private struct MemoizeKeys {
        static let subject      = "subject"
        static let snippet      = "snippet"
        static let headerTitle  = "headerTitle"
        static let footer       = "footer"
        static let text         = "text"
        static let badge        = "badge"
    }

    private typealias Styles    = WPStyleGuide.Notifications
}
