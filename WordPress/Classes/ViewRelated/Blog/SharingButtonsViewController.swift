import UIKit
import WordPressShared

/// Manages which sharing button are displayed, their order, and other settings 
/// related to sharing.
///
@objc class SharingButtonsViewController : UITableViewController
{
    let buttonSectionIndex = 0
    let moreSectionIndex = 1

    let blog: Blog
    var buttons = [SharingButton]()
    var sections = [SharingButtonsSection]()
    var buttonsSection: SharingButtonsSection {
        return sections[buttonSectionIndex]
    }

    var moreSection: SharingButtonsSection {
        return sections[moreSectionIndex]
    }

    var twitterSection: SharingButtonsSection {
        return sections.last!
    }

    let buttonStyles = [
        "icon-text": NSLocalizedString("Icon & Text", comment: "Title of a button style"),
        "icon": NSLocalizedString("Icon Only", comment: "Title of a button style"),
        "text": NSLocalizedString("Text Only", comment: "Title of a button style"),
        "official": NSLocalizedString("Official Buttons", comment: "Title of a button style")
    ]

    let buttonStyleTitle = NSLocalizedString("Button Style", comment:"Title for a list of different button styles.")
    let labelTitle = NSLocalizedString("Label", comment:"Noun. Title for the setting to edit the sharing label text.")
    let twitterUsernameTitle = NSLocalizedString("Twitter Username", comment:"Title for the setting to edit the twitter username used when sharing to twitter.")
    let twitterServiceID = "twitter"
    let managedObjectContext = ContextManager.sharedInstance().newMainContextChildContext()


    // MARK: - LifeCycle Methods


    init(blog: Blog) {
        self.blog = blog

        super.init(style: .Grouped)
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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadData()
    }


    // MARK: - Sections Setup and Config


    /// Configures the table view. The table view is set to edit mode to allow 
    /// rows in the buttons and more sections to be reordered.
    ///
    func configureTableView() {
        tableView.registerClass(SettingTableViewCell.self, forCellReuseIdentifier: SharingCellIdentifiers.SettingsCellIdentifier)
        tableView.registerClass(SwitchTableViewCell.self, forCellReuseIdentifier: SharingCellIdentifiers.SortableSwitchCellIdentifier)
        tableView.registerClass(SwitchTableViewCell.self, forCellReuseIdentifier: SharingCellIdentifiers.SwitchCellIdentifier)

        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
        tableView.setEditing(true, animated: false)
        tableView.allowsSelectionDuringEditing = true
    }


    /// Sets up the sections for the table view and configures their starting state.
    ///
    func setupSections() {
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
    func setupButtonSection() -> SharingButtonsSection {
        let section = SharingButtonsSection()
        section.canSort = true
        section.headerText = NSLocalizedString("Sharing Buttons", comment: "Title of a list of buttons used for sharing content to other services.")

        return section
    }


    /// Sets up the more section. This section is sortable.
    ///
    func setupMoreSection() -> SharingButtonsSection {
        let section = SharingButtonsSection()
        section.canSort = true
        section.headerText = NSLocalizedString("\"More\" Button", comment: "Title of a list of buttons used for sharing content to other services. These buttons appear when the user taps a `More` button.")
        section.footerText = NSLocalizedString("A \"more\" button contains a dropdown which displays sharing buttons", comment: "A short description of what the 'More' button is and how it works.")

        return section
    }


    /// Sets up the label section.
    ///
    func setupShareLabelSection() -> SharingButtonsSection {
        let section = SharingButtonsSection()

        let row = SharingSettingRow()
        row.action = { [unowned self] in
            self.handleEditLabel()
        }
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryType = .DisclosureIndicator
            cell.textLabel?.text = self.labelTitle
            cell.detailTextLabel?.text = self.blog.settings.sharingLabel
        }
        section.rows = [row]
        return section
    }


