import UIKit

/// WPContentSearchHelper is a helper class to encapsulate searches over a time interval.
///
/// The helper is configured with an interval and callback to call once the time elapses.
/// The helper automatically cancels pending callbacks when a new text update is incurred.
class WPContentSearchHelper: NSObject {

    /// The current searchText set on the helper.
    @objc var searchText: String? = nil

    // MARK: - Methods for configuring the timing of search callbacks.

    fileprivate var observers = [WPContentSearchObserver]()
    fileprivate let defaultDeferredSearchObservationInterval = TimeInterval(0.30)

    @objc func configureImmediateSearch(_ handler: @escaping ()->Void) {
        let observer = WPContentSearchObserver()
        observer.interval = 0.0
        observer.completion = handler
        observers.append(observer)
    }

    /// Add a search callback configured as a common deferred search.
    @objc func configureDeferredSearch(_ handler: @escaping ()->Void) {
        let observer = WPContentSearchObserver()
        observer.interval = defaultDeferredSearchObservationInterval
        observer.completion = handler
        observers.append(observer)
    }

    /// Remove any current configuration, such as local and remote search callbacks.
    @objc func resetConfiguration() {
        stopAllObservers()
        observers.removeAll()
    }

    // MARK: - Methods for updating the search.

    /// Update the current search text, ideally in real-time along with user input.
    @objc func searchUpdated(_ text: String?) {
        stopAllObservers()
        searchText = text
        for observer in observers {
            let timer = Timer.init(timeInterval: observer.interval,
                                     target: observer,
                                     selector: #selector(WPContentSearchObserver.timerFired),
                                     userInfo: nil,
                                     repeats: false)
            RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
        }
    }

    /// Cancel the current search and any pending callbacks.
    @objc func searchCanceled() {
        stopAllObservers()
    }

    // MARK: - Private Methods

    /// Stop the observers from firing.
    fileprivate func stopAllObservers() {
        for observer in observers {
            observer.timer?.invalidate()
            observer.timer = nil
        }
    }
}

// MARK: - Private Classes

/// Object encapsulating the callback and timing information.
private class WPContentSearchObserver: NSObject {

    @objc var interval = TimeInterval(0.0)
    @objc var timer: Timer?
    @objc var completion = {}

    @objc func timerFired() {
        completion()
    }
}
