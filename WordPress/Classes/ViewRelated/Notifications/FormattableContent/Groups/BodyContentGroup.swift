
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

        return blocks.enumerated().map { index, block in
            let isFooter = parentMayContainFooter && block.type == "text" && index == blocks.count - 1
            if isFooter {
                return FooterContentGroup(blocks: [block])
            }
            return FormattableContentGroup(blocks: [block], kind: .text)
        }
    }

    private class func groupsForCommentBodyBlocks(_ blocks: [FormattableContent], parent: FormattableContentParent) -> [FormattableContentGroup] {

//        guard let comment = blockOfKind(.comment, from: blocks), let user = blockOfKind(.user, from: blocks) else {
        guard let comment = blockOfType(FormattableCommentContent.self, from: blocks), let user = blockOfType(FormattableUserContent.self, from: blocks) else {
            return []
        }

        var groups = [FormattableContentGroup]()
        let commentGroupBlocks: [FormattableContent] = [comment, user]

        let middleGroupBlocks = contentFrom(blocks, differentThan: comment, and: user)
        
        let actionGroupBlocks   = [comment]

        // Comment Group: Comment + User Blocks
        groups.append(FormattableContentGroup(blocks: commentGroupBlocks, kind: .comment))

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
                groups.append(FormattableContentGroup(blocks: [block], kind: .text))
            }
        }

        // Whenever Possible *REMOVE* this workaround. Pingback Notifications require a locally generated block.
        //
        if parent.isPingback, let homeURL = user.metaLinksHome {
            let blockGroup = pingbackReadMoreGroup(for: homeURL)
            groups.append(blockGroup)
        }

        // Actions Group: A copy of the Comment Block (Actions)
        groups.append(FormattableContentGroup(blocks: actionGroupBlocks, kind: .actions))

        return groups
    }

    private class func contentFrom(_ content: [FormattableContent], differentThan comment: FormattableCommentContent, and user: FormattableUserContent) -> [FormattableContent] {
        return content.filter { block in
            if let theComment = block as? FormattableCommentContent {
                return theComment != comment
            } else if let theUser = block as? FormattableUserContent {
                return theUser != user
            }
            return true
        }
    }

    public class func pingbackReadMoreGroup(for url: URL) -> FormattableContentGroup {
        let text = NSLocalizedString("Read the source post", comment: "Displayed at the footer of a Pingback Notification.")
        let textRange = NSRange(location: 0, length: text.count)
        let zeroRange = NSRange(location: 0, length: 0)

        let ranges = [
            FormattableContentRange(kind: .Noticon, range: zeroRange, value: "\u{f442}"),
            FormattableContentRange(kind: .Link, range: textRange, url: url)
        ]

        let block = FormattableTextContent(text: text, ranges: ranges)
        return FooterContentGroup(blocks: [block])
    }
}
