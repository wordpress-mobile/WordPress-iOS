/// Abstracts contextual actions that can be applied to FormattableContent.
/// i.e. the actions applied to notifications (Approve, Mark a comment as Spam)

protocol FormattableContentActionCommand: CustomStringConvertible {
    var identifier: Identifier { get }
    var icon: UIButton? { get }
    var on: Bool { get set }

    func execute(context: ActionContext)
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
