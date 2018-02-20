/// Allows UIBarButtonItem to handle events programatically without using selectors or @objc

private final class BarButtonItemEventHandler<Sender: UIBarButtonItem>: NSObject {
    let closure: (Sender) -> Void

    init(sender: Sender, events: UIControlEvents, closure: @escaping (Sender) -> Void) {
        self.closure = closure
        super.init()

        sender.target = self
        sender.action = #selector(self.action)
    }

    @objc private func action(sender: UIBarButtonItem) {
        guard let sender = sender as? Sender else { return }

        self.closure(sender)
    }
}

extension UIBarButtonItem: ControlEventBindable { }

// MARK: - Implementation
extension ControlEventBindable where Self: UIBarButtonItem {
    private var controlEventHandlers: [BarButtonItemEventHandler<Self>] {
        get { return (objc_getAssociatedObject(self, &BlockEventKeys.ControlEventHandlers) as? [BarButtonItemEventHandler<Self>]) ?? [] }
        set { objc_setAssociatedObject(self, &BlockEventKeys.ControlEventHandlers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Set the event handler on this UIBarButtonItem without using selectors
    ///
    /// - Parameter closure: the closure to call when the button is taped
    /// - Note: this allows swift classes without @objc to create UIBarButtonItems
    public func on(call closure: @escaping (Self) -> Void) {
        let handler = BarButtonItemEventHandler<Self>(sender: self, events: .touchUpInside, closure: closure)
        self.controlEventHandlers.append(handler)
    }
}

