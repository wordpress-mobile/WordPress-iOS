import Foundation

struct LockScreenChartViewModel {
    struct Column: Hashable {
        let date: Date
        let value: Int

        var firstLetterOfWeekDay: String {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("EEE")
            return formatter.string(from: date).prefix(1).uppercased()
        }
    }

    let siteName: String
    let valueTitle: String
    let emptyChartTitle: String
    let columns: [Column]
    let updatedTime: Date
    var total: Int {
        return columns.map(\.value).reduce(0, +)
    }
}
