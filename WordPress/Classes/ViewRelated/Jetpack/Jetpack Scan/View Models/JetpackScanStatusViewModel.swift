import FormatterKit

struct JetpackScanStatusViewModel {
    let imageName: String
    let title: String
    let description: String

    private(set) var primaryButtonTitle: String?
    private(set) var primaryButtonEnabled: Bool = true
    private(set) var secondaryButtonTitle: String?
    private(set) var warningButtonTitle: HighlightedText?
    private(set) var progress: Float?

    private let coordinator: JetpackScanCoordinator

    private var primaryButtonAction: ButtonAction?
    private var secondaryButtonAction: ButtonAction?
    private var warningButtonAction: ButtonAction?

    init?(coordinator: JetpackScanCoordinator) {
        self.coordinator = coordinator

        guard let scan = coordinator.scan else {
            return nil
        }

        let blog = coordinator.blog
        let state = Self.viewState(for: scan)

        switch state {
        case .noThreats:
            let descriptionTitle: String

            if let mostRecent = scan.mostRecent, let startDate = mostRecent.startDate, let duration = mostRecent.duration {
                // Calculate the end date of the scan which is the start date + the duration
                let lastScanDate = startDate.addingTimeInterval(duration)
                let dateString = Self.relativeTimeString(for: lastScanDate)

                descriptionTitle = String(format: Strings.noThreatsDescriptionFormat, dateString)
            } else {
                descriptionTitle = Strings.noThreatsDescription
            }

            imageName = "jetpack-scan-state-okay"
            title = Strings.noThreatsTitle
            description = descriptionTitle

            secondaryButtonTitle = Strings.scanNowTitle
            secondaryButtonAction = .triggerScan

        case .hasThreats, .hasFixableThreats, .fixingThreats:
            imageName = "jetpack-scan-state-error"

            if state == .fixingThreats {
                title = Strings.fixing.title
                description = Strings.fixing.details
            } else {
                let threatCount = scan.threats?.count ?? 0
                let blogName = blog.title ?? ""

                let descriptionTitle: String
                if threatCount == 1 {
                    descriptionTitle = String(format: Strings.hasSingleThreatDescriptionFormat, blogName)
                } else {
                    descriptionTitle = String(format: Strings.hasThreatsDescriptionFormat, threatCount, blogName)
                }

                title = Strings.hasThreatsTitle
                description = descriptionTitle

                if state == .hasThreats {
                    secondaryButtonTitle = Strings.scanNowTitle
                    secondaryButtonAction = .triggerScan
                } else {
                    primaryButtonTitle = Strings.fixAllTitle
                    primaryButtonAction = .fixAll

                    secondaryButtonTitle = Strings.scanAgainTitle
                    secondaryButtonAction = .triggerScan

                    if !scan.hasValidCredentials {
                        let warningString = String(format: Strings.enterServerCredentialsFormat,
                                                   Strings.enterServerCredentialsSubstring)
                        warningButtonTitle = HighlightedText(substring: Strings.enterServerCredentialsSubstring,
                                                             string: warningString)
                        warningButtonAction = .enterServerCredentials

                        primaryButtonEnabled = false
                    }
                }
            }

        case .preparingToScan:
            imageName = "jetpack-scan-state-progress"
            title = Strings.preparingTitle
            description = Strings.scanningDescription
            progress = 0

        case .scanning:
            imageName = "jetpack-scan-state-progress"
            title = Strings.scanningTitle
            description = Strings.scanningDescription
            progress = Float(scan.current?.progress ?? 0) / 100.0

        case .error:
            imageName = "jetpack-scan-state-error"
            title = Strings.errorTitle
            description = Strings.errorDescription

            primaryButtonTitle = Strings.contactSupportTitle
            primaryButtonAction = .contactSupport

            secondaryButtonTitle = Strings.retryScanTitle
            secondaryButtonAction = .triggerScan
        }
    }

    // MARK: - Button Actions
    private enum ButtonAction {
        case triggerScan
        case fixAll
        case contactSupport
        case enterServerCredentials
    }

    func primaryButtonTapped(_ sender: Any) {
        guard let action = primaryButtonAction else {
            return
        }

        buttonTapped(action: action)
    }

    func secondaryButtonTapped(_ sender: Any) {
        guard let action = secondaryButtonAction else {
            return
        }

        buttonTapped(action: action)
    }

    func warningButtonTapped(_ sender: Any) {
        guard let action = warningButtonAction else {
            return
        }

        buttonTapped(action: action)
    }

    private func buttonTapped(action: ButtonAction) {
        switch action {
        case .fixAll:
            coordinator.presentFixAllAlert()
            WPAnalytics.track(.jetpackScanAllThreatsOpen)

        case .triggerScan:
            coordinator.startScan()
            WPAnalytics.track(.jetpackScanRunTapped)

        case .contactSupport:
            coordinator.openSupport()

        case .enterServerCredentials:
            coordinator.openJetpackSettings()
        }
    }

