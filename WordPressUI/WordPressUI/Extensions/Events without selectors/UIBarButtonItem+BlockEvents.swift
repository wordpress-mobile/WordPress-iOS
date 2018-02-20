// Adding UIBarButtonItem

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

    /// Listen for `UIControlEvents` executing the provided closure when triggered
    public func on(call closure: @escaping (Self) -> Void) {
        let handler = BarButtonItemEventHandler<Self>(sender: self, events: .touchUpInside, closure: closure)
        self.controlEventHandlers.append(handler)
    }
}

