import Foundation

protocol AbstractPostMenuViewModel {
    var buttonSections: [AbstractPostButtonSection] { get }
}

struct AbstractPostButtonSection {
    let title: String?
    let buttons: [AbstractPostButton]
    let submenuButton: AbstractPostButton?

    init(title: String? = nil, buttons: [AbstractPostButton], submenuButton: AbstractPostButton? = nil) {
        self.title = title
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
    case retry
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
