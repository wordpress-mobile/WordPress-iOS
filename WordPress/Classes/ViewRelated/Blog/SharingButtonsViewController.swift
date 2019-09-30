import UIKit
import CocoaLumberjack
import WordPressShared

/// Manages which sharing button are displayed, their order, and other settings
/// related to sharing.
///
@objc class SharingButtonsViewController: UITableViewController {
    typealias SharingButtonsRowAction = () -> Void
    typealias SharingButtonsCellConfig = (UITableViewCell) -> Void

    let buttonSectionIndex = 0
    let moreSectionIndex = 1

    let blog: Blog
    private var buttons = [SharingButton]()
    private var sections = [SharingButtonsSection]()
    private var buttonsSection: SharingButtonsSection {
        return sections[buttonSectionIndex]
    }

    private var moreSection: SharingButtonsSection {
        return sections[moreSectionIndex]
    }

    private var twitterSection: SharingButtonsSection {
        return sections.last!
    }

    private var didMakeChanges: Bool = false

    let buttonStyles = [
        "icon-text": NSLocalizedString("Icon & Text", comment: "Title of a button style"),
        "icon": NSLocalizedString("Icon Only", comment: "Title of a button style"),
        "text": NSLocalizedString("Text Only", comment: "Title of a button style"),
        "official": NSLocalizedString("Official Buttons", comment: "Title of a button style")
    ]

    let buttonStyleTitle = NSLocalizedString("Button Style", comment: "Title for a list of different button styles.")
    let labelTitle = NSLocalizedString("Label", comment: "Noun. Title for the setting to edit the sharing label text.")
    let twitterUsernameTitle = NSLocalizedString("Twitter Username", comment: "Title for the setting to edit the twitter username used when sharing to twitter.")
    let twitterServiceID = "twitter"
    let managedObjectContext = ContextManager.sharedInstance().newMainContextChildContext()

    struct SharingCellIdentifiers {
        static let SettingsCellIdentifier = "SettingsTableViewCellIdentifier"
        static let SortableSwitchCellIdentifier = "SortableSwitchTableViewCellIdentifier"
        static let SwitchCellIdentifier = "SwitchTableViewCellIdentifier"
    }

    // MARK: - LifeCycle Methods

    @objc init(blog: Blog) {
        self.blog = blog

        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Manage", comment: "Verb. Title of the screen for managing sharing buttons and settings related to sharing.")

        let service = SharingService(managedObjectContext: managedObjectContext)
        buttons = service.allSharingButtonsForBlog(self.blog)
        configureTableView()
        setupSections()

        syncSharingButtons()
        syncSharingSettings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if didMakeChanges {
            self.saveButtonChanges(true)
        }
    }

    // MARK: - Sections Setup and Config

