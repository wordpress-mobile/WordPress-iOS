import Foundation

protocol ReferrerDetailsViewModelDelegate: AnyObject {
    func displayWebViewWithURL(_ url: URL)
    func toggleSpamState(for referrerDomain: String, currentValue: Bool)
}

final class ReferrerDetailsViewModel {
    private(set) var data: StatsTotalRowData
    private weak var delegate: ReferrerDetailsViewModelDelegate?
    private(set) var isLoading = false

    init(data: StatsTotalRowData, delegate: ReferrerDetailsViewModelDelegate) {
        self.data = data
        self.delegate = delegate
    }
}

// MARK: - Public Methods
extension ReferrerDetailsViewModel {
    func update(with data: StatsTotalRowData) {
        self.data = data
    }

    func setLoadingState(_ value: Bool) {
        isLoading = value
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

        var secondSectionRows = [ImmuTableRow]()
        secondSectionRows.append(ReferrerDetailsSpamActionRow(action: action, isSpam: data.isReferrerSpam, isLoading: isLoading))

        switch data.canMarkReferrerAsSpam {
        case true:
            return ImmuTable(sections: [
                ImmuTableSection(rows: firstSectionRows),
                ImmuTableSection(rows: secondSectionRows)
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
                rows.append(ReferrerDetailsRow(action: action,
                                               isLast: index == children.count - 1,
                                               data: .init(name: child.name,
                                                           url: url,
                                                           views: child.data)))
            }
        } else {
            guard let url = data.disclosureURL else {
                return []
            }
            rows.append(ReferrerDetailsRow(action: action,
                                           isLast: true,
                                           data: .init(name: data.name,
                                                       url: url,
                                                       views: data.data)))
        }

        return rows
    }
}

// MARK: - Private Computed Properties
private extension ReferrerDetailsViewModel {
    var action: ((ImmuTableRow) -> Void) {
        return { [unowned self] row in
            switch row {
            case let row as ReferrerDetailsRow:
                self.delegate?.displayWebViewWithURL(row.data.url)
            case let row as ReferrerDetailsSpamActionRow:
                guard let referrerDomain = self.data.disclosureURL?.host ?? self.data.childRows?.first?.disclosureURL?.host else {
                    return
                }
                self.delegate?.toggleSpamState(for: referrerDomain, currentValue: row.isSpam)
            default:
                break
            }
        }
    }
}
