import Foundation

enum BlogHighlight: Equatable {

    case followers(Int)
    case drafts(Int)
    case views(Int)

    var title: String {
        switch self {
        case .followers(let count):
            return "\(count) followers"
        case .drafts(let count):
            return "\(count) drafts"
        case .views(let delta):
            return "Views \(abs(delta))%"
        }
    }

    var icon: UIImage {
        switch self {
        case .followers:
            return UIImage.gridicon(.user)
        case .drafts:
            return UIImage.gridicon(.posts)
        case .views(let delta):
            return delta >= 0 ? UIImage.gridicon(.arrowUp) : UIImage.gridicon(.arrowDown)
        }
    }

    var iconColor: UIColor {
        switch self {
        case .followers, .drafts:
            return UIColor.text
        case .views(let delta):
            return delta >= 0 ? UIColor.success : UIColor.error
        }
    }
}
