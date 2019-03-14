import Foundation

//From : https://github.com/webadnan/swift-debouncer

/// This class de-bounces the execution of a provided callback.
/// It also offers a mechanism to immediately trigger the scheduled call if necessary.
///
final class Debouncer {
    private let callback: (() -> Void)
    private let delay: Double
    private var timer: Timer?

    // MARK: - Init & deinit

    init(delay: Double, callback: @escaping (() -> Void)) {
        self.delay = delay
        self.callback = callback
    }

    deinit {
        if let timer = timer, timer.fireDate >= Date() {
            timer.invalidate()
            callback()
        }
    }

    // MARK: - Debounce Request

    func call(immediate: Bool = false) {
        timer?.invalidate()

        if immediate {
            immediateCallback()
        } else {
            scheduleCallback()
        }
    }

    // MARK: - Callback interaction

    private func immediateCallback() {
        timer = nil
        callback()
    }

    private func scheduleCallback() {
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [callback] timer in
            callback()
        }
    }
}
