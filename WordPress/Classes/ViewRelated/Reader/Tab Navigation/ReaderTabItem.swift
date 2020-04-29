struct ReaderTabItem: FilterTabBarItem {

    let shouldHideButtonsView: Bool
    let shouldHideSettingsButton: Bool

    let content: ReaderContent

    var accessibilityIdentifier: String {
        return title
    }

    /// initialize with topic
    init(_ content: ReaderContent) {
        self.content = content
        if let topic = content.topic {
            self.shouldHideButtonsView = !ReaderHelpers.topicIsFollowing(topic)
            self.shouldHideSettingsButton = false
        } else {
            self.shouldHideButtonsView = content.type != .emptyFollowing
            self.shouldHideSettingsButton = content.type == .emptyFollowing
        }
    }
}


// MARK: - Localized titles
extension ReaderTabItem {

    var title: String {
        switch content.type {
        case .topic:
            guard let topic = content.topic else {
                return ""
            }
            if ReaderHelpers.topicIsLiked(topic) {
                return NSLocalizedString("Likes", comment: "Title of the Likes Reader tab")
            } else if ReaderHelpers.topicIsFollowing(topic) {
                return NSLocalizedString("Following", comment: "Title of the Following Reader tab")
            } else {
                return topic.title
            }
        case .emptyFollowing:
            return NSLocalizedString("Following", comment: "Title of the Following Reader tab")
        case .saved:
            return NSLocalizedString("Saved", comment: "Title of the Saved Reader Tab")
        default:
            return ""
        }
    }
}


// MARK: - Reader Content
enum ReaderContentType {
    case emptyFollowing
    case contentError
    case saved
    case topic
}


struct ReaderContent {

    private(set) var topic: ReaderAbstractTopic?
    let type: ReaderContentType

    init(topic: ReaderAbstractTopic?, contentType: ReaderContentType = .topic) {

        if let topic = topic {
            self.topic = topic
            self.type = .topic
            return
        }
        self.type = contentType
    }
}
