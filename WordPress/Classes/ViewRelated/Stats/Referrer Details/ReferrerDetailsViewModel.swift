import Foundation

final class ReferrerDetailsViewModel {
    private let data: StatsTotalRowData

    init(data: StatsTotalRowData) {
        self.data = data
    }
}

// MARK: - Public Computed Properties
extension ReferrerDetailsViewModel {
    var title: String {
        data.name
    }

    var tableViewModel: ImmuTable {
        var firstSectionRows = [ImmuTableRow]()
        firstSectionRows.append(ReferrerDetailsHeaderRow())
        firstSectionRows.append(contentsOf: buildDetailsRows(data: data))

        var seconSectionRows = [ImmuTableRow]()
        seconSectionRows.append(ReferrerDetailsSpamActionRow(action: nil, isSpam: data.isReferrerSpam))

        switch data.canMarkReferrerAsSpam {
        case true:
            return ImmuTable(sections: [
                ImmuTableSection(rows: firstSectionRows),
                ImmuTableSection(rows: seconSectionRows)
            ])
        case false:
            return ImmuTable(sections: [
                ImmuTableSection(rows: firstSectionRows)
            ])
        }
    }
}

// MARK: - Private Methods
private extension ReferrerDetailsViewModel {
    func buildDetailsRows(data: StatsTotalRowData) -> [ImmuTableRow] {
        var rows = [ImmuTableRow]()

        if let children = data.childRows, !children.isEmpty {
            for (index, child) in children.enumerated() {
                guard let url = child.disclosureURL else {
                    continue
                }
                rows.append(ReferrerDetailsRow(action: nil,
                                               isLast: index == children.count - 1,
                                               data: .init(name: child.name,
                                                           url: url,
                                                           views: child.data)))
            }
        } else {
            guard let url = data.disclosureURL else {
                return []
            }
            rows.append(ReferrerDetailsRow(action: nil,
                                           isLast: true,
                                           data: .init(name: data.name,
                                                       url: url,
                                                       views: data.data)))
        }

        return rows
    }
}

