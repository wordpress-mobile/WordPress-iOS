struct ReaderTabItem: FilterTabBarItem {

    let shouldHideButtonsView: Bool
    let shouldHideSettingsButton: Bool
    let shouldHideTagFilter: Bool

    let content: ReaderContent

    var accessibilityIdentifier: String {
        return title
    }

    /// initialize with topic
    init(_ content: ReaderContent) {
        self.content = content
        let filterableTopicTypes = [ReaderTopicType.following, .organization]
        shouldHideButtonsView = !filterableTopicTypes.contains(content.topicType) && content.type != .selfHostedFollowing
        shouldHideSettingsButton = content.type == .selfHostedFollowing
        shouldHideTagFilter = content.topicType == .organization
    }
}


// MARK: - Localized titles
extension ReaderTabItem {

    var title: String {
        switch content.type {
        case .topic:
            switch content.topicType {
            case .following:
                return Titles.followingTitle
            case .likes:
                return Titles.likesTitle
            default:
                return content.topic?.title ?? Titles.emptyTitle
            }
        case .selfHostedFollowing:
            return Titles.followingTitle
        case .saved:
            return Titles.savedTitle
        default:
            return Titles.emptyTitle
        }
    }

    private enum Titles {
        static let followingTitle = NSLocalizedString("Following", comment: "Title of the Following Reader tab")
        static let likesTitle = NSLocalizedString("Likes", comment: "Title of the Likes Reader tab")
        static let savedTitle = NSLocalizedString("Saved", comment: "Title of the Saved Reader Tab")
        static let emptyTitle = ""
    }
}


// MARK: - Reader Content
enum ReaderContentType {
    case selfHostedFollowing
    case contentError
    case saved
    case topic
}


struct ReaderContent {

    private(set) var topic: ReaderAbstractTopic?
    let type: ReaderContentType
    let topicType: ReaderTopicType

    init(topic: ReaderAbstractTopic?, contentType: ReaderContentType = .topic) {
        self.topicType = ReaderHelpers.topicType(topic)

        if let topic = topic {
            self.topic = topic
            // if topic is not nil, contentType must be .topic.
            self.type = .topic
            return
        }
        // if topic is nil, passing contentType: .topic is invalid -> content will be treated as invalid
        self.type = (topic == nil && contentType == .topic) ? .contentError : contentType
    }
}
