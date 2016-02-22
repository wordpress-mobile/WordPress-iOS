import UIKit
import WordPressShared

///
///
@objc class SharingButtonsViewController : UITableViewController
{
    var blog: Blog
    var buttons = [SharingButton]()
    var sections = [SharingButtonsSection]()
    var buttonsSection: SharingButtonsSection {
        return sections[0]
    }

    var moreSection: SharingButtonsSection {
        return sections[1]
    }

    var twitterSection: SharingButtonsSection {
        return sections.last!
    }

    let buttonStyles = [
        "icon-text": "Icon & Text",
        "icon": "Icon Only",
        "text": "Text Only",
        "official": "Official Buttons"
    ]


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

        navigationItem.title = NSLocalizedString("Manage", comment: "")

        let service = SharingService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        buttons = service.allSharingButtonsForBlog(self.blog)
        configureTableView()
        setupSections()
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
    }


    /// Sets up the sections for the table view and configures their starting state.
    ///
    func setupSections() {
        sections.append(setupButtonSection())
        sections.append(setupMoreSection())
        sections.append(setupShareLabelSection())
        sections.append(setupButtonStyleSection())
        sections.append(setupReblogAndLikeSection())
        sections.append(setupCommentLikeSection())
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
        section.headerText = NSLocalizedString("Sharing Buttons", comment:"")

        return section
    }


    /// Sets up the more section. This section is sortable.
    ///
    func setupMoreSection() -> SharingButtonsSection {
        let section = SharingButtonsSection()
        section.canSort = true
        section.headerText = NSLocalizedString("\"More\" Button", comment:"")
        section.footerText = NSLocalizedString("A \"more\" button contains a dropdown which displays sharing buttons", comment:"")

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
            cell.textLabel?.text = NSLocalizedString("Label", comment:"")
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
            cell.textLabel?.text = NSLocalizedString("Button Style", comment:"")
            cell.detailTextLabel?.text = self.buttonStyles[self.blog.settings.sharingButtonStyle]!
        }
        section.rows = [row]
        return section
    }


    /// Sets up the reblog and the likes section
    ///
    func setupReblogAndLikeSection() -> SharingButtonsSection {
        var rows = [SharingButtonsRow]()
        let section = SharingButtonsSection()
        section.headerText = NSLocalizedString("Reblog & Like", comment:"")

        // Reblog button row
        var row = SharingSwitchRow()
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryView = cell.accessoryView
            cell.editingAccessoryType = cell.accessoryType

            if let switchCell = cell as? SwitchTableViewCell {
                switchCell.textLabel?.text = NSLocalizedString("Show Reblog button", comment:"")
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
                switchCell.textLabel?.text = NSLocalizedString("Show Like button", comment:"")
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
        section.footerText = NSLocalizedString("Allow all comments to be Liked by you and your readers", comment:"")

        let row = SharingSwitchRow()
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryView = cell.accessoryView
            cell.editingAccessoryType = cell.accessoryType

            if let switchCell = cell as? SwitchTableViewCell {
                switchCell.textLabel?.text = NSLocalizedString("Comment Likes", comment:"")
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

        twitterSection.footerText = NSLocalizedString("This will be included in tweets when people share using the Twitter button.", comment:"")

        let row = SharingSettingRow()
        row.action = { [unowned self] in
            self.handleEditTwitterName()
        }
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryType = .DisclosureIndicator
            cell.textLabel?.text = NSLocalizedString("Twitter Username", comment:"")
            cell.detailTextLabel?.text = self.blog.settings.sharingTwitterName
        }
        twitterSection.rows = [row]
    }


    /// Configures the rows for the button section. When the section is editing, 
    /// all buttons are shown with switch cells. When the section is not editing, 
    /// only enabled and visible buttons are shown and the rows are sortable.
    ///
    func configureButtonRows() {
        var rows = [SharingButtonsRow]()

        let row = SharingSwitchRow()
        row.configureCell = {[unowned self] (cell: UITableViewCell) in
            cell.editingAccessoryView = cell.accessoryView
            cell.editingAccessoryType = cell.accessoryType

            if let switchCell = cell as? SwitchTableViewCell {
                switchCell.textLabel?.text = NSLocalizedString("Edit sharing buttons", comment: "")
                switchCell.on = self.buttonsSection.editing
                switchCell.onChange = { newValue in
                    self.updateButtonOrderAfterEditing()
                    self.buttonsSection.editing = !self.buttonsSection.editing
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
                let row = SortableSharingSwitchRow(buttonID: button.buttonID)
                row.configureCell = {[unowned self] (cell: UITableViewCell) in
                    cell.imageView?.image = self.iconForSharingButton(button)
                    cell.imageView?.tintColor = WPStyleGuide.greyLighten20()

                    cell.editingAccessoryView = nil
                    cell.editingAccessoryType = .None
                    cell.textLabel?.text = button.name
                }
                rows.append(row)
            }

        } else {

            for button in buttons {
                let row = SortableSharingSwitchRow(buttonID: button.buttonID)
                row.configureCell = {[unowned self] (cell: UITableViewCell) in
                    cell.imageView?.image = self.iconForSharingButton(button)
                    cell.imageView?.tintColor = WPStyleGuide.greyLighten20()

                    if let switchCell = cell as? SwitchTableViewCell {
                        cell.editingAccessoryView = cell.accessoryView
                        cell.editingAccessoryType = cell.accessoryType

                        switchCell.textLabel?.text = button.name
                        switchCell.on = button.enabled && button.visible
                        switchCell.onChange = { newValue in
                            button.enabled = newValue
                            if button.enabled {
                                button.visibility = button.enabled ? "visible" : nil
                            }
                            self.refreshMoreSection()
                        }
                    }
                }
                rows.append(row)
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
            cell.editingAccessoryView = cell.accessoryView
            cell.editingAccessoryType = cell.accessoryType

            if let switchCell = cell as? SwitchTableViewCell {
                switchCell.textLabel?.text = NSLocalizedString("Edit \"More\" button", comment: "")
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
                let row = SortableSharingSwitchRow(buttonID: button.buttonID)
                row.configureCell = {[unowned self] (cell: UITableViewCell) in
                    cell.imageView?.image = self.iconForSharingButton(button)
                    cell.imageView?.tintColor = WPStyleGuide.greyLighten20()

                    cell.editingAccessoryView = nil
                    cell.editingAccessoryType = .None
                    cell.textLabel?.text = button.name
                }
                rows.append(row)
            }

        } else {

            for button in buttons {
                let row = SortableSharingSwitchRow(buttonID: button.buttonID)
                row.configureCell = {[unowned self] (cell: UITableViewCell) in
                    cell.imageView?.image = self.iconForSharingButton(button)
                    cell.imageView?.tintColor = WPStyleGuide.greyLighten20()

                    if let switchCell = cell as? SwitchTableViewCell {
                        cell.editingAccessoryView = cell.accessoryView
                        cell.editingAccessoryType = cell.accessoryType
                        switchCell.textLabel?.text = button.name
                        switchCell.on = button.enabled && !button.visible
                        switchCell.onChange = { newValue in
                            button.enabled = newValue
                            if button.enabled {
                                button.visibility = button.enabled ? "hidden" : nil
                            }
                            self.refreshButtonsSection()
                        }
                    }
                }
                rows.append(row)
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

        let indexSet = NSMutableIndexSet(index: 0)
        indexSet.addIndex(sections.count - 1)

        tableView.reloadSections(indexSet, withRowAnimation: .Automatic)
    }


    /// Refreshes the rows for but more section (also the twitter section if
    /// needed) and reloads the section.
    ///
    func refreshMoreSection() {
        configureMoreRows()
        configureTwitterNameSection()

        let indexSet = NSMutableIndexSet(index: 1)
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
            if button.buttonID == "twitter" {
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
        let service = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.updateSettingsForBlog(self.blog, success: nil, failure: { (error: NSError!) in
            DDLogSwift.logError(error.description)
        })

        if refresh {
            tableView.reloadData()
        }
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


    ///
    ///
    func saveButtonChanges(refreshAfterSync: Bool) {
        let context = ContextManager.sharedInstance().mainContext
        ContextManager.sharedInstance().saveContext(context) { [weak self] in
            self?.reloadButtons()
            self?.syncButtonChangesToBlog(refreshAfterSync)
        }
    }


    ///
    ///
    func reloadButtons() {
        let context = ContextManager.sharedInstance().mainContext
        let service = SharingService(managedObjectContext: context)
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
        let context = ContextManager.sharedInstance().mainContext

        let service = SharingService(managedObjectContext: context)
        service.updateSharingButtonsForBlog(blog,
            sharingButtons: buttons,
            success: {[weak self] in
                if refresh {
                    self?.reloadButtons()
                }
            },
            failure: { (error: NSError!) in
                DDLogSwift.logError(error.description)
        })
    }






    // MARK: - Actions


    /// Called when the user taps the label row. Shows a controller to change the
    /// edit label text.
    ///
    func handleEditLabel() {
        let text = blog.settings.sharingLabel
        let placeholder = NSLocalizedString("Type a label", comment: "")
        let hint = NSLocalizedString("Change the text of the sharing button's label. This text won't appear until you add at least one sharing button.", comment: "")
        let controller = SettingsTextViewController(text: text, placeholder: placeholder, hint: hint, isPassword: false)

        controller.title = NSLocalizedString("Label", comment:"")
        controller.onValueChanged = {[unowned self] (value) in
            if value == self.blog.settings.sharingLabel {
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
        let titles = ["Icon & Text", "Icon Only", "Text Only", "Official Buttons"]
        let values = ["icon-text","icon","text","official"]
        let currentValue = blog.settings.sharingButtonStyle

        let dict: [String: AnyObject] = [
            SettingsSelectionDefaultValueKey: values[0],
            SettingsSelectionTitleKey: NSLocalizedString("Button Style", comment: ""),
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
        let placeholder = NSLocalizedString("Username", comment: "")
        let hint = NSLocalizedString("This will be included in tweets when people share using the Twitter button.", comment: "")
        let controller = SettingsTextViewController(text: text, placeholder: placeholder, hint: hint, isPassword: false)

        controller.title = NSLocalizedString("Twitter Username", comment:"")
        controller.onValueChanged = {[unowned self] (value) in
            if value == self.blog.settings.sharingTwitterName {
                return
            }
            self.blog.settings.sharingTwitterName = value
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

        row.configureCell?(cell);

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
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let row = sections[indexPath.section].rows[indexPath.row]
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
        var idx = 0
        for button in buttonsArr {
            let sharingButton = button as! SharingButton
            sharingButton.order = idx
            idx += 1
        }

        self.saveButtonChanges(false)
    }


    // MARK: - Assets


    ///
    ///
    class SharingButtonsSection: NSObject
    {
        var rows: [SharingButtonsRow] = [SharingButtonsRow]()
        var headerText: String?
        var footerText: String?
        var editing = false
        var canSort = false

    }


    typealias SharingButtonsRowAction = () -> Void
    typealias SharingButtonsCellConfig = (UITableViewCell) -> Void

    ///
    ///
    class SharingButtonsRow: NSObject
    {
        var cellIdentifier = ""
        var action: SharingButtonsRowAction?
        var configureCell: SharingButtonsCellConfig?
    }


    ///
    ///
    class SortableSharingSwitchRow: SharingButtonsRow {
        var buttonID: String
        init(buttonID: String) {
            self.buttonID = buttonID
            super.init()
            cellIdentifier = SharingCellIdentifiers.SortableSwitchCellIdentifier
        }
    }


    ///
    ///
    class SharingSwitchRow: SharingButtonsRow {
        override init() {
            super.init()
            cellIdentifier = SharingCellIdentifiers.SwitchCellIdentifier
        }
    }


    ///
    ///
    class SharingSettingRow: SharingButtonsRow {
        override init() {
            super.init()
            cellIdentifier = SharingCellIdentifiers.SettingsCellIdentifier
        }
    }


    struct SharingCellIdentifiers {
        static let SettingsCellIdentifier = "SettingsTableViewCellIdentifier"
        static let SortableSwitchCellIdentifier = "SortableSwitchTableViewCellIdentifier"
        static let SwitchCellIdentifier = "SwitchTableViewCellIdentifier"
    }
}
