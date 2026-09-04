import Foundation
import UIKit
import WordPressShared
import WordPressSharedObjCUI

/// UIKit-dependent additions to `RichContentFormatter`.
///
/// The platform-independent text transformations live in `WordPressShared`. The
/// display pipeline below depends on the screen (for gallery image sizing) and on
/// `WordPressSharedObjCUI`'s Photon helper, so it stays in the UI layer.
///
extension RichContentFormatter {

    /// Formats the specified content string for display. Forbidden HTML tags are
    /// removed, paragraphs are normalized, etc.
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///     - isPrivate: Whether the content is from a private blog.
    ///
    /// - Returns: The formatted string.
    ///
    @objc public class func formatContentString(_ string: String, isPrivateSite isPrivate: Bool) -> String {
        guard !string.isEmpty else {
            return string
        }

        var content = string
        content = removeForbiddenTags(content)
        content = normalizeParagraphs(content)
        content = removeInlineStyles(content)
        content = (content as NSString).replacingHTMLEmoticonsWithEmoji() as String
        content = formatGutenbergGallery(content)
        content = resizeGalleryImageURL(content, isPrivateSite: isPrivate)
        content = formatVideoTags(content)
        return content
    }

    /// Mutates gallery image URLs to be correctly sized.
    ///
    /// - Parameters:
    ///     - string: The content string to format.
    ///     - isPrivate: Whether the content is from a private blog.
    ///
    /// - Returns: The formatted string.
    ///
    @objc public class func resizeGalleryImageURL(_ string: String, isPrivateSite isPrivate: Bool) -> String {
        guard !string.isEmpty else {
            return string
        }

        let imageSize = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        let scaledSize = imageSize.applying(CGAffineTransform(scaleX: scale, y: scale))

        let mContent = NSMutableString(string: string)

        let matches = RegEx.galleryImgTags.matches(
            in: mContent as String,
            options: [],
            range: NSRange(location: 0, length: mContent.length)
        )

        for match in matches.reversed() {
            let imgElementStr = mContent.substring(with: match.range)
            let srcImgURLStr = parseValueForAttribute("src", inElement: imgElementStr)
            let originalImgURLStr = parseValueForAttribute("data-orig-file", inElement: imgElementStr)

            guard let originalURL = URL(string: originalImgURLStr) else {
                continue
            }

            var modifiedURL: URL
            if isPrivate {
                modifiedURL = WPImageURLHelper.imageURLWithSize(scaledSize, forImageURL: originalURL)
            } else {
                modifiedURL = PhotonImageURLHelper.photonURL(with: imageSize, forImageURL: originalURL)
            }

            guard modifiedURL.absoluteString.isEmpty() == false else {
                continue
            }

            let mImageStr = NSMutableString(string: imgElementStr)
            mImageStr.replaceOccurrences(
                of: "src=\"\(srcImgURLStr)\"",
                with: "src=\"\(modifiedURL.absoluteString)\"",
                options: .literal,
                range: NSRange(location: 0, length: imgElementStr.utf16.count)
            )

            mContent.replaceCharacters(in: match.range, with: mImageStr as String)
        }

        return mContent as String
    }
}
