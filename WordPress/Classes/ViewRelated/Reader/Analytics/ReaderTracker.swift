import Foundation

class ReaderTracker {
    enum Section: String {
        /// Time spent in the main Reader view (the one with the tabs)
        case main = "time_in_main_reader"

        /// Time spent in the Following tab with an active filter
        case filteredList = "time_in_reader_filtered_list"

        /// Time spent reading article
        case readerPost = "time_in_reader_post"
    }

    func data() -> [String: Double] {
        return [
            Section.main.rawValue: 0,
            Section.filteredList.rawValue: 0,
            Section.readerPost.rawValue: 0
        ]
    }
}
