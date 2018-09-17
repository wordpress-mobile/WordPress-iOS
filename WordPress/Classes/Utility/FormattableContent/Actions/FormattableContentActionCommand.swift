/// Abstracts the logic behind contextual actions that can be applied to FormattableContent.
/// i.e. the actions applied to notifications (Approve, Mark a comment as Spam)

protocol FormattableContentActionCommand: CustomStringConvertible {
    var identifier: Identifier { get }
    var icon: UIButton? { get }
    var on: Bool { get set }

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

protocol AccessibleFormattableContentActionCommand {
    func setIconStrings(title: String, label: String, hint: String)
}

extension AccessibleFormattableContentActionCommand where Self: FormattableContentActionCommand {
    func setIconStrings(title: String, label: String, hint: String) {
        setIconTitle(title)
        setAccessibilityLabel(label)
        setAccessibilityHint(hint)
    }

    private func setIconTitle(_ title: String) {
        icon?.setTitle(title, for: .normal)
    }

    private func setAccessibilityLabel(_ label: String) {
        icon?.accessibilityLabel = label
    }

    private func setAccessibilityHint(_ hint: String) {
        icon?.accessibilityHint = hint
    }

}
