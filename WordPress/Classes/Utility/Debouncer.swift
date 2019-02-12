import Foundation

//From : https://github.com/webadnan/swift-debouncer

final class Debouncer {
    var callback: (() -> Void)
    var delay: Double
    weak var timer: Timer?

    init(delay: Double, callback: @escaping (() -> Void)) {
        self.delay = delay
        self.callback = callback
    }

    deinit {
        if let timer = timer, timer.fireDate >= Date() {
            timer.fire()
        }
    }

    func call() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] timer in
            self?.callback()
        }
    }
}
