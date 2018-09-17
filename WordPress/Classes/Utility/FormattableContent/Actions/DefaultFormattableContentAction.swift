class DefaultFormattableContentAction: FormattableContentAction {
    var enabled: Bool

    var on: Bool {
        set {
            command?.on = newValue
        }

        get {
            return command?.on ?? false
        }
    }

    private(set) var command: FormattableContentActionCommand?

    var identifier: Identifier {
        return type(of: self).actionIdentifier()
    }

    init(on: Bool, command: FormattableContentActionCommand) {
        self.enabled = true
        self.command = command
        self.on = on
    }

    func execute<ContentType: FormattableContent>(context: ActionContext<ContentType>) {
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
