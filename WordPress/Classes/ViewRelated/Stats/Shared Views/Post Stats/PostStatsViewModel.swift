import Foundation
import WordPressFlux

/// The view model used by PostStatsTableViewController to show
/// stats for a selected post.
///
class PostStatsViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()

    // MARK: - Table View

    func tableViewModel() -> ImmuTable {
        var tableRows = [ImmuTableRow]()

        // TODO: add rows

        tableRows.append(TableFooterRow())

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
    }

}

// MARK: - Private Extension

private extension PostStatsViewModel {

    // MARK: - Create Table Rows

}
