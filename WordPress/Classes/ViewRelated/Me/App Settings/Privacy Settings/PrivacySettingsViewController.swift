import Gridicons
import UIKit
import AutomatticTracks

class PrivacySettingsViewController: UITableViewController {
    fileprivate var handler: ImmuTableViewHandler!

    // MARK: - Dependencies

    private let analyticsTracker: PrivacySettingsAnalyticsTracking

    // MARK: - Init

    init(style: UITableView.Style, analyticsTracker: PrivacySettingsAnalyticsTracking) {
        self.analyticsTracker = analyticsTracker
        super.init(style: style)
        navigationItem.title = NSLocalizedString("Privacy Settings", comment: "Privacy Settings Title")
    }

    override convenience init(style: UITableView.Style) {
        self.init(style: style, analyticsTracker: PrivacySettingsAnalyticsTracker())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init() {
        self.init(style: .insetGrouped)
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        ImmuTable.registerRows([
            PaddedInfoRow.self,
            SwitchRow.self,
            PaddedLinkRow.self
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        reloadViewModel()

        WPStyleGuide.configureColors(view: view, tableView: tableView)
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
            icon: .gridicon(.stats),
            onChange: usageTrackingChanged
        )

        let shareInfoText = PaddedInfoRow(
            title: NSLocalizedString("Share information with our analytics tool about your use of services while logged in to your WordPress.com account.", comment: "Informational text for Collect Information setting")
        )

        let shareInfoLink = PaddedLinkRow(
            title: NSLocalizedString("Learn more", comment: "Link to cookie policy"),
            action: openCookiePolicy()
        )

        let privacyText = PaddedInfoRow(
            title: NSLocalizedString("This information helps us improve our products, make marketing to you more relevant, personalize your WordPress.com experience, and more as detailed in our privacy policy.", comment: "Informational text for the privacy policy link")
        )

        let privacyLink = PaddedLinkRow(
            title: NSLocalizedString("Read privacy policy", comment: "Link to privacy policy"),
            action: openPrivacyPolicy()
        )

        let ccpaLink = PaddedLinkRow(
            title: NSLocalizedString("Privacy notice for California users", comment: "Link to the CCPA privacy notice for residents of California."),
            action: openCCPANotice()
        )

        let otherTracking = PaddedInfoRow(
            title: NSLocalizedString("We use other tracking tools, including some from third parties. Read about these and how to control them.", comment: "Informational text about link to other tracking tools")
        )

        let otherTrackingLink = PaddedLinkRow(
            title: NSLocalizedString("Learn more", comment: "Link to cookie policy"),
            action: openCookiePolicy()
        )

        let reportCrashes = SwitchRow(
            title: NSLocalizedString("Crash reports", comment: "Label for switch to turn on/off sending crashes info"),
            value: !UserSettings.userHasOptedOutOfCrashLogging,
            icon: .gridicon(.bug),
            onChange: crashReportingChanged
        )

        let reportCrashesInfoText = PaddedInfoRow(
            title: NSLocalizedString("To help us improve the app’s performance and fix the occasional bug, enable automatic crash reports.", comment: "Informational text for Report Crashes setting")
        )

        return ImmuTable(sections: [
            ImmuTableSection(rows: [
                collectInformation,
                shareInfoText,
                shareInfoLink,
                privacyText,
                privacyLink,
                ccpaLink,
                otherTracking,
                otherTrackingLink
                ]),
            ImmuTableSection(rows: [
                reportCrashes,
                reportCrashesInfoText
            ])
        ])
    }

    /// A method that reacts to changes in the user's analytics tracking preference.
    ///
    /// This method is invoked when a user enables or disables analytics tracking in their privacy settings. Its purpose is to update the user's preference locally and remotely, and to track the event if possible.
    ///
    /// - If the user is enabling tracking, this method first turns tracking on, then sends an event to the analytics tracker. This ensures that the event of enabling tracking is tracked.
    /// - If the user is disabling tracking, the event is sent to the analytics tracker before tracking is turned off. This ensures that the event of disabling tracking is tracked before tracking is fully turned off.
    ///
    /// - Parameters:
    ///     - enabled: A boolean that indicates the user's preference. If `true`, analytics tracking is enabled. If `false`, analytics tracking is disabled.
    ///
    private func usageTrackingChanged(_ enabled: Bool) {
        analyticsTracker.trackPrivacySettingsAnalyticsTrackingToggled(enabled: enabled)
        updateUserHasOptedOut(enabled)
        analyticsTracker.trackPrivacySettingsAnalyticsTrackingToggled(enabled: enabled)
        persistTrackingUpdateRemotely(enabled)
    }

    private func updateUserHasOptedOut(_ enabled: Bool) {
        let appAnalytics = WordPressAppDelegate.shared?.analytics
        appAnalytics?.setUserHasOptedOut(!enabled)
    }

    private func persistTrackingUpdateRemotely(_ enabled: Bool) {
        let result = ContextManager.shared.performQuery { context -> (NSNumber, WordPressComRestApi)? in
            guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context),
                  let wordPressComRestApi = account.wordPressComRestApi
            else {
                return nil
            }
            return (account.userID, wordPressComRestApi)
        }

        if let (accountID, wordPressComRestApi) = result {
            let change = AccountSettingsChange.tracksOptOut(!enabled)
            AccountSettingsService(userID: accountID.intValue, api: wordPressComRestApi).saveChange(change)
        }
    }

    func openCookiePolicy() -> ImmuTableAction {
        return { [weak self] _ in
            self?.tableView.deselectSelectedRowWithAnimation(true)
            self?.displayWebView(WPAutomatticCookiesURL)
        }
    }

    func openPrivacyPolicy() -> ImmuTableAction {
        return { [weak self] _ in
            self?.tableView.deselectSelectedRowWithAnimation(true)
            self?.displayWebView(WPAutomatticPrivacyURL)
        }
    }

    func openCCPANotice() -> ImmuTableAction {
        return { [weak self] _ in
            self?.tableView.deselectSelectedRowWithAnimation(true)
            self?.displayWebView(WPAutomatticCCPAPrivacyNoticeURL)
        }
    }

    func displayWebView(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        let webViewController = WebViewControllerFactory.controller(url: url, source: "privacy_settings")
        let navigation = UINavigationController(rootViewController: webViewController)
        present(navigation, animated: true)
    }

    func crashReportingChanged(_ enabled: Bool) {
        UserSettings.userHasOptedOutOfCrashLogging = !enabled

        analyticsTracker.trackPrivacySettingsReportCrashesToggled(enabled: enabled)

        WordPressAppDelegate.crashLogging?.setNeedsDataRefresh()
    }
}

private class InfoCell: WPTableViewCellDefault {
    override func layoutSubviews() {
        super.layoutSubviews()
        guard var imageFrame = imageView?.frame,
            let textLabel = textLabel,
            let textLabelFont = textLabel.font,
            let text = textLabel.text else {
                return
        }

        // Determine the smallest size of text constrained to the width of the label
        let size = CGSize(width: textLabel.bounds.width, height: .greatestFiniteMagnitude)

        // First a single line of text, so we can center against the first line of text
        let singleLineRect = "Text".boundingRect(with: size,
                                                 options: [ .usesLineFragmentOrigin, .usesFontLeading],
                                                 attributes: [NSAttributedString.Key.font: textLabelFont],
                                                 context: nil)

        // And then the whole text, so we can calculate padding in the label above and below the text
        let textRect = text.boundingRect(with: size,
                                         options: [ .usesLineFragmentOrigin, .usesFontLeading],
                                         attributes: [NSAttributedString.Key.font: textLabelFont],
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

private struct PaddedInfoRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(InfoCell.self)

    let title: String
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.textLabel?.numberOfLines = 10
        cell.imageView?.image = UIImage(color: .clear, size: Gridicon.defaultSize)
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
        cell.imageView?.image = UIImage(color: .clear, size: Gridicon.defaultSize)

        WPStyleGuide.configureTableViewActionCell(cell)
        cell.textLabel?.textColor = AppColor.primary
    }
}
