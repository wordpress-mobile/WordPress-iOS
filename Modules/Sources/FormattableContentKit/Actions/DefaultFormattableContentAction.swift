import Foundation

public class DefaultFormattableContentAction: FormattableContentAction {
    public var enabled: Bool

    public var on: Bool {
        set {
            command?.on = newValue
        }

        get {
            return command?.on ?? false
        }
    }

    private(set) public var command: FormattableContentActionCommand?

    public var identifier: Identifier {
        return type(of: self).actionIdentifier()
    }

    public init(on: Bool, command: FormattableContentActionCommand) {
        self.enabled = true
        self.command = command
        self.on = on
    }

    public func execute<ContentType: FormattableContent>(context: ActionContext<ContentType>) {
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
