import Gridicons
import UIKit

class PrivacySettingsViewController: UITableViewController {
    fileprivate var handler: ImmuTableViewHandler!

    override init(style: UITableViewStyle) {
        super.init(style: style)
        navigationItem.title = NSLocalizedString("Privacy Settings", comment: "Privacy Settings Title")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init() {
        self.init(style: .grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ImmuTable.registerRows([
            InfoRow.self,
            SwitchRow.self,
            PaddedLinkRow.self
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        reloadViewModel()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)

        addAccountSettingsChangedObserver()
    }

    private func addAccountSettingsChangedObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(accountSettingsDidChange(_:)), name: NSNotification.Name.AccountSettingsChanged, object: nil)
    }

    @objc
    private func accountSettingsDidChange(_ notification: Notification) {
        reloadViewModel()
    }

    // MARK: - Model mapping

    fileprivate func reloadViewModel() {
        handler.viewModel = tableViewModel()
    }

    func tableViewModel() -> ImmuTable {
        let collectInformation = SwitchRow(
            title: NSLocalizedString("Collect information", comment: "Label for switch to turn on/off sending app usage data"),
            value: !WPAppAnalytics.userHasOptedOut(),
            icon: Gridicon.iconOfType(.stats),
            onChange: usageTrackingChanged()
        )

        let shareInfoText = InfoRow(
            title: NSLocalizedString("Share information with our analytics tool about your use of services while logged in to your WordPress.com account.", comment: "Informational text for Collect Information setting"),
            icon: Gridicon.iconOfType(.info)
        )

        let shareInfoLink = PaddedLinkRow(
            title: NSLocalizedString("Learn more", comment: "Link to cookie policy"),
            action: openCookiePolicy()
        )

        let privacyText = InfoRow(
            title: NSLocalizedString("This information helps us improve our products, make marketing to you more relevant, personalize your WordPress.com experience, and more as detailed in our privacy policy.", comment: "Informational text for the privacy policy link"),
            icon: Gridicon.iconOfType(.userCircle)
        )

        let privacyLink = PaddedLinkRow(
            title: NSLocalizedString("Read privacy policy", comment: "Link to privacy policy"),
            action: openPrivacyPolicy()
        )

        let otherTracking = InfoRow(
            title: NSLocalizedString("We use other tracking tools, including some from third parties. Read about these and how to control them.", comment: "Informational text about link to other tracking tools"),
            icon: Gridicon.iconOfType(.briefcase)
        )

        let otherTrackingLink = PaddedLinkRow(
            title: NSLocalizedString("Learn more", comment: "Link to cookie policy"),
            action: openCookiePolicy()
        )

        return ImmuTable(sections: [
            ImmuTableSection(rows: [
                collectInformation,
                shareInfoText,
                shareInfoLink
                ]),
            ImmuTableSection(rows: [
                privacyText,
                privacyLink
                ]),
            ImmuTableSection(rows: [
                otherTracking,
                otherTrackingLink
                ])
            ])
    }

    func usageTrackingChanged() -> (Bool) -> Void {
        return { enabled in
            let appAnalytics = WordPressAppDelegate.sharedInstance().analytics
            appAnalytics?.setUserHasOptedOut(!enabled)

            let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            AccountSettingsHelper(accountService: accountService).updateTracksOptOutSetting(!enabled)

            let crashalytics = WordPressAppDelegate.sharedInstance().crashlytics
            crashalytics?.setUserHasOptedOut(!enabled)
        }
    }

    func openCookiePolicy() -> ImmuTableAction {
        return { [weak self] _ in
            self?.displayWebView(WPAutomatticCookiesURL)
        }
    }

    func openPrivacyPolicy() -> ImmuTableAction {
        return { [weak self] _ in
            self?.displayWebView(WPAutomatticPrivacyURL)
        }
    }

    func displayWebView(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        let webViewController = WebViewControllerFactory.controller(url: url)
        let navigation = UINavigationController(rootViewController: webViewController)
        present(navigation, animated: true, completion: nil)
    }

}

private class InfoCell: WPTableViewCellDefault {
    override func layoutSubviews() {
        super.layoutSubviews()
        guard var imageFrame = imageView?.frame,
            let textLabel = textLabel,
            let text = textLabel.text else {
                return
        }

        // Determine the smallest size of text constrained to the width of the label
        let size = CGSize(width: textLabel.bounds.width, height: .greatestFiniteMagnitude)

        // First a single line of text, so we can center against the first line of text
        let singleLineRect = "Text".boundingRect(with: size,
                                                 options: [ .usesLineFragmentOrigin, .usesFontLeading],
                                                 attributes: [NSAttributedStringKey.font: textLabel.font],
                                                 context: nil)

        // And then the whole text, so we can calculate padding in the label above and below the text
        let textRect = text.boundingRect(with: size,
                                         options: [ .usesLineFragmentOrigin, .usesFontLeading],
                                         attributes: [NSAttributedStringKey.font: textLabel.font],
                                         context: nil)

        // Calculate the vertical padding in the label.
        // At very large accessibility sizing, the total rect size is coming out larger
        // than the label size. I'm unsure why, so we'll work around it by not allowing
        // values lower than zero.
        let padding = max(textLabel.bounds.height - textRect.height, 0)
        let topPadding = padding / 2.0

        // Calculate the center point of the first line of text, and center the image against it
        let imageCenterX = imageFrame.size.height / 2.0
        imageFrame.origin.y = floor(topPadding + singleLineRect.midY - imageCenterX)
        imageView?.frame = imageFrame
    }
}

private struct InfoRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(InfoCell.self)

    let title: String
    let icon: UIImage
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.textLabel?.numberOfLines = 10
        cell.imageView?.image = icon
        cell.selectionStyle = .none

        WPStyleGuide.configureTableViewCell(cell)
    }
}

private struct PaddedLinkRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellDefault.self)

    let title: String
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.imageView?.image = UIImage(color: .clear, havingSize: Gridicon.defaultSize)

        WPStyleGuide.configureTableViewActionCell(cell)
    }
}
