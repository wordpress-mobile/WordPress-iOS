
private enum Constants {
    /// Parsing Keys
    ///
    fileprivate enum BlockKeys {
        static let Actions      = "actions"
        static let Media        = "media"
        static let Meta         = "meta"
        static let Ranges       = "ranges"
        static let RawType      = "type"
        static let Text         = "text"
        static let UserType     = "user"
    }

    /// Meta Parsing Keys
    ///
    fileprivate enum MetaKeys {
        static let Ids          = "ids"
        static let Links        = "links"
        static let Titles       = "titles"
        static let Site         = "site"
        static let Post         = "post"
        static let Comment      = "comment"
        static let Reply        = "reply_comment"
        static let Home         = "home"
    }
}

class NotificationContentFactory: FormattableContentFactory {
    static func content(from blocks: [[String : AnyObject]], actionsParser parser: FormattableContentActionParser, parent: FormattableContentParent) -> [FormattableContent] {
        return blocks.compactMap {
            let actions = parser.parse($0[Constants.BlockKeys.Actions] as? [String: AnyObject])
            guard let type = $0[Constants.BlockKeys.RawType] as? String else {
                return DefaultFormattableContent(dictionary: $0, actions: actions, parent: parent)
            }
            if type == "comment" {
                return FormattableCommentContent(dictionary: $0, actions: actions, parent: parent)
            } else if type == "user" {
                return FormattableUserContent(dictionary: $0, actions: actions, parent: parent)
            }
            return DefaultFormattableContent(dictionary: $0, actions: actions, parent: parent)
        }
    }
}

class BodyContentGroup: FormattableContentGroup {
    class func create(from body: [[String: AnyObject]], parent: FormattableContentParent) -> [FormattableContentGroup] {
        let blocks = NotificationContentFactory.content(from: body, actionsParser: NotificationActionParser(), parent: parent)

        switch parent.kind {
        case .Comment:
            return groupsForCommentBodyBlocks(blocks, parent: parent)
        default:
            return groupsForNonCommentBodyBlocks(blocks, parent: parent)
        }
    }

    private class func groupsForNonCommentBodyBlocks(_ blocks: [FormattableContent], parent: FormattableContentParent) -> [FormattableContentGroup] {
        let parentKindsWithFooters: [ParentKind] = [.Follow, .Like, .CommentLike]
        let parentMayContainFooter = parentKindsWithFooters.contains(parent.kind)

        return blocks.map { block in
//            let isFooter = parentMayContainFooter && block.kind == .text && blocks.last == block
            let isFooter = false
            if isFooter {
                return FooterContentGroup(blocks: [block])
            }
            return FormattableContentGroup(blocks: [block])
        }
    }

    private class func groupsForCommentBodyBlocks(_ blocks: [FormattableContent], parent: FormattableContentParent) -> [FormattableContentGroup] {

//        guard let comment = blockOfKind(.comment, from: blocks), let user = blockOfKind(.user, from: blocks) else {
        guard let comment = blockOfType(FormattableCommentContent.self, from: blocks), let user = blockOfType(FormattableUserContent.self, from: blocks) else {
            return []
        }

        var groups = [FormattableContentGroup]()
        let commentGroupBlocks: [FormattableContent] = [comment, user]

        let middleGroupBlocks   = blocks.filter {
            if let theComment = $0 as? FormattableCommentContent {
                return theComment != comment
            } else if let theUser = $0 as? FormattableUserContent {
                return theUser != user
            }
            return false
        }
        
        let actionGroupBlocks   = [comment]

        // Comment Group: Comment + User Blocks
        groups.append(FormattableContentGroup(blocks: commentGroupBlocks))

        // Middle Group(s): Anything
        for block in middleGroupBlocks {
            // Duck Typing Again:
            // If the block contains a range that matches with the metaReplyID field, we'll need to render this
            // with a custom style. Translates into the `You replied to this comment` footer.
            //
            if let commentContent = block as? FormattableCommentContent,
                let parentReplyID = parent.metaReplyID,
                commentContent.formattableContentRangeWithCommentId(parentReplyID) != nil {

                groups.append(FooterContentGroup(blocks: [block]))
            } else {
                groups.append(FormattableContentGroup(blocks: [block]))
            }
        }

        // Whenever Possible *REMOVE* this workaround. Pingback Notifications require a locally generated block.
        //
        if parent.isPingback, let homeURL = user.metaLinksHome {
            let blockGroup = pingbackReadMoreGroup(for: homeURL)
            groups.append(blockGroup)
        }

        // Actions Group: A copy of the Comment Block (Actions)
        groups.append(FormattableContentGroup(blocks: actionGroupBlocks))

        return groups
    }

    public class func pingbackReadMoreGroup(for url: URL) -> FormattableContentGroup {
        let text = NSLocalizedString("Read the source post", comment: "Displayed at the footer of a Pingback Notification.")
        let textRange = NSRange(location: 0, length: text.count)
        let zeroRange = NSRange(location: 0, length: 0)

        let ranges = [
            FormattableContentRange(kind: .Noticon, range: zeroRange, value: "\u{f442}"),
            FormattableContentRange(kind: .Link, range: textRange, url: url)
        ]

        let block = DefaultFormattableContent(text: text, ranges: ranges)
        return FooterContentGroup(blocks: [block])
    }
}
