import Foundation
import WordPressShared


/// This class will display the Blog's Language setting, and will allow the user to pick a new value.
/// Upon selection, WordPress.com backend will get hit, and the new value will be persisted.
///
public class LanguageViewController : UITableViewController
{
    /// Callback to be executed whenever the Blog's selected language changes.
    ///
    var onChange : (NSNumber -> Void)?



    /// Designated Initializer
    ///
    /// - Parameter Blog: The blog for which we wanna display the languages picker
    ///
    public convenience init(blog: Blog) {
        self.init(style: .Grouped)
        self.blog = blog
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Setup tableViewController
        title = NSLocalizedString("Language", comment: "Title for the Language Picker Screen")
        clearsSelectionOnViewWillAppear = false

        // Setup tableView
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadDataPreservingSelection()
        tableView.deselectSelectedRowWithAnimationAfterDelay(true)
    }



    // MARK: - UITableViewDataSource Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier)
        if cell == nil {
            cell = WPTableViewCell(style: .Value1, reuseIdentifier: reuseIdentifier)
            cell?.accessoryType = .DisclosureIndicator
            WPStyleGuide.configureTableViewCell(cell)
        }

        configureTableViewCell(cell!)

        return cell!
    }

    public override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return footerText
    }

    public override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }

    // MARK: - UITableViewDelegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        pressedLanguageRow()
    }



    // MARK: - Private Methods
    private func configureTableViewCell(cell: UITableViewCell) {
        let languageId = blog.settings!.languageID.integerValue
        cell.textLabel?.text = NSLocalizedString("Language", comment: "Language of the current blog")
        cell.detailTextLabel?.text = languageDatabase.nameForLanguageWithId(languageId)
    }

    private func pressedLanguageRow() {
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
    private let reuseIdentifier = "reuseIdentifier"
    private let footerText = NSLocalizedString("The language in which this site is primarily written.",
                                                comment: "Footer Text displayed in Blog Language Settings View")

    // MARK: - Private Properties
    private var blog : Blog!
    private let languageDatabase = WordPressComLanguageDatabase()
}
