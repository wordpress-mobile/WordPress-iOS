/// Abstracts the logic behind contextual actions that can be applied to FormattableContent.
/// i.e. the actions applied to notifications (Approve, Mark a comment as Spam)

protocol FormattableContentActionCommand: CustomStringConvertible {
    var identifier: Identifier { get }
    var on: Bool { get set }

    func action(handler: @escaping UIContextualAction.Handler) -> UIContextualAction?
    func execute<ContentType: FormattableContent>(context: ActionContext<ContentType>)
}

extension FormattableContentActionCommand {
    static func commandIdentifier() -> Identifier {
        return Identifier(value: String(describing: self))
    }
}

extension FormattableContentActionCommand {
    var description: String {
        return identifier.description
    }
}
