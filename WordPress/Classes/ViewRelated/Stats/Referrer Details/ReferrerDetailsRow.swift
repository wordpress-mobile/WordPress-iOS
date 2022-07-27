import Foundation

struct ReferrerDetailsRow: ImmuTableRow {
    private typealias CellType = ReferrerDetailsCell

    static var cell = ImmuTableCell.class(CellType.self)
    var action: ImmuTableAction?
    let isLast: Bool
    let data: DetailsData

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? CellType else {
            return
        }
        cell.configure(data: data, isLast: isLast)
    }
}

// MARK: - Types
extension ReferrerDetailsRow {
    struct DetailsData {
        let name: String
        let url: URL
        let views: String
    }
}
