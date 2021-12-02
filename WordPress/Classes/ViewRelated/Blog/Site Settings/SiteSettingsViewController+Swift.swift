import Foundation
import WordPressFlux

// This is just a wrapper for the receipts, since Receipt isn't exposed to Obj-C
@objc class TimeZoneObserver: NSObject {
    let storeReceipt: Receipt
    let queryReceipt: Receipt

    init(onStateChange callback: @escaping (TimeZoneStoreState, TimeZoneStoreState) -> Void) {
        let store = StoreContainer.shared.timezone
        storeReceipt = store.onStateChange(callback)
        queryReceipt = store.query(TimeZoneQuery())
        super.init()
    }
}

extension SiteSettingsViewController {
    @objc func observeTimeZoneStore() {
        timeZoneObserver = TimeZoneObserver() { [weak self] (oldState, newState) in
            guard let controller = self else {
                return
            }
            let oldLabel = controller.timezoneLabel(state: oldState)
            let newLabel = controller.timezoneLabel(state: newState)
            guard newLabel != oldLabel else {
                return
            }

            // If this were ImmuTable-based, I'd reload the specific row
            // But it could silently break if we change the order of rows in the future
            // @koke 2018-01-17
            controller.tableView.reloadData()
        }
    }

    @objc func timezoneLabel() -> String? {
        return timezoneLabel(state: StoreContainer.shared.timezone.state)
    }

    func timezoneLabel(state: TimeZoneStoreState) -> String? {
        guard let settings = blog.settings else {
            return nil
        }
        if let timezone = state.findTimezone(gmtOffset: settings.gmtOffset?.floatValue, timezoneString: settings.timezoneString) {
            return timezone.label
        } else {
            return timezoneValue
        }
    }

    var timezoneValue: String? {
        if let timezoneString = blog.settings?.timezoneString?.nonEmptyString() {
            return timezoneString
        } else if let gmtOffset = blog.settings?.gmtOffset {
            return OffsetTimeZone(offset: gmtOffset.floatValue).label
        } else {
            return nil
        }
    }

    // MARK: - Homepage Settings

    @objc var homepageSettingsCell: SettingTableViewCell? {
        let cell = SettingTableViewCell(label: NSLocalizedString("Homepage Settings", comment: "Label for Homepage Settings site settings section"), editable: true, reuseIdentifier: nil)
        cell?.textValue = blog.homepageType?.title
        return cell
    }

    // MARK: - Navigation

    @objc(showHomepageSettingsForBlog:) func showHomepageSettings(for blog: Blog) {
        let settingsViewController = HomepageSettingsViewController(blog: blog)
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    @objc func showTimezoneSelector() {
        let controller = TimeZoneSelectorViewController(selectedValue: timezoneValue) { [weak self] (newValue) in
            self?.navigationController?.popViewController(animated: true)
            self?.blog.settings?.gmtOffset = newValue.gmtOffset as NSNumber?
            self?.blog.settings?.timezoneString = newValue.timezoneString
            self?.saveSettings()
            self?.trackSettingsChange(fieldName: "timezone",
                                      value: newValue.value as Any)
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc func showDateAndTimeFormatSettings() {
        let dateAndTimeFormatViewController = DateAndTimeFormatSettingsViewController(blog: blog)
        navigationController?.pushViewController(dateAndTimeFormatViewController, animated: true)
    }

    @objc func showPostPerPageSetting() {
        let pickerViewController = SettingsPickerViewController(style: .grouped)
        pickerViewController.title = NSLocalizedString("Posts per Page", comment: "Posts per Page Title")
        pickerViewController.switchVisible = false
        pickerViewController.selectionText = NSLocalizedString("The number of posts to show per page.",
                                                               comment: "Text above the selection of the number of posts to show per blog page")
        pickerViewController.pickerFormat = NSLocalizedString("%d posts", comment: "Number of posts")
        pickerViewController.pickerMinimumValue = minNumberOfPostPerPage
        if let currentValue = blog.settings?.postsPerPage as? Int {
            pickerViewController.pickerSelectedValue = currentValue
            pickerViewController.pickerMaximumValue = max(currentValue, maxNumberOfPostPerPage)
        } else {
            pickerViewController.pickerMaximumValue = maxNumberOfPostPerPage
        }
        pickerViewController.onChange           = { [weak self] (enabled: Bool, newValue: Int) in
            self?.blog.settings?.postsPerPage = newValue as NSNumber?
            self?.saveSettings()
            self?.trackSettingsChange(fieldName: "posts_per_page", value: newValue as Any)
        }

        navigationController?.pushViewController(pickerViewController, animated: true)
    }

    @objc func showSpeedUpYourSiteSettings() {
        let speedUpSiteSettingsViewController = JetpackSpeedUpSiteSettingsViewController(blog: blog)
        navigationController?.pushViewController(speedUpSiteSettingsViewController, animated: true)
    }

    // MARK: Footers

    @objc(getTrafficSettingsSectionFooterView)
    func trafficSettingsSectionFooterView() -> UIView {
        let footer = makeFooterView()
        footer.textLabel?.text = NSLocalizedString("Your WordPress.com site supports the use of Accelerated Mobile Pages, a Google-led initiative that dramatically speeds up loading times on mobile devices.",
                                                   comment: "Footer for AMP Traffic Site Setting, should match Calypso.")
        footer.textLabel?.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleAMPFooterTap(_:)))
        footer.addGestureRecognizer(tap)
        return footer
    }

    @objc(getEditorSettingsSectionFooterView)
    func editorSettingsSectionFooterView() -> UIView {
        let footer = makeFooterView()
        footer.textLabel?.text = NSLocalizedString("Edit new posts and pages with the block editor.", comment: "Explanation for the option to enable the block editor")
        return footer
    }

    private func makeFooterView() -> UITableViewHeaderFooterView {
        let footer = UITableViewHeaderFooterView()
        footer.textLabel?.numberOfLines = 0
        footer.textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        return footer
    }

    @objc fileprivate func handleAMPFooterTap(_ sender: UITapGestureRecognizer) {
        guard let url =  URL(string: self.ampSupportURL) else {
            return
        }
        let webViewController = WebViewControllerFactory.controller(url: url, source: "site_settings_amp_footer")

        if presentingViewController != nil {
            navigationController?.pushViewController(webViewController, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: webViewController)
            present(navController, animated: true)
        }
    }

    override open func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }

