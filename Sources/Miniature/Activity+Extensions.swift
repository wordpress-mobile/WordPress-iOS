import SwiftUI
import Gridicons
import DesignSystem
import WordPressKit

extension Activity {
    /// Returns an AttributedString with clickable links based on content ranges
    var formattedContent: AttributedString? {
        guard let content = content,
              let text = content["text"] as? String,
              !text.isEmpty else {
            return nil
        }
        
        var attributedString = AttributedString(text)
        
        // Apply links from ranges if available
        if let ranges = content["ranges"] as? [[String: Any]] {
            for range in ranges {
                guard let indices = range["indices"] as? [NSNumber],
                      indices.count == 2,
                      let urlString = range["url"] as? String,
                      let url = URL(string: urlString) else {
                    continue
                }
                
                let startIndex = indices[0].intValue
                let endIndex = indices[1].intValue

                // Convert string indices to AttributedString indices
                guard startIndex >= 0,
                      endIndex <= text.count,
                      startIndex < endIndex else {
                    continue
                }
                
                // Convert character indices to AttributedString.Index
                let stringStartIndex = text.index(text.startIndex, offsetBy: startIndex)
                let stringEndIndex = text.index(text.startIndex, offsetBy: endIndex)
                
                // Find corresponding indices in AttributedString
                guard let attrStartIndex = AttributedString.Index(stringStartIndex, within: attributedString),
                      let attrEndIndex = AttributedString.Index(stringEndIndex, within: attributedString) else {
                    continue
                }
                
                // Apply the link attribute to the exact range
                attributedString[attrStartIndex..<attrEndIndex].link = url
            }
        }
        
        return attributedString
    }

    /// Returns the appropriate GridiconType for this activity, if available
    var gridiconType: GridiconType? {
        Self.stringToGridiconTypeMapping[gridicon]
    }

    /// Returns the icon image for this activity
    /// - Returns: A white-tinted gridicon image, or nil if no icon is available
    var icon: UIImage? {
        guard let gridiconType else {
            return nil
        }

        return UIImage.gridicon(gridiconType).imageWithTintColor(.white)
    }

    /// Returns the appropriate color based on the activity's status
    var statusColor: UIColor {
        switch status {
        case ActivityStatus.error:
            return UIAppColor.error
        case ActivityStatus.success:
            return UIAppColor.success
        case ActivityStatus.warning:
            return UIAppColor.warning
        default:
            return UIAppColor.neutral(.shade20)
        }
    }

    // MARK: - Private

    // We will be able to get rid of this disgusting dictionary once we build the
    // String->GridiconType mapping into the Gridicon module and we get a server side
    // fix to have all the names correctly mapping.
    private static let stringToGridiconTypeMapping: [String: GridiconType] = [
        "checkmark": .checkmark,
        "cloud": .cloud,
        "cog": .cog,
        "comment": .comment,
        "cross": .cross,
        "domains": .domains,
        "history": .history,
        "image": .image,
        "layout": .layout,
        "lock": .lock,
        "logout": .signOut,
        "mail": .mail,
        "menu": .menu,
        "my-sites": .mySites,
        "notice": .notice,
        "notice-outline": .noticeOutline,
        "pages": .pages,
        "plans": .plans,
        "plugins": .plugins,
        "posts": .posts,
        "share": .share,
        "shipping": .shipping,
        "spam": .spam,
        "themes": .themes,
        "trash": .trash,
        "user": .user,
        "video": .video,
        "status": .status,
        "cart": .cart,
        "custom-post-type": .customPostType,
        "multiple-users": .multipleUsers,
        "audio": .audio
    ]
}
