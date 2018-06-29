
class BodyContentGroup: FormattableContentGroup {
    class func create(from body: [[String: AnyObject]], parent: FormattableContentParent) -> [FormattableContentGroup] {
        let blocks = FormattableContent.blocksFromArray(body, actions: [], parent: parent)

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
            let isFooter = parentMayContainFooter && block.kind == .text && blocks.last == block
            if isFooter {
                return FooterContentGroup(blocks: [block])
            }
            return FormattableContentGroup(blocks: [block])
        }
    }

    private class func groupsForCommentBodyBlocks(_ blocks: [FormattableContent], parent: FormattableContentParent) -> [FormattableContentGroup] {

        guard let comment = blockOfKind(.comment, from: blocks), let user = blockOfKind(.user, from: blocks) else {
            return []
        }

        var groups              = [FormattableContentGroup]()
        let commentGroupBlocks  = [comment, user]
        let middleGroupBlocks   = blocks.filter { return commentGroupBlocks.contains($0) == false }
        let actionGroupBlocks   = [comment]

        // Comment Group: Comment + User Blocks
        groups.append(FormattableContentGroup(blocks: commentGroupBlocks))

        // Middle Group(s): Anything
        for block in middleGroupBlocks {
            // Duck Typing Again:
            // If the block contains a range that matches with the metaReplyID field, we'll need to render this
            // with a custom style. Translates into the `You replied to this comment` footer.
            //
            if let parentReplyID = parent.metaReplyID, block.formattableContentRangeWithCommentId(parentReplyID) != nil {
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

        let block = FormattableContent(text: text, ranges: ranges)
        return FooterContentGroup(blocks: [block])
    }
}
