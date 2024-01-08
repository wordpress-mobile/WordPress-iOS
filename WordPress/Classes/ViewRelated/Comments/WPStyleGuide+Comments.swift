import Foundation

import WordPressShared

/// This class groups all of the styles used by all of the CommentsViewController.
///
extension WPStyleGuide {
    public struct Comments {

        static let gravatarPlaceholderImage = UIImage(named: "gravatar") ?? UIImage()
        static let pendingIndicatorColor = UIColor.muriel(color: MurielColor(name: .yellow, shade: .shade20))
    }
}
