import Foundation

class ReaderTracker {
    /// Time spent in the main Reader view (the one with the tabs)
    let timeInReader = "time_in_main_reader"

    /// Time spent in the Following tab with an active filter
    let timeInReaderFilteredList = "time_in_reader_filtered_list"

    /// Time spent reading article
    let timeInReaderPost = "time_in_reader_post"

    func data() -> [String: Double] {
        return [
            timeInReader: 0,
            timeInReaderFilteredList: 0,
            timeInReaderPost: 0
        ]
    }
}
