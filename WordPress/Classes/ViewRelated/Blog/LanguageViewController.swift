import Foundation
import WordPressShared


/// This class will display the Blog's Language setting, and will allow the user to pick a new value.
/// Upon selection, WordPress.com backend will get hit, and the new value will be persisted.
///
open class LanguageViewController : UITableViewController
{
    /// Callback to be executed whenever the Blog's selected language changes.
    ///
    var onChange : ((NSNumber) -> Void)?



    /// Designated Initializer
    ///
    /// - Parameter Blog: The blog for which we wanna display the languages picker
    ///
    public convenience init(blog: Blog) {
        self.init(style: .grouped)
        self.blog = blog
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        // Setup tableViewController
        title = NSLocalizedString("Language", comment: "Title for the Language Picker Screen")
        clearsSelectionOnViewWillAppear = false

        // Setup tableView
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadDataPreservingSelection()
        tableView.deselectSelectedRowWithAnimationAfterDelay(true)
    }



    // MARK: - UITableViewDataSource Methods
    open override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        if cell == nil {
            cell = WPTableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
            cell?.accessoryType = .disclosureIndicator
            WPStyleGuide.configureTableViewCell(cell)
        }

        configureTableViewCell(cell!)

        return cell!
    }

    open override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return footerText
    }

    open override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }

    // MARK: - UITableViewDelegate Methods
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pressedLanguageRow()
    }



    // MARK: - Private Methods
    fileprivate func configureTableViewCell(_ cell: UITableViewCell) {
        let languageId = blog.settings!.languageID.intValue
        cell.textLabel?.text = NSLocalizedString("Language", comment: "Language of the current blog")
        cell.detailTextLabel?.text = languageDatabase.nameForLanguageWithId(languageId)
    }

    fileprivate func pressedLanguageRow() {
        // Setup Properties
        let headers = [
            NSLocalizedString("Popular languages", comment: "Section title for Popular Languages"),
            NSLocalizedString("All languages", comment: "Section title for All Languages")
        ]

        let languages   = languageDatabase.grouped
        let titles      = languages.map { $0.map { $0.name } }
        let subtitles   = languages.map { $0.map { $0.description } }
        let values      = languages.map { $0.map { $0.id } } as [[NSObject]]

        // Setup ListPickerViewController
        let listViewController = SettingsListPickerViewController(headers: headers, titles: titles, subtitles: subtitles, values: values)
        listViewController.title = NSLocalizedString("Site Language", comment: "Title for the Language Picker View")
        listViewController.selectedValue = blog.settings!.languageID
        listViewController.onChange = { [weak self] (selected: AnyObject) in
            guard let newLanguageID = selected as? NSNumber else {
                return
            }

            self?.onChange?(newLanguageID)
        }

        navigationController?.pushViewController(listViewController, animated: true)
    }



    // MARK: - Private Constants
    fileprivate let reuseIdentifier = "reuseIdentifier"
    fileprivate let footerText = NSLocalizedString("The language in which this site is primarily written.",
                                                comment: "Footer Text displayed in Blog Language Settings View")

    // MARK: - Private Properties
    fileprivate var blog : Blog!
    fileprivate let languageDatabase = WordPressComLanguageDatabase()
}
