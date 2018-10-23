import Foundation

//From : https://github.com/webadnan/swift-debouncer

final class Debouncer {
    var callback: (() -> Void)?
    var delay: Double
    weak var timer: Timer?

    init(delay: Double, callback: (() -> Void)? = nil) {
        self.delay = delay
        self.callback = callback
    }

    func call() {
        timer?.invalidate()
        let nextTimer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(Debouncer.fireNow), userInfo: nil, repeats: false)
        timer = nextTimer
    }

    @objc func fireNow() {
        self.callback?()
    }
}
