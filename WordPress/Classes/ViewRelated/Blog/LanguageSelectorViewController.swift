import UIKit
import WordPressShared

// TODO: Make Language a top level type?
typealias Language = WordPressComLanguageDatabase.Language

protocol LanguageSelectorDelegate: class {
    func languageSelector(_ selector: LanguageSelectorViewController, didSelectLanguage: Language)
}

class LanguageSelectorViewController: UITableViewController, UISearchResultsUpdating {
    weak var delegate: LanguageSelectorDelegate?

    private let selectedLanguage: Language?
    private let searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        return controller
    }()

    private let database = WordPressComLanguageDatabase()
    private lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    init(selected language: Language?) {
        self.selectedLanguage = language
        super.init(style: .grouped)
        searchController.searchResultsUpdater = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ImmuTable.registerRows([LanguageSelectorRow.self], tableView: tableView)
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        tableView.tableHeaderView = searchController.searchBar
        updateViewModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.isActive = false
    }

    func updateViewModel() {
        if searchController.isActive {
            handler.viewModel = modelForSearch(query: searchController.searchBar.text?.nonEmptyString())
        } else {
            handler.viewModel = modelForBrowsing()
        }
    }

    func modelForSearch(query: String?) -> ImmuTable {
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

    func modelForBrowsing() -> ImmuTable {
        return ImmuTable(sections: [
            ImmuTableSection(
                headerText: NSLocalizedString("Popular languages", comment: "Section title for Popular Languages"),
                rows: database.popular.map(model(language:))),
            ImmuTableSection(
                headerText: NSLocalizedString("All languages", comment: "Section title for All Languages"),
                rows: database.all.map(model(language:)))
            ])
    }

    func updateSearchResults(for searchController: UISearchController) {
        updateViewModel()
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
            strongSelf.delegate?.languageSelector(strongSelf, didSelectLanguage: language)
        }
    }
}

struct LanguageSelectorRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellSubtitle.self)
    let language: Language
    let selected: Bool
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.textLabel?.text = language.name
        cell.detailTextLabel?.text = language.description
        cell.accessoryType = selected ? .checkmark : .none
    }
}
