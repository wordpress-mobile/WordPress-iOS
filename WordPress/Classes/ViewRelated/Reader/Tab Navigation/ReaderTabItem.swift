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
            self.shouldHideButtonsView = content.type != .selfHostedFollowing
            self.shouldHideSettingsButton = content.type == .selfHostedFollowing
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
        case .selfHostedFollowing:
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
            // contentType != .topic if there is a topic is invalid -> contentType will be reset to .topic
            self.type = .topic
            return
        }
        // contentType == .topic without a topic is invalid -> content will be treated as invalid
        self.type = (topic == nil && contentType == .topic) ? .contentError : contentType
    }
}
