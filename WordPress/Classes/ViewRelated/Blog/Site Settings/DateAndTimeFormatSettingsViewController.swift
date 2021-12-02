import Foundation
import CocoaLumberjack
import WordPressShared

/// This class will display the Blog's date and time settings, and will allow the user to modify them.
/// Upon selection, WordPress.com backend will get hit, and the new value will be persisted.
///
open class DateAndTimeFormatSettingsViewController: UITableViewController {

    // MARK: - Private Properties

    fileprivate var blog: Blog!
    fileprivate var service: BlogService!
    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - Computed Properties

    fileprivate var settings: BlogSettings {
        return blog.settings!
    }

    // MARK: - Static Properties

    fileprivate static let footerHeight = CGFloat(34.0)
    fileprivate static let learnMoreUrl = "https://codex.wordpress.org/Formatting_Date_and_Time"

    // MARK: - Typealiases

    fileprivate typealias DateFormat = BlogSettings.DateFormat
    fileprivate typealias TimeFormat = BlogSettings.TimeFormat
    fileprivate typealias DaysOfTheWeek = BlogSettings.DaysOfTheWeek

    // MARK: - Initializer

    @objc public convenience init(blog: Blog) {
        self.init(style: .grouped)
        self.blog = blog
        self.service = BlogService(managedObjectContext: settings.managedObjectContext!)
    }

