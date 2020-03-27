enum ReaderSection: Int, FilterTabBarItem {
    case following
    case discover
    case likes
    case saved

    var title: String {
        switch self {
        case .following: return NSLocalizedString("Following", comment: "Title of the Following Reader tab")
        case .discover: return NSLocalizedString("Discover", comment: "Title of the Discover Reader tab")
        case .likes: return NSLocalizedString("Likes", comment: "Title of the Likes Reader tab")
        case .saved: return NSLocalizedString("Saved", comment: "Title of the Saved Reader tab")
        }
    }

    var shouldHideButtonsView: Bool {
        switch self {
        case .following:
            return false
        default:
            return true
        }
    }
}
