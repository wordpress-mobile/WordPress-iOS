import UIKit
import WordPressShared

/// Defines the methods implemented by the LanguageSelectorViewController delegate
///
protocol LanguageSelectorDelegate: AnyObject {

    /// Called when the user tapped on a language.
    ///
    func languageSelector(_ selector: LanguageSelectorViewController, didSelect languageId: Int)
}


/// Displays a searchable list of languages supported by WordPress.com, letting the user select one.
///
class LanguageSelectorViewController: UITableViewController, UISearchResultsUpdating {

    // MARK: - Public interface

    /// The receiver’s delegate.
    ///
    weak var delegate: LanguageSelectorDelegate?

    /// Initializes the language selector, optionally with a selected language.
    ///
    init(selected languageId: Int?) {
        self.selectedLanguage = languageId.flatMap(database.find(id:))
        super.init(style: .grouped)
        searchController.searchResultsUpdater = self
    }

    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ImmuTable.registerRows([LanguageSelectorRow.self], tableView: tableView)
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
        WPStyleGuide.configureSearchBar(searchController.searchBar)
        tableView.tableHeaderView = searchController.searchBar
        updateViewModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.isActive = false
    }

    // MARK: - Search Results Updating

    func updateSearchResults(for searchController: UISearchController) {
        updateViewModel()
    }

    // MARK: - Model

    private lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    private func updateViewModel() {
        if searchController.isActive {
            handler.viewModel = modelForSearch(query: searchController.searchBar.text?.nonEmptyString())
        } else {
            handler.viewModel = modelForBrowsing()
        }
    }

    private func modelForSearch(query: String?) -> ImmuTable {
        let filtered: [Language]
        if let query = query {
            filtered = database.all.filter({ (language) -> Bool in
                return language.name.localizedCaseInsensitiveContains(query)
                    || language.description.localizedCaseInsensitiveContains(query)
            })
        } else {
            filtered = database.all
        }
        return ImmuTable(sections: [
            ImmuTableSection(rows: filtered.map(model(language:)))
            ])
    }

    private func modelForBrowsing() -> ImmuTable {
        return ImmuTable(sections: [
            ImmuTableSection(
                headerText: NSLocalizedString("Popular languages", comment: "Section title for Popular Languages"),
                rows: database.popular.map(model(language:))),
            ImmuTableSection(
                headerText: NSLocalizedString("All languages", comment: "Section title for All Languages"),
                rows: database.all.map(model(language:)))
            ])
    }

    private func model(language: Language) -> ImmuTableRow {
        let selected: Bool = selectedLanguage == language
        let action = self.action(language: language)
        return LanguageSelectorRow(language: language, selected: selected, action: action)
    }

    private func action(language: Language) -> ImmuTableAction {
        return { [weak self] row in
            guard let strongSelf = self else {
                return
            }
            strongSelf.searchController.isActive = false
            strongSelf.delegate?.languageSelector(strongSelf, didSelect: language.id)
        }
    }

    // MARK: - Private properties

    fileprivate typealias Language = WordPressComLanguageDatabase.Language

    private let selectedLanguage: Language?

    private let searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        return controller
    }()

    private let database = WordPressComLanguageDatabase()

}

private struct LanguageSelectorRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellSubtitle.self)
    let language: LanguageSelectorViewController.Language
    let selected: Bool
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.textLabel?.text = language.name
        cell.detailTextLabel?.text = language.description
        cell.accessoryType = selected ? .checkmark : .none
    }
}
