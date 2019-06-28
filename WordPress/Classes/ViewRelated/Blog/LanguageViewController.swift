import Foundation
import WordPressShared


/// This class will display the Blog's Language setting, and will allow the user to pick a new value.
/// Upon selection, WordPress.com backend will get hit, and the new value will be persisted.
///
open class LanguageViewController: UITableViewController, LanguageSelectorDelegate {
    /// Callback to be executed whenever the Blog's selected language changes.
    ///
    @objc var onChange: ((NSNumber) -> Void)?



    /// Designated Initializer
    ///
    /// - Parameter Blog: The blog for which we wanna display the languages picker
    ///
    @objc public convenience init(blog: Blog) {
        self.init(style: .grouped)
        self.blog = blog
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        // Setup tableViewController
        title = NSLocalizedString("Language", comment: "Title for the Language Picker Screen")
        clearsSelectionOnViewWillAppear = false

        // Setup tableView
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
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
        let selectedLanguageId = blog.settings?.languageID.intValue
        let selector = LanguageSelectorViewController(selected: selectedLanguageId)
        selector.delegate = self
        selector.title = NSLocalizedString("Site Language", comment: "Title for the Language Picker View")
        navigationController?.pushViewController(selector, animated: true)
    }


    @objc func languageSelector(_ selector: LanguageSelectorViewController, didSelect languageId: Int) {
        _ = navigationController?.popToViewController(self, animated: true)
        onChange?(languageId as NSNumber)
    }


    // MARK: - Private Constants
    fileprivate let reuseIdentifier = "reuseIdentifier"
    fileprivate let footerText = NSLocalizedString("The language in which this site is primarily written.",
                                                comment: "Footer Text displayed in Blog Language Settings View")

    // MARK: - Private Properties
    fileprivate var blog: Blog!
    fileprivate let languageDatabase = WordPressComLanguageDatabase()
}
