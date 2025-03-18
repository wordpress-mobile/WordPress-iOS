import UIKit
import WordPressShared
import WordPressUI

/// This class groups all of the styles used by all of the CommentsViewController.
///
extension WPStyleGuide {
    public struct Comments {

        static let gravatarPlaceholderImage = UIImage(named: "gravatar") ?? UIImage()
        static let pendingIndicatorColor = UIAppColor.yellow(.shade20)
    }
}
