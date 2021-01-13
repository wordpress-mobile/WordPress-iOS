import FormatterKit

struct JetpackScanStatusViewModel {
    let imageName: String
    let title: String
    let description: String
    let primaryButtonTitle: String?
    let secondaryButtonTitle: String?

    init(scan: JetpackScan, blog: Blog) {
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
            primaryButtonTitle = nil

        case .hasThreats, .hasFixableThreats:
            let threatCount = scan.threats?.count ?? 0
            let blogName = blog.title ?? ""

            let descriptionTitle: String
            if threatCount == 1 {
                descriptionTitle = String(format: Strings.hasSingleThreatDescriptionFormat, blogName)
            } else {
                descriptionTitle = String(format: Strings.hasThreatsDescriptionFormat, threatCount, blogName)
            }

            imageName = "jetpack-scan-state-error"
            title = Strings.hasThreatsTitle
            description = descriptionTitle

            if state == .hasThreats {
                secondaryButtonTitle = Strings.scanNowTitle
                primaryButtonTitle = nil
            } else {
                primaryButtonTitle = Strings.fixAllTitle
                secondaryButtonTitle = Strings.scanAgainTitle
            }

        case .preparingToScan:
            imageName = "jetpack-scan-state-progress"
            title = Strings.preparingTitle
            description = Strings.scanningDescription
            primaryButtonTitle = nil
            secondaryButtonTitle = nil

        case .scanning:
            imageName = "jetpack-scan-state-progress"
            title = Strings.scanningTitle
            description = Strings.scanningDescription
            primaryButtonTitle = nil
            secondaryButtonTitle = nil

        case .error:
            imageName = "jetpack-scan-state-error"
            title = Strings.errorTitle
            description = Strings.errorDescription
            primaryButtonTitle = Strings.contactSupportTitle
            secondaryButtonTitle = Strings.retryScanTitle
        }
    }

    /// The potential states the view can be in based on the scan state
    private enum StatusViewState {
        case noThreats
        case hasThreats
        case hasFixableThreats
        case preparingToScan
        case scanning
        case error
    }

    private static func viewState(for scan: JetpackScan) -> StatusViewState {
        let viewState: StatusViewState

//        // If the most recent or current scan has failed, display an error state
//        TODO: Disabled for now until I implement the error state
//        if scan.current?.didFail ?? false || scan.mostRecent?.didFail ?? false {
//            return .error
//        }

        switch scan.state {
        case .idle:
            if let threats = scan.threats, threats.count > 0 {
                let fixableThreats = threats.filter { $0.fixable != nil }.count > 0
                viewState = fixableThreats ? .hasFixableThreats : .hasThreats
            } else {
                if scan.mostRecent?.didFail == true {

                }
                viewState = .noThreats
            }

        case .provisioning:
            viewState = .preparingToScan

        case .scanning:
            let isPreparing = (scan.current?.progress ?? 0) == 0

            viewState = isPreparing ? .preparingToScan : .scanning
        default:
            viewState = .noThreats
        }

        return viewState
    }

    /// Converts a date into a relative time (X seconds ago, X hours ago, etc)
    private static func relativeTimeString(for date: Date) -> String {
        let dateString: String

        // Temporary check until iOS 13 is the deployment target
        if #available(iOS 13.0, *) {
            let formatter = RelativeDateTimeFormatter()
            formatter.dateTimeStyle = .named
            formatter.unitsStyle = .full

            dateString = formatter.localizedString(for: date, relativeTo: Date())
        } else {
            let relativeFormatter = TTTTimeIntervalFormatter()
            dateString = relativeFormatter.string(forTimeInterval: date.timeIntervalSinceNow)
        }

        return dateString
    }

    private struct Strings {
        static let noThreatsTitle = NSLocalizedString("Don’t worry about a thing", comment: "Title for label when there are no threats on the users site")
        static let noThreatsDescriptionFormat = NSLocalizedString("The last Jetpack scan ran %1$@ and everything looked great.\n\nRun a manual scan now or wait for Jetpack to scan your site later today.", comment: "Description for label when there are no threats on a users site and how long ago the scan ran")
        static let noThreatsDescription = NSLocalizedString("The last Jetpack scan completed and everything looked great.\n\nRun a manual scan now or wait for Jetpack to scan your site later today.", comment: "Description that informs for label when there are no threats on a users site")

        static let hasThreatsTitle = NSLocalizedString("Your site may be at risk", comment: "Title for label when there are threats on the users site")
        static let hasThreatsDescriptionFormat = NSLocalizedString("Jetpack Scan found %1$d potential threats on %2$@. Please review each threat and take action.", comment: "Description for a label when there are threats on the site, displays the number of threats, and the site's title")
        static let hasSingleThreatDescriptionFormat = NSLocalizedString("Jetpack Scan found 1 potential threat on %1$@. Please review each threat and take action.", comment: "Description for a label when there is a single threat on the site, displays the site's title")

        static let preparingTitle = NSLocalizedString("Preparing to scan", comment: "Title for label when the preparing to scan the users site")
        static let scanningTitle = NSLocalizedString("Scanning files", comment: "Title for label when the actively scanning the users site")
        static let scanningDescription = NSLocalizedString("We will send you an email if security threats are found. In the meantime feel free to continue to use your site as normal, you can check back on progress at any time.", comment: "Description for label when the actively scanning the users site")

        static let errorTitle = NSLocalizedString("Something went wrong", comment: "Title for a label that appears when the scan failed")
        static let errorDescription = NSLocalizedString("Jetpack Scan couldn't complete a scan of your site. Please check to see if your site is down – if it's not, try again. If it is, or if Jetpack Scan is still having problems, contact our support team.", comment: "Description for a label when the scan has failed")

        // Buttons
        static let contactSupportTitle = NSLocalizedString("Contact Support", comment: "Button title that opens the support page")
        static let retryScanTitle = NSLocalizedString("Retry Scan", comment: "Button title that triggers a scan")
        static let scanNowTitle = NSLocalizedString("Scan Now", comment: "Button title that triggers a scan")
        static let scanAgainTitle = NSLocalizedString("Scan Again", comment: "Button title that triggers a scan")
        static let fixAllTitle = NSLocalizedString("Fix All", comment: "Button title that attempts to fix all fixable threats")
    }
}
