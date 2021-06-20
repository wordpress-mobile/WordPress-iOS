import Foundation

final class ReferrerDetailsViewModel {
    
}

// MARK: - Public Computed Properties
extension ReferrerDetailsViewModel {
    var tableViewModel: ImmuTable {
        var rows = [ImmuTableRow]()

        rows.append(ReferrerDetailsHeaderRow())

        return ImmuTable(sections: [
            ImmuTableSection(rows: rows)
        ])
    }
}
