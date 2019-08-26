import UIKit
import WordPressKit


/// The purpose of this class is to render a collection of notifications sunscriptions for a Site Topic,
/// and to provide the user a simple interface to update those settings, as needed.
///
class NotificationSiteSubscriptionViewController: UITableViewController {
    private class Section {
        enum SectionType {
            case posts
            case emails
            case comments
        }

        var type: SectionType
        var rows: [Row]
        var footerText: String?

        init(type: SectionType, rows: [Row], footerText: String? = nil) {
            self.type = type
            self.rows = rows
            self.footerText = footerText
        }
    }

    private class Row {
        enum Kind: String {
            case setting = "SwitchCellIdentifier"
            case checkmark = "CheckmarkCellIdentifier"
        }

        let title: String
        let kind: Kind
        let frequency: ReaderServiceDeliveryFrequency?


        init(kind: Kind = .setting, title: String, frequency: ReaderServiceDeliveryFrequency? = nil) {
            self.title = title
            self.kind = kind
            self.frequency = frequency
        }
    }

    private class SiteSubscription {
        var postsNotification: Bool = false
        var emailsNotification: Bool = false {
            didSet {
                if emailsNotification {
                    frequency = .instantly
                }
            }
        }
        var commentsNotification: Bool = false
        var frequency: ReaderServiceDeliveryFrequency?

        func boolValue(for sectionType: Section.SectionType) -> Bool {
            switch sectionType {
            case .posts: return postsNotification
            case .emails: return emailsNotification
            case .comments: return commentsNotification
            }
        }
    }

    private var sections: [Section] = []
    private let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
    private let siteId: Int
    private var siteTopic: ReaderSiteTopic?
    private let siteSubscription = SiteSubscription()


    required init(siteId: Int) {
        self.siteId = siteId
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupData()
        setupTitle()
        setupTableView()

        startListeningToNotifications()
    }


    // MARK: - Private methods

    private func setupData() {
        siteTopic = service.findSiteTopic(withSiteID: NSNumber(value: siteId))

        siteSubscription.postsNotification = siteTopic?.postSubscription?.sendPosts ?? false
        siteSubscription.emailsNotification = siteTopic?.emailSubscription?.sendPosts ?? false
        siteSubscription.commentsNotification = siteTopic?.emailSubscription?.sendComments ?? false
        if let postDeliveryFrequency = siteTopic?.emailSubscription?.postDeliveryFrequency,
            let frequency = ReaderServiceDeliveryFrequency(rawValue: postDeliveryFrequency) {
            siteSubscription.frequency = frequency
        }

        let instantly = ReaderServiceDeliveryFrequency.instantly
        let daily = ReaderServiceDeliveryFrequency.daily
        let weekly = ReaderServiceDeliveryFrequency.weekly

        let newPostsString = NSLocalizedString("New posts", comment: "Noun. The title of an item in a list.")
        let emailPostsString = NSLocalizedString("Email me new posts", comment: "The title of an item in a list.")
        let emailCommentsString = NSLocalizedString("Email me new comments", comment: "Noun. The title of an item in a list.")
        let footerString = NSLocalizedString("Receive notifications for new posts from this site", comment: "Descriptive text below a list of options.")

        let post = Section(type: .posts,
                           rows: [Row(title: newPostsString)],
                           footerText: footerString)
        let email = Section(type: .emails, rows: [Row(title: emailPostsString),
                                                  Row(kind: .checkmark, title: instantly.rawValue.capitalized, frequency: instantly),
                                                  Row(kind: .checkmark, title: daily.rawValue.capitalized, frequency: daily),
                                                  Row(kind: .checkmark, title: weekly.rawValue.capitalized, frequency: weekly)])
        let comments = Section(type: .comments, rows: [Row(title: emailCommentsString)])

        sections = [post, email, comments]
    }

    private func setupTitle() {
        title = siteTopic?.title
    }

    private func setupTableView() {
        // Register the cells
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: Row.Kind.setting.rawValue)
        tableView.register(CheckmarkTableViewCell.self, forCellReuseIdentifier: Row.Kind.checkmark.rawValue)

        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()

        // Style!
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    private func switchCell(for section: Section, row: Row, at index: IndexPath) -> SwitchTableViewCell {
        let cell: SwitchTableViewCell = self.cell(for: tableView, at: index, identifier: row.kind.rawValue)
        cell.name = row.title
        cell.on = siteSubscription.boolValue(for: section.type)
        cell.onChange = { [weak self] (newValue: Bool) in
            switch section.type {
            case .posts:
                self?.siteSubscription.postsNotification = newValue
                self?.service.toggleSubscribingNotifications(for: self?.siteId, subscribe: newValue, {
                    let event: WPAnalyticsStat = newValue ? .notificationsSettingsBlogNotificationsOn : .notificationsSettingsBlogNotificationsOff
                    WPAnalytics.track(event)
                })

            case .emails:
                self?.siteSubscription.emailsNotification = newValue
                self?.reloadData(at: index.section, animation: .fade)
                self?.service.toggleSubscribingEmail(for: self?.siteId, subscribe: newValue)

            case .comments:
                self?.siteSubscription.commentsNotification = newValue
                self?.service.toggleSubscribingComments(for: self?.siteId, subscribe: newValue)
            }
        }
        return cell
    }

    private func checkmarkCell(for section: Section, row: Row, at index: IndexPath) -> CheckmarkTableViewCell {
        let cell: CheckmarkTableViewCell = self.cell(for: tableView, at: index, identifier: row.kind.rawValue)
        cell.title = row.title
        cell.on = siteSubscription.frequency == row.frequency
        return cell
    }

    private func reloadData(at section: Int, animation: UITableView.RowAnimation = .none) {
        let sections = IndexSet(integer: section)
        tableView.reloadSections(sections, with: animation)
    }

    private func cell<T: UITableViewCell>(for tableView: UITableView, at indexPath: IndexPath, identifier: String) -> T {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? T else {
            fatalError("A cell must be found for identifier: \(identifier)")
        }

        return cell
    }

    private func startListeningToNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(followingSiteStateToggled), name: NSNotification.Name(rawValue: ReaderPostServiceToggleSiteFollowingState), object: nil)
    }

    @objc func followingSiteStateToggled() {
        if let siteTopic = service.findSiteTopic(withSiteID: NSNumber(value: siteId)), !siteTopic.following {
            navigationController?.popToRootViewController(animated: true)
        }
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        switch section.type {
        case .emails: return siteSubscription.emailsNotification ? section.rows.count : 1
        default: return section.rows.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let row = section.rows[indexPath.row]

        switch row.kind {
        case .checkmark: return checkmarkCell(for: section, row: row, at: indexPath)
        case .setting: return switchCell(for: section, row: row, at: indexPath)
        }
    }


    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footerText
    }

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)

        let section = sections[indexPath.section]
        let row = section.rows[indexPath.row]

        guard let frequency = row.frequency else {
            return
        }

        if row.kind == .checkmark {
            siteSubscription.frequency = row.frequency
            reloadData(at: indexPath.section)
            service.updateFrequencyPostsEmail(with: siteId, frequency: frequency)
        }
    }
}
