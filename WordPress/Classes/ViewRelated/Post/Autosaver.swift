/// Post autosave helper that triggers an action after X ammount of changes or Y time of inactivity.
///
class Autosaver {
    private let action: (() -> Void)
    private let changesThreshold: Int
    private var changesCount = 0
    private let delay: Double
    private lazy var debouncer = Debouncer(delay: delay, callback: { [weak self] in
        self?.triggerAutosave()
    })

    private func triggerAutosave() {
        changesCount = 0
        action()
    }

    /// Instantiates an instance of Autosaver
    /// - Parameter changesThreshold: Ammount of changes allowed before autosaving. Default 50 changes.
    /// - Parameter delay: Maximum time of inactivity before autosaving. Default 1 second.
    /// - Parameter action: The action to be triggered when autosave is fired.
    ///
    init(changesThreshold: Int = 50, delay: Double = 1, action: @escaping () -> Void) {
        self.changesThreshold = changesThreshold
        self.action = action
        self.delay = delay
    }

    /// Call this method everytime the post content changes to trigger the autosave action at the most appropiate time
    ///
    func contentDidChange() {
        changesCount += 1
        if changesCount > changesThreshold {
            triggerAutosave()
        } else {
            debouncer.call()
        }
    }
}
