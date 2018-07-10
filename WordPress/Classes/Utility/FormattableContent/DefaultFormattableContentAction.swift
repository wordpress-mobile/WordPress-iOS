public class DefaultFormattableContentAction: FormattableContentAction {
    public var enabled: Bool 

    public var on: Bool {
        didSet {
            command?.on = on
        }
    }

    public private(set) var command: FormattableContentActionCommand?

    public var identifier: Identifier {
        return type(of: self).actionIdentifier()
    }

    public init(on: Bool, command: FormattableContentActionCommand) {
        self.on = on
        self.enabled = true
        self.command = command
    }

    public func execute(context: ActionContext) {
        command?.execute(context: context)
    }
}

public final class ApproveCommentAction: DefaultFormattableContentAction { }
public final class FollowAction: DefaultFormattableContentAction { }
public final class LikeCommentAction: DefaultFormattableContentAction { }
public final class ReplyToCommentAction: DefaultFormattableContentAction { }
public final class MarkAsSpamAction: DefaultFormattableContentAction { }
public final class TrashCommentAction: DefaultFormattableContentAction { }
public final class LikePostAction: DefaultFormattableContentAction { }
public final class EditCommentAction: DefaultFormattableContentAction { }
