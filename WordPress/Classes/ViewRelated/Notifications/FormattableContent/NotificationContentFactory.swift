
private enum Constants {
    static let Actions      = "actions"
    static let RawType      = "type"
}

extension Notification {
    enum ContentType: String {
        case comment
        case user
        case text
        case image
    }
}

class NotificationContentFactory: FormattableContentFactory {
    static func content(from blocks: [[String: AnyObject]], actionsParser parser: FormattableContentActionParser, parent: FormattableContentParent) -> [FormattableContent] {
        return blocks.compactMap { rawBlock in
            let actions = parser.parse(rawBlock[Constants.Actions] as? [String: AnyObject])
            guard let type = rawBlock[Constants.RawType] as? String else {
                return NotificationTextContent(dictionary: rawBlock, actions: actions, parent: parent)
            }
            return content(for: type, with: rawBlock, actions: actions, parent: parent)
        }
    }

    private static func content(for type: String, with rawBlock: [String: AnyObject], actions: [FormattableContentAction], parent: FormattableContentParent) -> FormattableContent? {
        guard let type = Notification.ContentType(rawValue: type) else {
            return NotificationTextContent(dictionary: rawBlock, actions: actions, parent: parent)
        }

        switch type {
        case .comment:
            return FormattableCommentContent(dictionary: rawBlock, actions: actions, parent: parent)
        case .user:
            return FormattableUserContent(dictionary: rawBlock, actions: actions, parent: parent)
        case .text:
            return NotificationTextContent(dictionary: rawBlock, actions: actions, parent: parent)
        case .image:
            return NotificationTextContent(dictionary: rawBlock, actions: actions, parent: parent)
        }
    }
}