    /// Sets up the button style section
    ///
    func setupButtonStyleSection() -> SharingButtonsSection {
        let section = SharingButtonsSection()

        let row = SharingSettingRow()
        row.action = { [unowned self] in
            self.handleEditButtonStyle()
        }
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryType = .DisclosureIndicator
            cell.textLabel?.text = self.buttonStyleTitle
            cell.detailTextLabel?.text = self.buttonStyles[self.blog.settings.sharingButtonStyle]
        }
        section.rows = [row]
        return section
    }


    /// Sets up the reblog and the likes section
    ///
    func setupReblogAndLikeSection() -> SharingButtonsSection {
        var rows = [SharingButtonsRow]()
        let section = SharingButtonsSection()
        section.headerText = NSLocalizedString("Reblog & Like", comment: "Title for a list of ssettings for editing a blog's Reblog and Like settings.")

        // Reblog button row
        var row = SharingSwitchRow()
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryView = cell.accessoryView
            cell.editingAccessoryType = cell.accessoryType

            if let switchCell = cell as? SwitchTableViewCell {
                switchCell.textLabel?.text = NSLocalizedString("Show Reblog button", comment:"Title for the `show reblog button` setting")
                switchCell.on = !self.blog.settings.sharingDisabledReblogs
                switchCell.onChange = { newValue in
                    self.blog.settings.sharingDisabledReblogs = !newValue
                    self.saveBlogSettingsChanges(false)
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
                switchCell.textLabel?.text = NSLocalizedString("Show Like button", comment:"Title for the `show like button` setting")
                switchCell.on = !self.blog.settings.sharingDisabledLikes
                switchCell.onChange = { newValue in
                    self.blog.settings.sharingDisabledLikes = !newValue
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
    func setupCommentLikeSection() -> SharingButtonsSection {
        let section = SharingButtonsSection()
        section.footerText = NSLocalizedString("Allow all comments to be Liked by you and your readers", comment:"A short description of the comment like sharing setting.")

        let row = SharingSwitchRow()
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryView = cell.accessoryView
            cell.editingAccessoryType = cell.accessoryType

            if let switchCell = cell as? SwitchTableViewCell {
                switchCell.textLabel?.text = NSLocalizedString("Comment Likes", comment:"Title for the `comment likes` setting")
                switchCell.on = self.blog.settings.sharingCommentLikesEnabled
                switchCell.onChange = { newValue in
                    self.blog.settings.sharingCommentLikesEnabled = newValue
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
    func setupTwitterNameSection() -> SharingButtonsSection {
        return SharingButtonsSection()
    }


    /// Configures the twiter name section. When the twitter button is disabled,
    /// the section header is empty, and there are no rows.  When the twitter button
    /// is enabled. the section header and the row is shown.
    ///
    func configureTwitterNameSection() {
        if !shouldShowTwitterSection() {
            twitterSection.footerText = " "
            twitterSection.rows.removeAll()
            return
        }

        twitterSection.footerText = NSLocalizedString("This will be included in tweets when people share using the Twitter button.", comment:"A description of the twitter sharing setting.")

        let row = SharingSettingRow()
        row.action = { [unowned self] in
            self.handleEditTwitterName()
        }
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryType = .DisclosureIndicator
            cell.textLabel?.text = self.twitterUsernameTitle

            var name = self.blog.settings.sharingTwitterName
            if name.characters.count > 0 {
                name = "@\(name)"
            }
            cell.detailTextLabel?.text = name
        }
        twitterSection.rows = [row]
    }


    /// Creates a sortable row for the specified button.
    /// 
    /// - Parameters:
    ///     - button: The sharing button that the row will represent.
    ///
    /// - Returns: A SortableSharingSwitchRow.
    ///
    func sortableRowForButton(button: SharingButton) -> SortableSharingSwitchRow {
        let row = SortableSharingSwitchRow(buttonID: button.buttonID)
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.imageView?.image = self.iconForSharingButton(button)
            cell.imageView?.tintColor = WPStyleGuide.greyLighten20()

            cell.editingAccessoryView = nil
            cell.editingAccessoryType = .None
            cell.textLabel?.text = button.name
        }
        return row
    }


    /// Creates a switch row for the specified button in the sharing buttons section.
    ///
    /// - Parameters:
    ///     - button: The sharing button that the row will represent.
    ///
    /// - Returns: A SortableSharingSwitchRow.
    ///
    func switchRowForButtonSectionButton(button: SharingButton) -> SortableSharingSwitchRow {
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
                    self.refreshMoreSection()
                }
            }
        }
        return row
    }


    /// Creates a switch row for the specified button in the more buttons section.
    ///
    /// - Parameters:
    ///     - button: The sharing button that the row will represent.
    ///
    /// - Returns: A SortableSharingSwitchRow.
    ///
    func switchRowForMoreSectionButton(button: SharingButton) -> SortableSharingSwitchRow {
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
    func configureSortableSwitchCellAppearance(cell: SwitchTableViewCell, button: SharingButton) {
        cell.editingAccessoryView = cell.accessoryView
        cell.editingAccessoryType = cell.accessoryType
        cell.imageView?.image = self.iconForSharingButton(button)
        cell.imageView?.tintColor = WPStyleGuide.greyLighten20()
        cell.textLabel?.text = button.name
    }


    /// Configures the rows for the button section. When the section is editing,
    /// all buttons are shown with switch cells. When the section is not editing, 
    /// only enabled and visible buttons are shown and the rows are sortable.
    ///
    func configureButtonRows() {
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
                    self.saveButtonChanges(true)
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
    func configureMoreRows() {
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
                    self.saveButtonChanges(true)
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
    func refreshButtonsSection() {
        configureButtonRows()
        configureTwitterNameSection()

        let indexSet = NSMutableIndexSet(index: buttonSectionIndex)
        indexSet.addIndex(sections.count - 1)

        tableView.reloadSections(indexSet, withRowAnimation: .Automatic)
    }


    /// Refreshes the rows for but more section (also the twitter section if
    /// needed) and reloads the section.
    ///
    func refreshMoreSection() {
        configureMoreRows()
        configureTwitterNameSection()

        let indexSet = NSMutableIndexSet(index: moreSectionIndex)
        indexSet.addIndex(sections.count - 1)

        tableView.reloadSections(indexSet, withRowAnimation: .Automatic)
    }


    /// Provides the icon that represents the sharing button's service.
    ///
    /// - Parameters:
    ///     - button: The sharing button for the icon.
    ///
    /// - Returns: The UIImage for the icon
    ///
    func iconForSharingButton(button: SharingButton) -> UIImage {
        return WPStyleGuide.iconForService(button.buttonID)
    }


    // MARK: - Instance Methods


    /// Whether the twitter section should be present or not.
    /// 
    /// - Returns: true if the twitter section should be shown. False otherwise.
    ///
    func shouldShowTwitterSection() -> Bool {
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
    /// - Parameters:
    ///     - refresh: True if the tableview should be reloaded.
    ///
    func saveBlogSettingsChanges(refresh: Bool) {
        if refresh {
            tableView.reloadData()
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)
        service.updateSettingsForBlog(self.blog, success: nil, failure: { [weak self] (error: NSError!) in
            DDLogSwift.logError(error.description)
            self?.showErrorSyncingMessage(error)
        })
    }


    /// Syncs sharing buttons from the user's blog and reloads the button sections
    /// when finished.  Fails silently if there is an error.
    ///
    func syncSharingButtons() {
        let service = SharingService(managedObjectContext: managedObjectContext)
        service.syncSharingButtonsForBlog(self.blog,
            success: { [weak self] in
                self?.reloadButtons()
            },
            failure: { (error: NSError!) in
                DDLogSwift.logError(error.description)
        })
    }


    /// Sync sharing settings from the user's blog and reloads the setting sections
    /// when finished.  Fails silently if there is an error.
    ///
    func syncSharingSettings() {
        let service = BlogService(managedObjectContext: managedObjectContext)
        service.syncSettingsForBlog(blog, success: { [weak self] in
                self?.reloadSettingsSections()
            },
            failure: { (error: NSError!) in
                DDLogSwift.logError(error.description)
        })
    }


    /// Reloads the sections for different button settings.
    ///
    func reloadSettingsSections() {
        let settingsSections = NSMutableIndexSet()
        for i in 0..<sections.count {
            if i <= buttonSectionIndex {
                continue
            }
            settingsSections.addIndex(i)
        }
        tableView.reloadSections(settingsSections, withRowAnimation: .Automatic)
    }


    // MARK: - Update And Save Buttons


    /// Updates rows after editing.
    ///
    func updateButtonOrderAfterEditing() {
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
            button.order = order
            order += 1
        }
        for button in buttonsForMoreSection {
            button.order = order
            order += 1
        }
        for button in remainingButtons {
            // we'll update the order for the remaining buttons but this is not
            // respected by the REST API and changes after syncing.
            button.order = order
            order += 1
        }
    }


    /// Saves changes to sharing buttons to core data, reloads the buttons, then
    /// pushes the changes up to the blog, optionally refreshing when done.
    ///
    /// - Parameters:
    ///     - refreshAfterSync: If true buttons are reloaded when the sync completes.
    ///
    func saveButtonChanges(refreshAfterSync: Bool) {
        let context = ContextManager.sharedInstance().mainContext
        ContextManager.sharedInstance().saveContext(context) { [weak self] in
            self?.reloadButtons()
            self?.syncButtonChangesToBlog(refreshAfterSync)
        }
    }


    /// Retrives a fresh copy of the SharingButtons from core data, updating the
    /// `buttons` property and refreshes the button section and the more section.
    ///
    func reloadButtons() {
        let service = SharingService(managedObjectContext: managedObjectContext)
        buttons = service.allSharingButtonsForBlog(blog)

        refreshButtonsSection()
        refreshMoreSection()
    }


    /// Saves changes to the sharing buttons back to the blog.
    ///
    /// - Parameters:
    ///     - refresh: True if the tableview sections should be reloaded.
    ///
    func syncButtonChangesToBlog(refresh: Bool) {
        let service = SharingService(managedObjectContext: managedObjectContext)
        service.updateSharingButtonsForBlog(blog,
            sharingButtons: buttons,
            success: {[weak self] in
                if refresh {
                    self?.reloadButtons()
                }
            },
            failure: { [weak self] (error: NSError!) in
                DDLogSwift.logError(error.description)
                self?.showErrorSyncingMessage(error)
        })
    }


    /// Shows an alert. The localized description of the specified NSError is 
    /// included in the alert.
    ///
    /// - Parameters: 
    ///     - error: An NSError object.
    ///
    func showErrorSyncingMessage(error: NSError) {
        let title = NSLocalizedString("Could Not Save Changes", comment: "Title of an prompt letting the user know there was a problem saving.")
        let message = NSLocalizedString("There was a problem saving changes to sharing management.", comment: "A short error message shown in a prompt.")
        let controller = UIAlertController(title: title, message: "\(message) \(error.localizedDescription)", preferredStyle: .Alert)
        controller.addCancelActionWithTitle(NSLocalizedString("OK", comment: "A button title."), handler: nil)

        controller.presentFromRootViewController()
    }


    // MARK: - Actions


    /// Called when the user taps the label row. Shows a controller to change the
    /// edit label text.
    ///
    func handleEditLabel() {
        let text = blog.settings.sharingLabel
        let placeholder = NSLocalizedString("Type a label", comment: "A placeholder for the sharing label.")
        let hint = NSLocalizedString("Change the text of the sharing button's label. This text won't appear until you add at least one sharing button.", comment: "Instructions for editing the sharing label.")
        let controller = SettingsTextViewController(text: text, placeholder: placeholder, hint: hint, isPassword: false)

        controller.title = labelTitle
        controller.onValueChanged = {[unowned self] (value) in
            guard value != self.blog.settings.sharingLabel else {
                return
            }
            self.blog.settings.sharingLabel = value
            self.saveBlogSettingsChanges(true)
        }

        navigationController?.pushViewController(controller, animated: true)
    }


    /// Called when the user taps the button style row.  Shows a controller to 
    /// choose from available button styles.
    ///
    func handleEditButtonStyle() {
        var titles = [String]()
        var values = [String]()
        _ = buttonStyles.map({ (k: String, v: String) in
            titles.append(v)
            values.append(k)
        })

        let currentValue = blog.settings.sharingButtonStyle

        let dict: [String: AnyObject] = [
            SettingsSelectionDefaultValueKey: values[0],
            SettingsSelectionTitleKey: buttonStyleTitle,
            SettingsSelectionTitlesKey: titles,
            SettingsSelectionValuesKey: values,
            SettingsSelectionCurrentValueKey: currentValue
        ]

        let controller = SettingsSelectionViewController(dictionary: dict)
        controller.onItemSelected = { [unowned self] (selected) in
            if let str = selected as? String {
                if self.blog.settings.sharingButtonStyle == str {
                    return
                }

                self.blog.settings.sharingButtonStyle = str
                self.saveBlogSettingsChanges(true)
            }

        }
        navigationController?.pushViewController(controller, animated: true)
    }


    /// Called when the user taps the twitter name row. Shows a controller to change
    /// the twitter name text.
    ///
    func handleEditTwitterName() {
        let text = blog.settings.sharingTwitterName
        let placeholder = NSLocalizedString("Username", comment: "A placeholder for the twitter username")
        let hint = NSLocalizedString("This will be included in tweets when people share using the Twitter button.", comment: "Information about the twitter sharing feature.")
        let controller = SettingsTextViewController(text: text, placeholder: placeholder, hint: hint, isPassword: false)

        controller.title = twitterUsernameTitle
        controller.onValueChanged = {[unowned self] (value) in
            if value == self.blog.settings.sharingTwitterName {
                return
            }

            // Remove the @ sign if it was entered. 
            var str = NSString(string: value)
            str = str.stringByReplacingOccurrencesOfString("@", withString: "")
            self.blog.settings.sharingTwitterName = str as String
            self.saveBlogSettingsChanges(true)
        }

        navigationController?.pushViewController(controller, animated: true)
    }


    // MARK: - TableView Delegate Methods


    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]

        let cell = tableView.dequeueReusableCellWithIdentifier(row.cellIdentifier)!

        row.configureCell?(cell)

        return cell
    }


    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].headerText
    }


    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = self.tableView(tableView, titleForHeaderInSection: section) else {
            return nil
        }

        let headerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Header)
        headerView.title = title
        return headerView
    }


    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let title = self.tableView(tableView, titleForHeaderInSection: section)
        return WPTableViewSectionHeaderFooterView.heightForHeader(title, width: view.bounds.width)
    }


    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footerText
    }


    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let title = self.tableView(tableView, titleForFooterInSection: section) else {
            return nil
        }

        let footerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Footer)
        footerView.title = title
        return footerView
    }


    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let title = self.tableView(tableView, titleForFooterInSection: section)
        return WPTableViewSectionHeaderFooterView.heightForFooter(title, width: view.bounds.width)
    }


    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]
        if row.cellIdentifier != SharingCellIdentifiers.SettingsCellIdentifier {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        row.action?()
    }


    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let section = sections[indexPath.section]
        return section.canSort && !section.editing && indexPath.row > 0
    }


    // The table view is in editing mode, but no cells should show the delete button,
    // only the move icon.
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .None
    }


    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }


    // The first row in the section is static containing the on/off toggle.
    override func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        let row = proposedDestinationIndexPath.row > 0 ? proposedDestinationIndexPath.row : 1
        return NSIndexPath(forRow: row, inSection: sourceIndexPath.section)
    }


    // Updates the order of the moved button.
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let sourceSection = sections[sourceIndexPath.section]

        let diff =  destinationIndexPath.row - sourceIndexPath.row
        let movedRow = sourceSection.rows[sourceIndexPath.row] as! SortableSharingSwitchRow

        let movedButton = buttons.filter { (button) -> Bool in
            return button.buttonID == movedRow.buttonID
        }
        let theButton = movedButton.first!

        let oldIndex = buttons.indexOf(theButton)!
        let newIndex = oldIndex + diff

        let buttonsArr = NSMutableArray(array: buttons)
        buttonsArr.removeObjectAtIndex(oldIndex)
        buttonsArr.insertObject(theButton, atIndex: newIndex)

        // Update the order for all buttons
        for (index, button) in buttonsArr.enumerate() {
            let sharingButton = button as! SharingButton
            sharingButton.order = index
        }

        self.saveButtonChanges(false)
    }


    // MARK: - View Model Assets


    typealias SharingButtonsRowAction = () -> Void
    typealias SharingButtonsCellConfig = (UITableViewCell) -> Void


    struct SharingCellIdentifiers {
        static let SettingsCellIdentifier = "SettingsTableViewCellIdentifier"
        static let SortableSwitchCellIdentifier = "SortableSwitchTableViewCellIdentifier"
        static let SwitchCellIdentifier = "SwitchTableViewCellIdentifier"
    }


    /// Represents a section in the sharinging management table view.
    ///
    class SharingButtonsSection
    {
        var rows: [SharingButtonsRow] = [SharingButtonsRow]()
        var headerText: String?
        var footerText: String?
        var editing = false
        var canSort = false
    }


    /// Represents a row in the sharing management table view.
    ///
    class SharingButtonsRow
    {
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