    // MARK: Private Properties

    fileprivate var minNumberOfPostPerPage: Int { return 1 }
    fileprivate var maxNumberOfPostPerPage: Int { return 1000 }
    fileprivate var ampSupportURL: String { return "https://support.wordpress.com/amp-accelerated-mobile-pages/" }

}

// MARK: - General Settings Table Section Management

extension SiteSettingsViewController {

    enum GeneralSettingsRow {
        case title
        case tagline
        case url
        case privacy
        case language
        case timezone
        case bloggingReminders
    }

    var generalSettingsRows: [GeneralSettingsRow] {
        var rows: [GeneralSettingsRow] = [.title, .tagline, .url]

        if blog.supportsSiteManagementServices() {
            rows.append(contentsOf: [.privacy, .language])
        }

        if blog.supports(.wpComRESTAPI) {
            rows.append(.timezone)
        }

        if blog.areBloggingRemindersAllowed() {
            rows.append(.bloggingReminders)
        }

        return rows
    }

    @objc
    var generalSettingsRowCount: Int {
        generalSettingsRows.count
    }

    @objc
    func tableView(_ tableView: UITableView, cellForGeneralSettingsInRow row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCellReuseIdentifier) as! SettingTableViewCell

        switch generalSettingsRows[row] {
        case .title:
            configureCellForTitle(cell)
        case .tagline:
            configureCellForTagline(cell)
        case .url:
            configureCellForURL(cell)
        case .privacy:
            configureCellForPrivacy(cell)
        case .language:
            configureCellForLanguage(cell)
        case .timezone:
            configureCellForTimezone(cell)
        case .bloggingReminders:
            configureCellForBloggingReminders(cell)
        }

