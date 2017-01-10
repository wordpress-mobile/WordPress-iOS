import Foundation
import WordPressShared



/// SettingsListPicker will render a list of options, and will allow the user to select one from the list.
///
class SettingsListPickerViewController<T: Equatable> : UITableViewController {
    /// Current selected value, if any
    ///
    var selectedValue: T?

    /// Callback to be executed whenever the selectedValue changes
    ///
    var onChange: ((T) -> Void)?



    // MARK: - Initializers
    init(headers: [String]? = nil, footers: [String]? = nil, titles: [[String]], subtitles: [[String]]? = nil, values: [[T]]) {
        self.headers = headers
        self.footers = footers
        self.titles = titles
        self.subtitles = subtitles
        self.values = values

        super.init(style: .grouped)

        assert(titles.count == values.count)
        assert(titles.count == subtitles?.count || subtitles == nil)
        assert(headers?.count == titles.count || headers == nil)
        assert(footers?.count == titles.count || footers == nil)
    }

    required init?(coder aDecoder: NSCoder) {
        self.headers = nil
        self.footers = nil
        self.titles = nil
        self.subtitles = nil
        self.values = nil
        self.selectedValue = nil
        self.onChange = nil

        super.init(coder: aDecoder)

        return nil
    }



    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Note: This fixes an extra padding glitch upon rotation
        view.setNeedsLayout()
    }



    // MARK: - Setup Helpers
    fileprivate func setupTableView() {
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }



    // MARK: - UITableViewDataSource Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return titles?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles?[section].count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        if cell == nil {
            cell = WPTableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
            WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        }


        let title = titles?[indexPath.section][indexPath.row] ?? String()
        let subtitle = subtitles?[indexPath.section][indexPath.row] ?? String()
        let selected = values?[indexPath.section][indexPath.row] == selectedValue

        cell?.textLabel?.text = title
        cell?.detailTextLabel?.text = subtitle
        cell?.accessoryType = selected ? .checkmark : .none

        return cell!
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headers?[section]
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionHeader(view)
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return footers?[section]
    }

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }



    // MARK: - UITableViewDelegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let newValue = values?[indexPath.section][indexPath.row] else {
            return
        }

        selectedValue = newValue
        tableView.reloadDataPreservingSelection()
        tableView.deselectSelectedRowWithAnimationAfterDelay(true)

        // Callback!
        onChange?(newValue)
    }



    // MARK: - Constants

    fileprivate let reuseIdentifier = "WPTableViewCell"




    // MARK: - Private Properties

    /// Header Strings to be applied over the diferent sections
    ///
    fileprivate let headers: [String]?

    /// Footer Strings to be applied over the diferent sections
    ///
    fileprivate let footers: [String]?

    /// Titles to be rendered
    ///
    fileprivate let titles: [[String]]?

    /// Row Subtitles. Should contain the exact same number as titles
    ///
    fileprivate let subtitles: [[String]]?

    /// Row Values. Should contain the exact same number as titles
    ///
    fileprivate let values: [[T]]?
}