    /// Configures the table view. The table view is set to edit mode to allow
    /// rows in the buttons and more sections to be reordered.
    ///
    private func configureTableView() {
        tableView.register(SettingTableViewCell.self, forCellReuseIdentifier: SharingCellIdentifiers.SettingsCellIdentifier)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SharingCellIdentifiers.SortableSwitchCellIdentifier)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SharingCellIdentifiers.SwitchCellIdentifier)

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        tableView.setEditing(true, animated: false)
        tableView.allowsSelectionDuringEditing = true
    }

    /// Sets up the sections for the table view and configures their starting state.
    ///
    private func setupSections() {
        sections.append(setupButtonSection()) // buttons section should be section idx 0
        sections.append(setupMoreSection()) // more section should be section idx 1
        sections.append(setupShareLabelSection())
        sections.append(setupButtonStyleSection())
        if blog.isHostedAtWPcom {
            sections.append(setupReblogAndLikeSection())
            sections.append(setupCommentLikeSection())
        }
        sections.append(setupTwitterNameSection())

        configureTwitterNameSection()
        configureButtonRows()
        configureMoreRows()
    }

    /// Sets up the buttons section.  This section is sortable.
    ///
    private func setupButtonSection() -> SharingButtonsSection {
        let section = SharingButtonsSection()
        section.canSort = true
        section.headerText = NSLocalizedString("Sharing Buttons", comment: "Title of a list of buttons used for sharing content to other services.")

        return section
    }

    /// Sets up the more section. This section is sortable.
    ///
    private func setupMoreSection() -> SharingButtonsSection {
        let section = SharingButtonsSection()
        section.canSort = true
        section.headerText = NSLocalizedString("\"More\" Button", comment: "Title of a list of buttons used for sharing content to other services. These buttons appear when the user taps a `More` button.")
        section.footerText = NSLocalizedString("A \"more\" button contains a dropdown which displays sharing buttons", comment: "A short description of what the 'More' button is and how it works.")

        return section
    }

    /// Sets up the label section.
    ///
    private func setupShareLabelSection() -> SharingButtonsSection {
        let section = SharingButtonsSection()

        let row = SharingSettingRow()
        row.action = { [unowned self] in
            self.handleEditLabel()
        }
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryType = .disclosureIndicator
            cell.textLabel?.text = self.labelTitle
            cell.detailTextLabel!.text = self.blog.settings!.sharingLabel
        }
        section.rows = [row]
        return section
    }

    /// Sets up the button style section
    ///
    private func setupButtonStyleSection() -> SharingButtonsSection {
        let section = SharingButtonsSection()

        let row = SharingSettingRow()
        row.action = { [unowned self] in
            self.handleEditButtonStyle()
        }
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryType = .disclosureIndicator
            cell.textLabel?.text = self.buttonStyleTitle
            cell.detailTextLabel!.text = self.buttonStyles[self.blog.settings!.sharingButtonStyle]
        }
        section.rows = [row]
        return section
    }

    /// Sets up the reblog and the likes section
    ///
    private func setupReblogAndLikeSection() -> SharingButtonsSection {
        var rows = [SharingButtonsRow]()
        let section = SharingButtonsSection()
        section.headerText = NSLocalizedString("Reblog & Like", comment: "Title for a list of ssettings for editing a blog's Reblog and Like settings.")

        // Reblog button row
        var row = SharingSwitchRow()
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryView = cell.accessoryView
            cell.editingAccessoryType = cell.accessoryType

            if let switchCell = cell as? SwitchTableViewCell {
                switchCell.textLabel?.text = NSLocalizedString("Show Reblog button", comment: "Title for the `show reblog button` setting")
                switchCell.on = !self.blog.settings!.sharingDisabledReblogs
                switchCell.onChange = { newValue in
                    self.blog.settings!.sharingDisabledReblogs = !newValue
                    self.didMakeChanges = true
                    self.saveBlogSettingsChanges(false)

                    let properties = [
                        "checked": NSNumber(value: newValue)
                    ]
                    WPAppAnalytics.track(.sharingButtonShowReblogChanged, withProperties: properties, with: self.blog)
                }
            }
        }
        rows.append(row)

        // Like button row
        row = SharingSwitchRow()
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryView = cell.accessoryView
            cell.editingAccessoryType = cell.accessoryType

            if let switchCell = cell as? SwitchTableViewCell {
                switchCell.textLabel?.text = NSLocalizedString("Show Like button", comment: "Title for the `show like button` setting")
                switchCell.on = !self.blog.settings!.sharingDisabledLikes
                switchCell.onChange = { newValue in
                    self.blog.settings!.sharingDisabledLikes = !newValue
                    self.didMakeChanges = true
                    self.saveBlogSettingsChanges(false)
                }
            }
        }
        rows.append(row)

        section.rows = rows
        return section
    }

    /// Sets up the section for comment likes
    ///
    private  func setupCommentLikeSection() -> SharingButtonsSection {
        let section = SharingButtonsSection()
        section.footerText = NSLocalizedString("Allow all comments to be Liked by you and your readers", comment: "A short description of the comment like sharing setting.")

        let row = SharingSwitchRow()
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryView = cell.accessoryView
            cell.editingAccessoryType = cell.accessoryType

            if let switchCell = cell as? SwitchTableViewCell {
                switchCell.textLabel?.text = NSLocalizedString("Comment Likes", comment: "Title for the `comment likes` setting")
                switchCell.on = self.blog.settings!.sharingCommentLikesEnabled
                switchCell.onChange = { newValue in
                    self.blog.settings!.sharingCommentLikesEnabled = newValue
                    self.didMakeChanges = true
                    self.saveBlogSettingsChanges(false)
                }
            }
        }
        section.rows = [row]
        return section
    }

    /// Sets up the twitter names section. The contents of the section are displayed
    /// or not displayed depending on if the Twitter button is enabled.
    ///
    private func setupTwitterNameSection() -> SharingButtonsSection {
        return SharingButtonsSection()
    }

    /// Configures the twiter name section. When the twitter button is disabled,
    /// the section header is empty, and there are no rows.  When the twitter button
    /// is enabled. the section header and the row is shown.
    ///
    private func configureTwitterNameSection() {
        if !shouldShowTwitterSection() {
            twitterSection.footerText = " "
            twitterSection.rows.removeAll()
            return
        }

        twitterSection.footerText = NSLocalizedString("This will be included in tweets when people share using the Twitter button.", comment: "A description of the twitter sharing setting.")

        let row = SharingSettingRow()
        row.action = { [unowned self] in
            self.handleEditTwitterName()
        }
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryType = .disclosureIndicator
            cell.textLabel?.text = self.twitterUsernameTitle

            var name = self.blog.settings!.sharingTwitterName
            if name.count > 0 {
                name = "@\(name)"
            }
            cell.detailTextLabel?.text = name
        }
        twitterSection.rows = [row]
    }

    /// Creates a sortable row for the specified button.
    ///
    /// - Parameter button: The sharing button that the row will represent.
    ///
    /// - Returns: A SortableSharingSwitchRow.
    ///
    private  func sortableRowForButton(_ button: SharingButton) -> SortableSharingSwitchRow {
        let row = SortableSharingSwitchRow(buttonID: button.buttonID)
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.imageView?.image = self.iconForSharingButton(button)
            cell.imageView?.tintColor = .listIcon

            cell.editingAccessoryView = nil
            cell.editingAccessoryType = .none
            cell.textLabel?.text = button.name
        }
        return row
    }

    /// Creates a switch row for the specified button in the sharing buttons section.
    ///
    /// - Parameter button: The sharing button that the row will represent.
    ///
    /// - Returns: A SortableSharingSwitchRow.
    ///
    private func switchRowForButtonSectionButton(_ button: SharingButton) -> SortableSharingSwitchRow {
        let row = SortableSharingSwitchRow(buttonID: button.buttonID)
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            if let switchCell = cell as? SwitchTableViewCell {
                self.configureSortableSwitchCellAppearance(switchCell, button: button)
                switchCell.on = button.enabled && button.visible
                switchCell.onChange = { newValue in
                    button.enabled = newValue
                    if button.enabled {
                        button.visibility = button.enabled ? SharingButton.visible : nil
                    }

                    self.didMakeChanges = true
                    self.refreshMoreSection()
                }
            }
        }
        return row
    }

    /// Creates a switch row for the specified button in the more buttons section.
    ///
    /// - Parameter button: The sharing button that the row will represent.
    ///
    /// - Returns: A SortableSharingSwitchRow.
    ///
    private func switchRowForMoreSectionButton(_ button: SharingButton) -> SortableSharingSwitchRow {
        let row = SortableSharingSwitchRow(buttonID: button.buttonID)
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            if let switchCell = cell as? SwitchTableViewCell {
                self.configureSortableSwitchCellAppearance(switchCell, button: button)
                switchCell.on = button.enabled && !button.visible
                switchCell.onChange = { newValue in
                    button.enabled = newValue
                    if button.enabled {
                        button.visibility = button.enabled ? SharingButton.hidden : nil
                    }

                    self.didMakeChanges = true
                    self.refreshButtonsSection()
                }
            }
        }
        return row
    }

    /// Configures common appearance properties for the button switch cells.
    ///
    /// - Parameters:
    ///     - cell: The SwitchTableViewCell cell to configure
    ///     - button: The sharing button that the row will represent.
    ///
    private func configureSortableSwitchCellAppearance(_ cell: SwitchTableViewCell, button: SharingButton) {
        cell.editingAccessoryView = cell.accessoryView
        cell.editingAccessoryType = cell.accessoryType
        cell.imageView?.image = self.iconForSharingButton(button)
        cell.imageView?.tintColor = .listIcon
        cell.textLabel?.text = button.name
    }

    /// Configures the rows for the button section. When the section is editing,
    /// all buttons are shown with switch cells. When the section is not editing,
    /// only enabled and visible buttons are shown and the rows are sortable.
    ///
    private func configureButtonRows() {
        var rows = [SharingButtonsRow]()

        let row = SharingSwitchRow()
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            if let switchCell = cell as? SwitchTableViewCell {
                cell.editingAccessoryView = cell.accessoryView
                cell.editingAccessoryType = cell.accessoryType
                switchCell.textLabel?.text = NSLocalizedString("Edit sharing buttons", comment: "Title for the edit sharing buttons section")
                switchCell.on = self.buttonsSection.editing
                switchCell.onChange = { newValue in
                    self.buttonsSection.editing = !self.buttonsSection.editing
                    self.updateButtonOrderAfterEditing()
                    self.reloadButtons()
                }
            }
        }
        rows.append(row)

        if !buttonsSection.editing {
            let buttonsToShow = buttons.filter { (button) -> Bool in
                return button.enabled && button.visible
            }

            for button in buttonsToShow {
                rows.append(sortableRowForButton(button))
            }

        } else {

            for button in buttons {
                rows.append(switchRowForButtonSectionButton(button))
            }
        }

        buttonsSection.rows = rows
    }

    /// Configures the rows for the more section. When the section is editing,
    /// all buttons are shown with switch cells. When the section is not editing,
    /// only enabled and hidden buttons are shown and the rows are sortable.
    ///
    private func configureMoreRows() {
        var rows = [SharingButtonsRow]()

        let row = SharingSwitchRow()
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            if let switchCell = cell as? SwitchTableViewCell {
                cell.editingAccessoryView = cell.accessoryView
                cell.editingAccessoryType = cell.accessoryType
                switchCell.textLabel?.text = NSLocalizedString("Edit \"More\" button", comment: "Title for the edit more button section")
                switchCell.on = self.moreSection.editing
                switchCell.onChange = { newValue in
                    self.updateButtonOrderAfterEditing()
                    self.moreSection.editing = !self.moreSection.editing
                   self.reloadButtons()
                }
            }
        }
        rows.append(row)

        if !moreSection.editing {
            let buttonsToShow = buttons.filter { (button) -> Bool in
                return button.enabled && !button.visible
            }

            for button in buttonsToShow {
                rows.append(sortableRowForButton(button))
            }

        } else {

            for button in buttons {
                rows.append(switchRowForMoreSectionButton(button))
            }
        }

        moreSection.rows = rows
    }

    /// Refreshes the rows for but button section (also the twitter section if
    /// needed) and reloads the section.
    ///
    private func refreshButtonsSection() {
        configureButtonRows()
        configureTwitterNameSection()

        let indexes: IndexSet = [buttonSectionIndex, sections.count - 1]
        tableView.reloadSections(indexes, with: .automatic)
    }

    /// Refreshes the rows for but more section (also the twitter section if
    /// needed) and reloads the section.
    ///
    private func refreshMoreSection() {
        configureMoreRows()
        configureTwitterNameSection()

        let indexes: IndexSet = [moreSectionIndex, sections.count - 1]
        tableView.reloadSections(indexes, with: .automatic)
    }

    /// Provides the icon that represents the sharing button's service.
    ///
    /// - Parameter button: The sharing button for the icon.
    ///
    /// - Returns: The UIImage for the icon
    ///
    private func iconForSharingButton(_ button: SharingButton) -> UIImage {
        return WPStyleGuide.iconForService(button.buttonID as NSString)
    }

    // MARK: - Instance Methods

    /// Whether the twitter section should be present or not.
    ///
    /// - Returns: true if the twitter section should be shown. False otherwise.
    ///
    private func shouldShowTwitterSection() -> Bool {
        for button in buttons {
            if button.buttonID == twitterServiceID {
                return button.enabled
            }
        }
        return false
    }

    /// Saves changes to blog settings back to the blog and optionally refreshes
    /// the tableview.
    ///
    /// - Parameter refresh: True if the tableview should be reloaded.
    ///
    private func saveBlogSettingsChanges(_ refresh: Bool) {
        if refresh {
            tableView.reloadData()
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)
        let dotComID = blog.dotComID
        service.updateSettings(
            for: self.blog,
            success: {
                WPAppAnalytics.track(.sharingButtonSettingsChanged, withBlogID: dotComID)
            },
            failure: { [weak self] (error: Error) in
                let error = error as NSError
                DDLogError(error.description)
                self?.showErrorSyncingMessage(error)
            })
    }

    /// Syncs sharing buttons from the user's blog and reloads the button sections
    /// when finished.  Fails silently if there is an error.
    ///
    private func syncSharingButtons() {
        let service = SharingService(managedObjectContext: managedObjectContext)
        service.syncSharingButtonsForBlog(self.blog,
            success: { [weak self] in
                self?.reloadButtons()
            },
            failure: { (error: NSError?) in
                DDLogError((error?.description)!)
        })
    }

    /// Sync sharing settings from the user's blog and reloads the setting sections
    /// when finished.  Fails silently if there is an error.
    ///
    private func syncSharingSettings() {
        let service = BlogService(managedObjectContext: managedObjectContext)
        service.syncSettings(for: blog, success: { [weak self] in
                self?.reloadSettingsSections()
            },
            failure: { (error: Error) in
                let error = error as NSError
                DDLogError(error.description)
        })
    }

    /// Reloads the sections for different button settings.
    ///
    private func reloadSettingsSections() {
        let settingsSections = NSMutableIndexSet()
        for i in 0..<sections.count {
            if i <= buttonSectionIndex {
                continue
            }
            settingsSections.add(i)
        }
        tableView.reloadSections(settingsSections as IndexSet, with: .automatic)
    }

    // MARK: - Update And Save Buttons

    /// Updates rows after editing.
    ///
    private func updateButtonOrderAfterEditing() {
        let buttonsForButtonSection = buttons.filter { (btn) -> Bool in
            return btn.enabled && btn.visible
        }
        let buttonsForMoreSection = buttons.filter { (btn) -> Bool in
            return btn.enabled && !btn.visible
        }
        let remainingButtons = buttons.filter { (btn) -> Bool in
            return !btn.enabled
        }

        var order = 0
        for button in buttonsForButtonSection {
            button.order = NSNumber(value: order)
            order += 1
        }
        for button in buttonsForMoreSection {
            button.order = NSNumber(value: order)
            order += 1
        }
        for button in remainingButtons {
            // we'll update the order for the remaining buttons but this is not
            // respected by the REST API and changes after syncing.
            button.order = NSNumber(value: order)
            order += 1
        }
    }

    /// Saves changes to sharing buttons to core data, reloads the buttons, then
    /// pushes the changes up to the blog, optionally refreshing when done.
    ///
    /// - Parameter refreshAfterSync: If true buttons are reloaded when the sync completes.
    ///
    private func saveButtonChanges(_ refreshAfterSync: Bool) {
        let context = ContextManager.sharedInstance().mainContext
        ContextManager.sharedInstance().save(context) { [weak self] in
            self?.reloadButtons()
            self?.syncButtonChangesToBlog(refreshAfterSync)
        }
    }

    /// Retrives a fresh copy of the SharingButtons from core data, updating the
    /// `buttons` property and refreshes the button section and the more section.
    ///
    private func reloadButtons() {
        let service = SharingService(managedObjectContext: managedObjectContext)
        buttons = service.allSharingButtonsForBlog(blog)

        refreshButtonsSection()
        refreshMoreSection()
    }

    /// Saves changes to the sharing buttons back to the blog.
    ///
    /// - Parameter refresh: True if the tableview sections should be reloaded.
    ///
    private func syncButtonChangesToBlog(_ refresh: Bool) {
        let service = SharingService(managedObjectContext: managedObjectContext)
        service.updateSharingButtonsForBlog(blog,
            sharingButtons: buttons,
            success: {[weak self] in
                if refresh {
                    self?.reloadButtons()
                }
            },
            failure: { [weak self] (error: NSError?) in
                DDLogError((error?.description)!)
                self?.showErrorSyncingMessage(error)
        })
    }

    /// Shows an alert. The localized description of the specified NSError is
    /// included in the alert.
    ///
    /// - Parameter error: An NSError object.
    ///
    private func showErrorSyncingMessage(_ error: NSError?) {
        let title = NSLocalizedString("Could Not Save Changes", comment: "Title of an prompt letting the user know there was a problem saving.")
        var message = NSLocalizedString("There was a problem saving changes to sharing management.", comment: "A short error message shown in a prompt.")
        if let error = error {
            message.append(error.localizedDescription)
        }
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addCancelActionWithTitle(NSLocalizedString("OK", comment: "A button title."), handler: nil)

        controller.presentFromRootViewController()
    }

    // MARK: - Actions

    /// Called when the user taps the label row. Shows a controller to change the
    /// edit label text.
    ///
    private func handleEditLabel() {
        let text = blog.settings!.sharingLabel
        let placeholder = NSLocalizedString("Type a label", comment: "A placeholder for the sharing label.")
        let hint = NSLocalizedString("Change the text of the sharing buttons' label. This text won't appear until you add at least one sharing button.", comment: "Instructions for editing the sharing label.")
        let controller = SettingsTextViewController(text: text, placeholder: placeholder, hint: hint)

        controller.title = labelTitle
        controller.onValueChanged = {[unowned self] (value) in
            guard value != self.blog.settings!.sharingLabel else {
                return
            }
            self.blog.settings!.sharingLabel = value
            self.saveBlogSettingsChanges(true)
        }

        navigationController?.pushViewController(controller, animated: true)
    }

    /// Called when the user taps the button style row.  Shows a controller to
    /// choose from available button styles.
    ///
    private func handleEditButtonStyle() {
        var titles = [String]()
        var values = [String]()
        _ = buttonStyles.map({ (k: String, v: String) in
            titles.append(v)
            values.append(k)
        })

        let currentValue = blog.settings!.sharingButtonStyle

        let dict: [String: AnyObject] = [
            SettingsSelectionDefaultValueKey: values[0] as AnyObject,
            SettingsSelectionTitleKey: buttonStyleTitle as AnyObject,
            SettingsSelectionTitlesKey: titles as AnyObject,
            SettingsSelectionValuesKey: values as AnyObject,
            SettingsSelectionCurrentValueKey: currentValue as AnyObject
        ]

        let controller = SettingsSelectionViewController(dictionary: dict)
        controller?.onItemSelected = { [unowned self] (selected) in
            if let str = selected as? String {
                if self.blog.settings!.sharingButtonStyle == str {
                    return
                }

                self.blog.settings!.sharingButtonStyle = str
                self.saveBlogSettingsChanges(true)
            }

        }
        navigationController?.pushViewController(controller!, animated: true)
    }

    /// Called when the user taps the twitter name row. Shows a controller to change
    /// the twitter name text.
    ///
    private func handleEditTwitterName() {
        let text = blog.settings!.sharingTwitterName
        let placeholder = NSLocalizedString("Username", comment: "A placeholder for the twitter username")
        let hint = NSLocalizedString("This will be included in tweets when people share using the Twitter button.", comment: "Information about the twitter sharing feature.")
        let controller = SettingsTextViewController(text: text, placeholder: placeholder, hint: hint)

        controller.title = twitterUsernameTitle
        controller.onValueChanged = {[unowned self] (value) in
            if value == self.blog.settings!.sharingTwitterName {
                return
            }

            // Remove the @ sign if it was entered.
            var str = NSString(string: value)
            str = str.replacingOccurrences(of: "@", with: "") as NSString
            self.blog.settings!.sharingTwitterName = str as String
            self.saveBlogSettingsChanges(true)
        }

        navigationController?.pushViewController(controller, animated: true)
    }

    /// Represents a section in the sharinging management table view.
    ///
    class SharingButtonsSection {
        var rows: [SharingButtonsRow] = [SharingButtonsRow]()
        var headerText: String?
        var footerText: String?
        var editing = false
        var canSort = false
    }

    /// Represents a row in the sharing management table view.
    ///
    class SharingButtonsRow {
        var cellIdentifier = ""
        var action: SharingButtonsRowAction?
        var configureCell: SharingButtonsCellConfig?
    }

    /// A sortable switch row.  By convention this is only used for sortable button rows
    ///
    class SortableSharingSwitchRow: SharingButtonsRow {
        var buttonID: String
        init(buttonID: String) {
            self.buttonID = buttonID
            super.init()
            cellIdentifier = SharingCellIdentifiers.SortableSwitchCellIdentifier
        }
    }

    /// An unsortable switch row.
    ///
    class SharingSwitchRow: SharingButtonsRow {
        override init() {
            super.init()
            cellIdentifier = SharingCellIdentifiers.SwitchCellIdentifier
        }
    }

    /// A row for sharing settings that do not need a switch control in its cell.
    ///
    class SharingSettingRow: SharingButtonsRow {
        override init() {
            super.init()
            cellIdentifier = SharingCellIdentifiers.SettingsCellIdentifier
        }
    }
}

