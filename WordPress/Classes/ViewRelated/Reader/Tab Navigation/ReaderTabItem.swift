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

        self.shouldHideButtonsView = content.topicType != .following && content.type != .selfHostedFollowing
        self.shouldHideSettingsButton = content.type == .selfHostedFollowing
    }
}


// MARK: - Localized titles
extension ReaderTabItem {

    var title: String {
        switch content.type {
        case .topic:
            switch content.topicType {
            case .following:
                return NSLocalizedString("Following", comment: "Title of the Following Reader tab")
            case .likes:
                return NSLocalizedString("Likes", comment: "Title of the Likes Reader tab")
            default:
                return content.topic?.title ?? ""
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
            // if topic is not nil, contentType must be .topic.
            self.type = .topic
            return
        }
        // if topic is nil, passing contentType: .topic is invalid -> content will be treated as invalid
        self.type = (topic == nil && contentType == .topic) ? .contentError : contentType
    }
}