    // MARK: - View State

    /// The potential states the view can be in based on the scan state
    private enum StatusViewState {
        case noThreats
        case hasThreats
        case hasFixableThreats
        case preparingToScan
        case scanning
        case fixingThreats
        case error
    }

    private static func viewState(for scan: JetpackScan) -> StatusViewState {
        let viewState: StatusViewState

        switch scan.state {
        case .idle:
            if let threats = scan.threats, threats.count > 0 {
                viewState = scan.hasFixableThreats ? .hasFixableThreats : .hasThreats
            } else {
                if scan.mostRecent?.didFail ?? false {
                    return .error
                }

                viewState = .noThreats
            }
        case .fixingThreats:
            viewState = .fixingThreats

        case .provisioning:
            viewState = .preparingToScan

        case .scanning:
            let isPreparing = (scan.current?.progress ?? 0) == 0

            viewState = isPreparing ? .preparingToScan : .scanning

        case .unavailable:
            viewState = .error

        default:
            viewState = .noThreats
        }

        return viewState
    }

    /// Converts a date into a relative time (X seconds ago, X hours ago, etc)
    private static func relativeTimeString(for date: Date) -> String {
        let dateString: String

        // Temporary check until iOS 13 is the deployment target
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full

        dateString = formatter.localizedString(for: date, relativeTo: Date())
        return dateString
    }

    // MARK: - Localized Strings
    private struct Strings {
        static let enterServerCredentialsSubstring = NSLocalizedString("Enter your server credentials", comment: "Error message displayed when site credentials aren't configured.")
        static let enterServerCredentialsFormat = NSLocalizedString("%1$@ to fix threats.", comment: "Title for button when a site is missing server credentials. %1$@ is a placeholder for the string 'Enter your server credentials'.")
        static let noThreatsTitle = NSLocalizedString("Don’t worry about a thing", comment: "Title for label when there are no threats on the users site")
        static let noThreatsDescriptionFormat = NSLocalizedString("The last Jetpack scan ran %1$@ and did not find any risks.\n\nTo review your site again run a manual scan, or wait for Jetpack to scan your site later today.", comment: "Description for label when there are no threats on a users site and how long ago the scan ran.")
        static let noThreatsDescription = NSLocalizedString("The last jetpack scan did not find any risks.\n\nTo review your site again run a manual scan, or wait for Jetpack to scan your site later today.",
                                                            comment: "Description that informs for label when there are no threats on a users site")

        static let hasThreatsTitle = NSLocalizedString("Your site may be at risk", comment: "Title for label when there are threats on the users site")
        static let hasThreatsDescriptionFormat = NSLocalizedString("Jetpack Scan found %1$d potential threats with %2$@. Please review them below and take action or tap the fix all button. We are here to help if you need us.", comment: "Description for a label when there are threats on the site, displays the number of threats, and the site's title")
        static let hasSingleThreatDescriptionFormat = NSLocalizedString("Jetpack Scan found 1 potential threat with %1$@. Please review them below and take action or tap the fix all button. We are here to help if you need us.", comment: "Description for a label when there is a single threat on the site, displays the site's title")

        static let preparingTitle = NSLocalizedString("Preparing to scan", comment: "Title for label when the preparing to scan the users site")
        static let scanningTitle = NSLocalizedString("Scanning files", comment: "Title for label when the actively scanning the users site")
        static let scanningDescription = NSLocalizedString("We will send you an email if security threats are found. In the meantime feel free to continue to use your site as normal, you can check back on progress at any time.", comment: "Description for label when the actively scanning the users site")

        static let errorTitle = NSLocalizedString("Something went wrong", comment: "Title for a label that appears when the scan failed")
        static let errorDescription = NSLocalizedString("Jetpack Scan couldn't complete a scan of your site. Please check to see if your site is down – if it's not, try again. If it is, or if Jetpack Scan is still having problems, contact our support team.", comment: "Description for a label when the scan has failed")

        struct fixing {
            static let title = NSLocalizedString("Fixing Threats", comment: "Subtitle displayed while the server is fixing threats")
            static let details = NSLocalizedString("We're hard at work fixing these threats in the background. In the meantime feel free to continue to use your site as normal, you can check back on progress at any time.", comment: "Detail text display informing the user that we're fixing threats")
        }

        // Buttons
        static let contactSupportTitle = NSLocalizedString("Contact Support", comment: "Button title that opens the support page")
        static let retryScanTitle = NSLocalizedString("Retry Scan", comment: "Button title that triggers a scan")
        static let scanNowTitle = NSLocalizedString("Scan Now", comment: "Button title that triggers a scan")
        static let scanAgainTitle = NSLocalizedString("Scan Again", comment: "Button title that triggers a scan")
        static let fixAllTitle = NSLocalizedString("Fix All", comment: "Button title that attempts to fix all fixable threats")
    }
}
