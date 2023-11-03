import Foundation

protocol AbstractPostMenuViewModel {
    var buttonSections: [AbstractPostButtonSection] { get }
}

struct AbstractPostButtonSection {
    let buttons: [AbstractPostButton]
    let submenuButton: AbstractPostButton?

    init(buttons: [AbstractPostButton], submenuButton: AbstractPostButton? = nil) {
        self.buttons = buttons
        self.submenuButton = submenuButton
    }
}

enum AbstractPostButton: Equatable {
    case retry
    case view
    case publish
    case stats
    case duplicate
    case moveToDraft
    case trash
    case cancelAutoUpload
    case share
    case blaze
    case comments

    /// Specific to pages
    case pageAttributes
    case setParent(IndexPath)
    case setHomepage
    case setPostsPage
}