    // MARK: - View Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Date and Time Format", comment: "Title for the Date and Time Format Settings Screen")
        ImmuTable.registerRows([NavigationItemRow.self], tableView: tableView)
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        reloadViewModel()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadViewModel()
    }

    // MARK: - Model

    fileprivate func reloadViewModel() {
        handler.viewModel = tableViewModel()
    }

    func tableViewModel() -> ImmuTable {

        let dateFormatRow = NavigationItemRow(title: NSLocalizedString("Date Format",
                                                                       comment: "Blog Writing Settings: Date Format"),
                                              detail: settings.dateFormatDescription,
                                              action: self.pressedDateFormat())

        let timeFormatRow = NavigationItemRow(title: NSLocalizedString("Time Format",
                                                                       comment: "Blog Writing Settings: Time Format"),
                                              detail: settings.timeFormatDescription,
                                              action: self.pressedTimeFormat())

        let startOfWeekRow = NavigationItemRow(title: NSLocalizedString("Week starts on",
                                                                       comment: "Blog Writing Settings: Weeks starts on"),
                                               detail: settings.startOfWeekDescription,
                                               action: self.pressedStartOfWeek())

        return ImmuTable(sections: [
            ImmuTableSection(
                headerText: "",
                rows: [dateFormatRow, timeFormatRow, startOfWeekRow],
                footerText: nil)
        ])
    }

    // MARK: Learn More footer

    open override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return DateAndTimeFormatSettingsViewController.footerHeight
    }

    open override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UITableViewHeaderFooterView(frame: CGRect(x: 0.0,
                                                               y: 0.0,
                                                               width: tableView.frame.width,
                                                               height: DateAndTimeFormatSettingsViewController.footerHeight))
        footer.textLabel?.text = NSLocalizedString("Learn more about date and time formatting.",
                                                   comment: "Writing, Date and Time Settings: Learn more about date and time settings footer text")
        footer.textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        footer.textLabel?.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleLearnMoreTap(_:)))
        footer.addGestureRecognizer(tap)
        return footer
    }

    // MARK: - Row Handlers

    func pressedDateFormat() -> ImmuTableAction {
        return { [unowned self] row in
            let settingsViewController = SettingsSelectionViewController(style: .grouped)
            settingsViewController.title = NSLocalizedString("Date Format",
                                                             comment: "Writing Date Format Settings Title")
            settingsViewController.currentValue = self.settings.dateFormat as NSObject

            var allTitles = DateFormat.allTitles
            var allValues = DateFormat.allValues

            if let _ = DateFormat(rawValue: self.settings.dateFormat) {
                allTitles.append(NSLocalizedString("Tap to enter a custom value",
                                                   comment: "Message in a row indicating to tap to enter a custom value"))
                allValues.append("")
            } else {
                allTitles.append(self.settings.dateFormat)
                allValues.append(self.settings.dateFormat)
            }

            settingsViewController.titles = allTitles
            settingsViewController.values = allValues
            settingsViewController.editableIndex = allTitles.count - 1
            settingsViewController.onItemSelected = { [weak self] (selected: Any?) in
                if let newDateFormat = selected as? String {
                    self?.settings.dateFormat = newDateFormat
                    self?.saveSettings()
                    WPAnalytics.trackSettingsChange("date_format", fieldName: "date_format")
                }
            }

            self.navigationController?.pushViewController(settingsViewController, animated: true)
        }
    }

    func pressedTimeFormat() -> ImmuTableAction {
        return { [unowned self] row in
            let settingsViewController = SettingsSelectionViewController(style: .grouped)
            settingsViewController.title = NSLocalizedString("Time Format",
                                                             comment: "Writing Time Format Settings Title")
            settingsViewController.currentValue = self.settings.timeFormat as NSObject

            var allTitles = TimeFormat.allTitles
            var allValues = TimeFormat.allValues

            if let _ = TimeFormat(rawValue: self.settings.timeFormat) {
                allTitles.append(NSLocalizedString("Tap to enter a custom value",
                                                   comment: "Message in a row indicating to tap to enter a custom value"))
                allValues.append("")
            } else {
                allTitles.append(self.settings.timeFormat)
                allValues.append(self.settings.timeFormat)
            }

            settingsViewController.titles = allTitles
            settingsViewController.values = allValues
            settingsViewController.editableIndex = allTitles.count - 1
            settingsViewController.onItemSelected = { [weak self] (selected: Any?) in
                if let newTimeFormat = selected as? String {
                    self?.settings.timeFormat = newTimeFormat
                    self?.saveSettings()
                    WPAnalytics.trackSettingsChange("date_format", fieldName: "time_format")

                }
            }

            self.navigationController?.pushViewController(settingsViewController, animated: true)
        }
    }

    func pressedStartOfWeek() -> ImmuTableAction {
        return { [unowned self] row in
            let settingsViewController = SettingsSelectionViewController(style: .grouped)
            settingsViewController.title = NSLocalizedString("Week starts on",
                                                             comment: "Blog Writing Settings: Weeks starts on")
            settingsViewController.currentValue = self.settings.startOfWeek as NSObject
            settingsViewController.titles = DaysOfTheWeek.allTitles
            settingsViewController.values = DaysOfTheWeek.allValues
            settingsViewController.onItemSelected = { [weak self] (selected: Any?) in
                if let newStartOfWeek = selected as? String {
                    self?.settings.startOfWeek = newStartOfWeek
                    self?.saveSettings()
                    WPAnalytics.trackSettingsChange("date_format",
                                                    fieldName: "start_of_week",
                                                    value: newStartOfWeek as Any)
                }
            }

            self.navigationController?.pushViewController(settingsViewController, animated: true)
        }
    }

    // MARK: - Footer handler

    @objc fileprivate func handleLearnMoreTap(_ sender: UITapGestureRecognizer) {
        guard let url =  URL(string: DateAndTimeFormatSettingsViewController.learnMoreUrl) else {
            return
        }
        let webViewController = WebViewControllerFactory.controller(url: url, source: "site_settings_date_time_format_learn_more")

        if presentingViewController != nil {
            navigationController?.pushViewController(webViewController, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: webViewController)
            present(navController, animated: true)
        }
    }

    // MARK: - Persistance

    fileprivate func saveSettings() {
        service.updateSettings(for: blog,
                               success: { SiteStatsInformation.sharedInstance.updateTimeZone() },
                               failure: { [weak self] (error: Error) -> Void in
                                    self?.refreshSettings()
                                    DDLogError("Error while persisting settings: \(error)")
                               })
    }

    fileprivate func refreshSettings() {
        let service = BlogService(managedObjectContext: settings.managedObjectContext!)
        service.syncSettings(for: blog,
                             success: { [weak self] in
                                self?.reloadViewModel()
                                DDLogInfo("Reloaded Settings")
                             },
                             failure: { (error: Error) in
                                DDLogError("Error while sync'ing blog settings: \(error)")
                             })
    }

}
