import Foundation


extension NotificationBlock
{
    public func subjectAttributedText() -> NSAttributedString {
        return textWithRangeStyles(isSubject: true, mediaMap: nil)
    }

    public func snippetAttributedText() -> NSAttributedString {
        if text == nil {
            return NSAttributedString()
        }

        return NSAttributedString(string: text, attributes: Styles.snippetRegularStyle)
    }

    public func richAttributedTextWithEmbeddedImages(mediaMap: [NSURL: UIImage]?) -> NSAttributedString {
        //  Operations such as editing a comment cause a lag between the REST and Simperium update.
        //  TextOverride is a transient property meant to store, temporarily, the edited text
        if textOverride != nil {
            return NSAttributedString(string: textOverride, attributes: Styles.blockRegularStyle)
        }
        
        return textWithRangeStyles(isSubject: false, mediaMap: mediaMap)
    }
    
    
    // MARK: - Private Helpers
    private func textWithRangeStyles(#isSubject: Bool, mediaMap: [NSURL: UIImage]?) -> NSAttributedString {
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

        // Embed the images, if needed
        if mediaMap == nil {
            return theString
        }
        
        let unwrappedMediaMap = mediaMap!
        for theMedia in media as [NotificationMedia] {
            
            let image = unwrappedMediaMap[theMedia.mediaURL]
            if theMedia.isImage == false || image == nil {
                continue
            }
            
            let imageAttachment     = NSTextAttachment()
            imageAttachment.bounds  = CGRect(origin: CGPointZero, size: image!.size)
            imageAttachment.image   = image!
            
            let attachmentString    = NSAttributedString(attachment: imageAttachment)
            theString.replaceCharactersInRange(theMedia.range, withAttributedString: attachmentString)
        }
        
        return theString;
    }
    
    
    private typealias Styles = WPStyleGuide.Notifications
}
