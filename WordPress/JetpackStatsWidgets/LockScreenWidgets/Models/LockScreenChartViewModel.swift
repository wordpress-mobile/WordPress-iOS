import Foundation

struct LockScreenChartViewModel {
    struct Column: Hashable {
        let date: Date
        let value: Int
    }

    let siteName: String
    let title: String
    let columns: [Column]
    let updatedTime: Date
    var total: Int {
        return columns.map(\.value).reduce(0, +)
    }
}
