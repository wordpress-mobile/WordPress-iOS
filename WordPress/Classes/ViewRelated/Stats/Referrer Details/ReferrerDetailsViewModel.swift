import Foundation

final class ReferrerDetailsViewModel {
    private let data: StatsTotalRowData

    init(data: StatsTotalRowData) {
        self.data = data
    }
}

// MARK: - Public Computed Properties
extension ReferrerDetailsViewModel {
    var tableViewModel: ImmuTable {
        var rows = [ImmuTableRow]()

        rows.append(ReferrerDetailsHeaderRow())

        rows.append(ReferrerDetailsRow())
        rows.append(ReferrerDetailsRow())
        rows.append(ReferrerDetailsRow())
        rows.append(ReferrerDetailsRow(action: nil, isLast: true))

        return ImmuTable(sections: [
            ImmuTableSection(rows: rows),
            ImmuTableSection(rows: [ReferrerDetailsSpamActionRow(action: nil, isSpam: false)])
        ])
    }
}
