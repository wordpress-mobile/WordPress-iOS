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
    case view
    case publish
    case stats
    case duplicate
    case moveToDraft
    case trash
    case delete
    case share
    case blaze
    case comments
    case settings

    /// Specific to pages
    case pageAttributes
    case setHomepage
    case setPostsPage
    case setRegularPage
}
