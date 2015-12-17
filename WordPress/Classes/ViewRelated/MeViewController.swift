import UIKit
import WordPressShared

class NewMeViewController: UITableViewController {
    var handler: ImmuTableViewHandler!

    // MARK: - Table View Controller

    required convenience init() {
        self.init(style: .Grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("My Profile", comment: "My Profile view title")

        ImmuTable.registerRows([
            NavigationItemRow.self
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        handler.viewModel = buildViewModel()

        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    func buildViewModel() -> ImmuTable {
        let myProfile = NavigationItemRow(
            title: NSLocalizedString("My Profile", comment: "Link to My Profile section"),
//            icon: UIImage(named: "icon-menu-people")!,
            action: pushMyProfile())

        let accountSettings = NavigationItemRow(
            title: NSLocalizedString("Account Settings", comment: "Link to Account Settings section"),
            action: pushAccountSettings())

        let notificationSettings = NavigationItemRow(
            title: NSLocalizedString("Notification Settings", comment: "Link to Notification Settings section"),
            action: pushNotificationSettings())

        let helpAndSupport = NavigationItemRow(
            title: NSLocalizedString("Help & Support", comment: "Link to Help section"),
            action: pushHelp())

        let about = NavigationItemRow(
            title: NSLocalizedString("About", comment: "Link to About section (contains info about the app)"),
            action: pushAbout())

        return ImmuTable(
            sections: [
                ImmuTableSection(rows: [
                    myProfile,
                    accountSettings,
                    notificationSettings
                    ]),
                ImmuTableSection(rows: [
                    helpAndSupport,
                    about
                    ])
            ])
    }

    // MARK: - Actions

    func pushMyProfile() -> ImmuTableActionType {
        return { [unowned self] row in
            WPAppAnalytics.track(.OpenedMyProfile)
            let controller = MyProfileViewController()
            controller.account = self.defaultAccount()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func pushAccountSettings() -> ImmuTableActionType {
        return { [unowned self] row in
            WPAppAnalytics.track(.OpenedAccountSettings)
            let controller = SettingsViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func pushNotificationSettings() -> ImmuTableActionType {
        return { [unowned self] row in
            let controller = NotificationSettingsViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func pushHelp() -> ImmuTableActionType {
        return { [unowned self] row in
            let controller = SupportViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func pushAbout() -> ImmuTableActionType {
        return { [unowned self] row in
            let controller = AboutViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    // MARK: - Helpers
    // FIXME: Not cool. Let's stop passing managed objects and initializing stuff
    // with safer values like userID
    func defaultAccount() -> WPAccount {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        let account = service.defaultWordPressComAccount()
        // Again, ! isn't cool, but let's keep it for now until we refactor the VC
        // initialization parameters.
        return account!
    }
}
