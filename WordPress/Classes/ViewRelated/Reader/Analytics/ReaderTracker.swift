import Foundation

class ReaderTracker: NSObject {
    @objc static let shared = ReaderTracker()

    enum Section: String, CaseIterable {
        /// Time spent in the main Reader view (the one with the tabs)
        case main = "time_in_main_reader"

        /// Time spent in the Following tab with an active filter
        case filteredList = "time_in_reader_filtered_list"

        /// Time spent reading article
        case readerPost = "time_in_reader_post"
    }

    private var now: () -> Date
    private var startTime: [Section: Date] = [:]
    private var totalTimeInSeconds: [Section: TimeInterval] = [:]

    init(now: @escaping () -> Date = { return Date() }) {
        self.now = now
    }

    /// Returns a dictionary with a key and the time spent in that section
    @objc func data() -> [String: Double] {
        return Section.allCases.reduce([String: Double]()) { dict, section in
            var dict = dict
            dict[section.rawValue] = totalTimeInSeconds[section] ?? 0
            return dict
        }
    }

    /// Start counting time spent for a given section
    func start(_ section: Section) {
        guard startTime[section] == nil else {
            return
        }

        startTime[section] = now()
    }

    /// Stop counting time spent for a given section
    func stop(_ section: Section) {
        guard let startTime = startTime[section] else {
            return
        }

        let timeSince = now().timeIntervalSince(startTime)

        totalTimeInSeconds[section] = (totalTimeInSeconds[section] ?? 0) + round(timeSince)
        self.startTime.removeValue(forKey: section)
    }

    /// Stop counting time for all sections
    @objc func stopAll() {
        Section.allCases.forEach { stop($0) }
    }

    /// Stop counting time for all sections and reset them to zero
    @objc func reset() {
        startTime = [:]
        totalTimeInSeconds = [:]
    }
}
