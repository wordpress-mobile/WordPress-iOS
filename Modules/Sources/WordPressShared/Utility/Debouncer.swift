import Foundation

//From : https://github.com/webadnan/swift-debouncer

/// This class de-bounces the execution of a provided callback.
/// It also offers a mechanism to immediately trigger the scheduled call if necessary.
///
public final class Debouncer {
    private var callback: (() -> Void)?
    private let delay: Double
    private var timer: Timer?

    // MARK: - Init & deinit

    public init(delay: Double, callback: (() -> Void)? = nil) {
        self.delay = delay
        self.callback = callback
    }

    deinit {
        if let timer, timer.fireDate >= Date() {
            timer.invalidate()
            callback?()
        }
    }

    // MARK: - Debounce Request

    public func cancel() {
        timer?.invalidate()
    }

    public func call(immediate: Bool = false, callback: (() -> Void)? = nil) {
        timer?.invalidate()

        if let newCallback = callback {
            self.callback = newCallback
        }

        if immediate {
            immediateCallback()
        } else {
            scheduleCallback()
        }
    }

    // MARK: - Callback interaction

    private func immediateCallback() {
        timer = nil
        callback?()
    }

    private func scheduleCallback() {
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [callback] timer in
            callback?()
        }
    }
}
