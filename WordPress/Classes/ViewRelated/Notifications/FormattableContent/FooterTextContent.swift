import Foundation

class FooterTextContent: FormattableTextContent {
    override init(text: String, ranges: [FormattableContentRange], actions: [FormattableContentAction]?) {
        if text == "You replied to this comment." {
            let localizedText = NSLocalizedString("You replied to this comment.", comment: "Notification text - below a comment notification detail")

            /// Now that we have localized the text, the clickable link range is not accurate
            /// and could cause an out-of-bounds error. Recalculate the range as the entire phrase.
            ///
            var modifiedRanges = [FormattableContentRange]()
            if let firstRange = ranges.first {
                modifiedRanges.append(firstRange)
            }

            if let secondItem = ranges.last as? NotificationCommentRange {
                let modifiedSecondRange = secondItem.rangeShifted(by: -secondItem.range.location)
                var properties = NotificationContentRange.Properties(range: modifiedSecondRange)
                    properties.url = secondItem.url
                    properties.siteID = secondItem.siteID
                    properties.userID = secondItem.userID
                    properties.postID = secondItem.postID

                let secondRange = NotificationContentRange(kind: .comment, properties: properties)
                modifiedRanges.append(secondRange)
            }
            super.init(text: localizedText, ranges: modifiedRanges, actions: actions)
        } else {
            super.init(text: text, ranges: ranges, actions: actions)
        }
    }
}
