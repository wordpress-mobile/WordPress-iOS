import UIKit

/// WPContentSearchHelper is a helper class to encapsulate searches over a time interval.
///
/// The helper is configured with an interval and callback to call once the time elapses.
/// The helper automatically cancels pending callbacks when a new text update is incurred.
class WPContentSearchHelper: NSObject {

    /// The current searchText set on the helper.
    var searchText:String? = nil

    // MARK: - Methods for configuring the timing of search callbacks.

    private var observers = [WPContentSearchObserver]()
    private let defaultDeferredSearchObservationInterval = NSTimeInterval(0.30)

    func configureImmediateSearch(handler: ()->Void) {
        let observer = WPContentSearchObserver()
        observer.interval = 0.0
        observer.completion = handler
        observers.append(observer)
    }

    /// Add a search callback configured as a common deferred search.
    func configureDeferredSearch(handler: ()->Void) {
        let observer = WPContentSearchObserver()
        observer.interval = defaultDeferredSearchObservationInterval
        observer.completion = handler
        observers.append(observer)
    }

    /// Remove any current configuration, such as local and remote search callbacks.
    func resetConfiguration() {
        stopAllObservers()
        observers.removeAll()
    }

    // MARK: - Methods for updating the search.

    /// Update the current search text, ideally in real-time along with user input.
    func searchUpdated(text: String?) {
        stopAllObservers()
        searchText = text ?? ""
        guard let updatedText = text where !updatedText.isEmpty else {
            return
        }
        for observer in observers {
            observer.timer = NSTimer.scheduledTimerWithTimeInterval(observer.interval, target: observer, selector: #selector(WPContentSearchObserver.timerFired), userInfo: nil, repeats: false)
        }
    }

    /// Cancel the current search and any pending callbacks.
    func searchCanceled() {
        stopAllObservers()
    }

    // MARK: - Private Methods

    /// Stop the observers from firing.
    private func stopAllObservers() {
        for observer in observers {
            observer.timer?.invalidate()
            observer.timer = nil
        }
    }
}

// MARK: - Private Classes

/// Object encapsulating the callback and timing information.
private class WPContentSearchObserver: NSObject {

    var interval = NSTimeInterval(0.0)
    var timer:NSTimer? = nil
    var completion:()->Void = {}

    @objc func timerFired() {
        completion()
    }
}
