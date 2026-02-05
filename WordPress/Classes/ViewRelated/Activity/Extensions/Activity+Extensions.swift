import SwiftUI
import Gridicons
import DesignSystem
import WordPressKit

extension Activity {

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
            return UIAppColor.neutral(.shade20)
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

// MARK: - Shared Strings

extension Activity {
    enum Strings {
        static let unknownUser = NSLocalizedString(
            "activity.unknownUser",
            value: "Unknown User",
            comment: "Placeholder text shown when the activity actor's display name is empty"
        )
    }
}
