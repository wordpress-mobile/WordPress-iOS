import Foundation

enum BlogHighlight: Equatable {

    case followers(Int)
    case drafts(Int)

    var title: String {
        switch self {
        case .followers(let count):
            return "\(count) followers"
        case .drafts(let count):
            return "\(count) drafts"
        }
    }

    var icon: UIImage {
        switch self {
        case .followers:
            return UIImage.gridicon(.user)
        case .drafts:
            return UIImage.gridicon(.posts)
        }
    }
}
