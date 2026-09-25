import UIKit

// A concrete section identifier keeps the snapshot types Sendable without the
// `AnyHashable: @retroactive @unchecked Sendable` conformance the old
// AnyHashable-keyed snapshot needed.
enum ImmuTableDiffableSectionID: Hashable {
    case insight(InsightType)
    case addInsight
    case traffic(PeriodType)
    case rows([AnyHashableImmuTableRow])
}

typealias ImmuTableDiffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<
    ImmuTableDiffableSectionID, AnyHashableImmuTableRow
>
typealias ImmuTableDiffableDataSource = UITableViewDiffableDataSource<
    ImmuTableDiffableSectionID, AnyHashableImmuTableRow
>

struct AnyHashableImmuTableRow: Hashable {
    let immuTableRow: any (ImmuTableRow & Hashable)

    static func == (lhs: AnyHashableImmuTableRow, rhs: AnyHashableImmuTableRow) -> Bool {
        AnyHashable(lhs.immuTableRow) == AnyHashable(rhs.immuTableRow)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(AnyHashable(immuTableRow))
    }
}

class ImmuTableDiffableViewHandler: ImmuTableViewHandler {
    lazy var diffableDataSource: ImmuTableDiffableDataSource = {
        ImmuTableDiffableDataSource(tableView: target.tableView) { tableView, indexPath, item in
            let row = item.immuTableRow
            let cell = tableView.dequeueReusableCell(withIdentifier: row.reusableIdentifier, for: indexPath)
            row.configureCell(cell)
            return cell
        }
    }()

    override init(
        takeOver target: ImmuTableViewHandler.UIViewControllerWithTableView,
        with passthroughScrollViewDelegate: UIScrollViewDelegate? = nil
    ) {
        super.init(takeOver: target, with: passthroughScrollViewDelegate)

        self.target.tableView.dataSource = diffableDataSource
        self.automaticallyReloadTableView = false
    }

    func item(for indexPath: IndexPath) -> ImmuTableRow? {
        guard
            let diffableDataSource = target.tableView.dataSource
                as? UITableViewDiffableDataSource<ImmuTableDiffableSectionID, AnyHashableImmuTableRow>
        else {
            return nil
        }

        return diffableDataSource.itemIdentifier(for: indexPath)?.immuTableRow
    }

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if target.responds(to: #selector(UITableViewDelegate.tableView(_:didSelectRowAt:))) {
            target.tableView?(tableView, didSelectRowAt: indexPath)
        } else if let item = item(for: indexPath) {
            item.action?(item)
        }
        if automaticallyDeselectCells {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let item = item(for: indexPath), let customHeight = type(of: item).customHeight {
            return CGFloat(customHeight)
        }
        return tableView.rowHeight
    }
}
