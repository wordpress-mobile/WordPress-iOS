import Foundation

protocol AbstractPostMenuViewModel {
    var buttonSections: [AbstractPostButtonSection] { get }
}

struct AbstractPostButtonSection {
    let buttons: [AbstractPostButton]
}

enum AbstractPostButton {
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
}
