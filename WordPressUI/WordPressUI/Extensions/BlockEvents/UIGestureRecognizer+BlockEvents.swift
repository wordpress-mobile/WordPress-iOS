/// Allows UIBarButtonItem to handle events programatically without using selectors or @objc

private final class UITapGestureRecognizerEventHandler<Sender: UITapGestureRecognizer>: NSObject {
    let closure: (Sender) -> Void

    init(sender: Sender, closure: @escaping (Sender) -> Void) {
        self.closure = closure
        super.init()

        sender.addTarget(self, action: #selector(self.action))
    }

    @objc private func action(sender: UITapGestureRecognizer) {
        guard let sender = sender as? Sender else { return }

        self.closure(sender)
    }
}

extension UITapGestureRecognizer: ControlEventBindable {}

extension ControlEventBindable where Self: UITapGestureRecognizer {
    private var controlEventHandlers: [UITapGestureRecognizerEventHandler<Self>] {
        get { return (objc_getAssociatedObject(self, &BlockEventKeys.ControlEventHandlers) as? [UITapGestureRecognizerEventHandler<Self>]) ?? [] }
        set { objc_setAssociatedObject(self, &BlockEventKeys.ControlEventHandlers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Set the event handler on this UITapGestureRecognizer without using selectors
    ///
    /// - Parameter closure: the closure to call when the gesture is taped
    /// - Note: this allows swift classes without @objc to create UITapGestureRecognizers
    public func on(call closure: @escaping (Self) -> Void) {
        let handler = UITapGestureRecognizerEventHandler<Self>(sender: self, closure: closure)
        self.controlEventHandlers.append(handler)
    }
}
