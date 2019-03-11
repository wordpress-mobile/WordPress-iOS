import Foundation
import WordPressFlux

/// The view model used by PostStatsTableViewController to show
/// stats for a selected post.
///
class PostStatsViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()
    private var postTitle: String?

    // MARK: - Init

    init(postTitle: String?) {
        self.postTitle = postTitle
    }

    // MARK: - Table View

    func tableViewModel() -> ImmuTable {
        var tableRows = [ImmuTableRow]()

        tableRows.append(titleTableRow())

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

    func titleTableRow() -> ImmuTableRow {
        return PostStatsTitleRow(postTitle: postTitle ?? NSLocalizedString("(No Title)", comment: "Empty Post Title"))
    }

}