        return cell
    }

    @objc
    func tableView(_ tableView: UITableView, didSelectInGeneralSettingsAt indexPath: IndexPath) {
        switch generalSettingsRows[indexPath.row] {
        case .title where blog.isAdmin:
            showEditSiteTitleController(indexPath: indexPath)
        case .tagline where blog.isAdmin:
            showEditSiteTaglineController(indexPath: indexPath)
        case .privacy where blog.isAdmin:
            showPrivacySelector()
        case .language where blog.isAdmin:
            showLanguageSelector(for: blog)
        case .timezone where blog.isAdmin:
            showTimezoneSelector()
        case .bloggingReminders:
            presentBloggingRemindersFlow(indexPath: indexPath)
        default:
            break
        }
    }

    // MARK: - Cell Configuration

    private func configureCellForTitle(_ cell: SettingTableViewCell) {
        let name = blog.settings?.name ?? NSLocalizedString("A title for the site", comment: "Placeholder text for the title of a site")

        cell.editable = blog.isAdmin
        cell.textLabel?.text = NSLocalizedString("Site Title", comment: "Label for site title blog setting")
        cell.textValue = name
    }

    private func configureCellForTagline(_ cell: SettingTableViewCell) {
        let tagline = blog.settings?.tagline ?? NSLocalizedString("Explain what this site is about.", comment: "Placeholder text for the tagline of a site")

        cell.editable = blog.isAdmin
        cell.textLabel?.text = NSLocalizedString("Tagline", comment: "Label for tagline blog setting")
        cell.textValue = tagline
    }

    private func configureCellForURL(_ cell: SettingTableViewCell) {
        let url: String = {
            guard let url = blog.url else {
                return NSLocalizedString("http://my-site-address (URL)", comment: "(placeholder) Help the user enter a URL into the field")
            }

            return url
        }()

        cell.editable = false
        cell.textLabel?.text = NSLocalizedString("Address", comment: "Label for url blog setting")
        cell.textValue = url
    }

    private func configureCellForPrivacy(_ cell: SettingTableViewCell) {
        cell.editable = blog.isAdmin
        cell.textLabel?.text = NSLocalizedString("Privacy", comment: "Label for the privacy setting")
        cell.textValue = BlogSiteVisibilityHelper.titleForCurrentSiteVisibility(of: blog)
    }

    private func configureCellForLanguage(_ cell: SettingTableViewCell) {
        let name: String

        if let languageId = blog.settings?.languageID.intValue {
            name = WordPressComLanguageDatabase().nameForLanguageWithId(languageId)
        } else {
            // Since the settings can be nil, we need to handle the scenario... but it
            // really should not be possible to reach this line.
            name = NSLocalizedString("Undefined", comment: "When the App can't figure out what language a blog is configured to use.")
        }

        cell.editable = blog.isAdmin
        cell.textLabel?.text = NSLocalizedString("Language", comment: "Label for the privacy setting")
        cell.textValue = name
    }

    private func configureCellForTimezone(_ cell: SettingTableViewCell) {
        cell.editable = blog.isAdmin
        cell.textLabel?.text = NSLocalizedString("Time Zone", comment: "Label for the timezone setting")
        cell.textValue = timezoneLabel()
    }

    private func configureCellForBloggingReminders(_ cell: SettingTableViewCell) {
        cell.editable = true
        cell.textLabel?.text = NSLocalizedString("Blogging Reminders", comment: "Label for the blogging reminders setting")
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.minimumScaleFactor = 0.5
        cell.accessoryType = .none
        cell.textValue = schedule(for: blog)
    }

    // MARK: - Schedule Description

    private func schedule(for blog: Blog) -> String {
        guard let scheduler = try? BloggingRemindersScheduler() else {
            return ""
        }

        let formatter = BloggingRemindersScheduleFormatter()
        return formatter.shortScheduleDescription(for: scheduler.schedule(for: blog), time: scheduler.scheduledTime(for: blog).toLocalTime()).string
    }

    // MARK: - Handling General Setting Cell Taps

    private func showEditSiteTitleController(indexPath: IndexPath) {
        guard blog.isAdmin else {
            return
        }

        let siteTitleViewController = SettingsTextViewController(
            text: blog.settings?.name ?? "",
            placeholder: NSLocalizedString("A title for the site", comment: "Placeholder text for the title of a site"),
            hint: "")

        siteTitleViewController.title = NSLocalizedString("Site Title", comment: "Title for screen that show site title editor")
        siteTitleViewController.onValueChanged = { [weak self] value in
            guard let self = self,
                  let cell = self.tableView.cellForRow(at: indexPath) else {
                // No need to update anything if the cell doesn't exist.
                return
            }

            cell.detailTextLabel?.text = value

            if value != self.blog.settings?.name {
                self.blog.settings?.name = value
                self.saveSettings()

                self.trackSettingsChange(fieldName: "site_title")
            }
        }

        self.navigationController?.pushViewController(siteTitleViewController, animated: true)
    }

    private func showEditSiteTaglineController(indexPath: IndexPath) {
        guard blog.isAdmin else {
            return
        }

        let siteTaglineViewController = SettingsTextViewController(
            text: blog.settings?.tagline ?? "",
            placeholder: NSLocalizedString("Explain what this site is about.", comment: "Placeholder text for the tagline of a site"),
            hint: NSLocalizedString("In a few words, explain what this site is about.", comment: "Explain what is the purpose of the tagline"))

        siteTaglineViewController.title = NSLocalizedString("Tagline", comment: "Title for screen that show tagline editor")
        siteTaglineViewController.onValueChanged = { [weak self] value in
            guard let self = self,
                  let cell = self.tableView.cellForRow(at: indexPath) else {
                // No need to update anything if the cell doesn't exist.
                return
            }

            let normalizedTagline = value.trimmingCharacters(in: .whitespacesAndNewlines)
            cell.detailTextLabel?.text = normalizedTagline

            if normalizedTagline != self.blog.settings?.tagline {
                self.blog.settings?.tagline = normalizedTagline
                self.saveSettings()

                self.trackSettingsChange(fieldName: "tagline")
            }
        }

        self.navigationController?.pushViewController(siteTaglineViewController, animated: true)
    }

    private func presentBloggingRemindersFlow(indexPath: IndexPath) {
        BloggingRemindersFlow.present(from: self, for: blog, source: .blogSettings) { [weak self] in
            guard let self = self,
                  let cell = self.tableView.cellForRow(at: indexPath) as? SettingTableViewCell else {
                return
            }

            cell.textValue = self.schedule(for: self.blog)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func trackSettingsChange(fieldName: String, value: Any? = nil) {
        WPAnalytics.trackSettingsChange("site_settings",
                                        fieldName: fieldName,
                                        value: value)
    }
}
