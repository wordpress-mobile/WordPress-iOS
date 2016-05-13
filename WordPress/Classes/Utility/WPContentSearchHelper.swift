import UIKit

/// WPContentSearchHelper is a helper class to encapsulate searches over a time interval.
///
/// The helper is configured with an interval and callback to call once the time elapses.
/// The helper automatically cancels pending callbacks when a new text update is incurred.
class WPContentSearchHelper: NSObject {

    /// The current searchText set on the helper.
    var searchText:String? = nil

    /// Helper flag for when a remote search is processing.
    var isSearchingRemotely:Bool = false

    // MARK: - Methods for configuring the timing of search callbacks.

    private var observers:Array = [WPContentSearchObserver]()
    private let defaultRemoteObservationInterval = 0.30

    /// Add a search callback configured as a common remote search.
    func configureRemoteSearchWithCompletion(completion: ()->Void = {}) {
        let observer = WPContentSearchObserver()
        observer.interval = defaultRemoteObservationInterval
        observer.completion = completion
        observers.append(observer)
    }

    /// Remove any current configuration, such as local and search callbacks.
    func resetConfiguration() {
        stopAllObservers()
        observers.removeAll()
    }

    // MARK: - Methods for updating the search.

    /// Update the current search text, ideally in real-time along with user input.
    func searchingUpdatedWithSearchText(text:String?) {
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
    func searchingCanceled() {
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

    var interval:NSTimeInterval = 0.10
    var timer:NSTimer? = nil
    var completion:()->Void = {}

    @objc func timerFired() {
        completion()
    }
}