// MARK: - TableView Delegate Methods
extension SharingButtonsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: row.cellIdentifier)!

        row.configureCell?(cell)

        return cell
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        return sections[section].headerText
    }

    override func tableView(_ tableView: UITableView,
                            willDisplayHeaderView view: UIView,
                            forSection section: Int) {
    }

    override func tableView(_ tableView: UITableView,
                            titleForFooterInSection section: Int) -> String? {
        return sections[section].footerText
    }

    override func tableView(_ tableView: UITableView,
                            willDisplayFooterView view: UIView,
                            forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]
        if row.cellIdentifier != SharingCellIdentifiers.SettingsCellIdentifier {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        row.action?()
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Since we want to be able to order particular rows, let's only allow editing for those specific rows.
        // Note: We have to allow editing because UITableView will only give us the ordering accessory while editing is toggled.
        let section = sections[indexPath.section]
        return section.canSort && !section.editing && indexPath.row > 0
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let section = sections[indexPath.section]
        return section.canSort && !section.editing && indexPath.row > 0
    }

    // The table view is in editing mode, but no cells should show the delete button,
    // only the move icon.
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    // The first row in the section is static containing the on/off toggle.
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        let row = proposedDestinationIndexPath.row > 0 ? proposedDestinationIndexPath.row : 1
        return IndexPath(row: row, section: sourceIndexPath.section)
    }

    // Updates the order of the moved button.
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let sourceSection = sections[sourceIndexPath.section]

        let diff =  destinationIndexPath.row - sourceIndexPath.row
        let movedRow = sourceSection.rows[sourceIndexPath.row] as! SortableSharingSwitchRow

        let movedButton = buttons.filter { (button) -> Bool in
            return button.buttonID == movedRow.buttonID
        }
        let theButton = movedButton.first!

        let oldIndex = buttons.index(of: theButton)!
        let newIndex = oldIndex + diff

        let buttonsArr = NSMutableArray(array: buttons)
        buttonsArr.removeObject(at: oldIndex)
        buttonsArr.insert(theButton, at: newIndex)

        // Update the order for all buttons
        for (index, button) in buttonsArr.enumerated() {
            let sharingButton = button as! SharingButton
            sharingButton.order = NSNumber(value: index)
        }
        self.didMakeChanges = true
        WPAppAnalytics.track(.sharingButtonOrderChanged, with: blog)
    }
}
