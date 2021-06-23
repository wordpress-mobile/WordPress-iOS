import Foundation

final class ReferrerDetailsViewModel {
    // TODO: implement
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
