class DefaultFormattableContentAction: FormattableContentAction {
    var enabled: Bool

    var on: Bool {
        didSet {
            command?.on = on
        }
    }

    private(set) var command: FormattableContentActionCommand?

    var identifier: Identifier {
        return type(of: self).actionIdentifier()
    }

    init(on: Bool, command: FormattableContentActionCommand) {
        self.on = on
        self.enabled = true
        self.command = command
    }

    func execute(context: ActionContext) {
        command?.execute(context: context)
    }
}

final class ApproveCommentAction: DefaultFormattableContentAction { }
final class FollowAction: DefaultFormattableContentAction { }
final class LikeCommentAction: DefaultFormattableContentAction { }
final class ReplyToCommentAction: DefaultFormattableContentAction { }
final class MarkAsSpamAction: DefaultFormattableContentAction { }
final class TrashCommentAction: DefaultFormattableContentAction { }
final class LikePostAction: DefaultFormattableContentAction { }
final class EditCommentAction: DefaultFormattableContentAction { }
