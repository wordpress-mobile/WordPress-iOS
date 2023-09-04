import Foundation

final class DashboardGoogleDomainsViewModel {
    private enum Constants {
        static let transferDomainsURL = "https://wordpress.com/transfer-google-domains/"
    }

    private let tracker: EventTracker
    weak var cell: DashboardGoogleDomainsCardCellProtocol?

    init(tracker: EventTracker = DefaultEventTracker()) {
        self.tracker = tracker
    }

    func didShowCard() {
        tracker.track(.domainTransferShown)
    }

    func didTapTransferDomains() {
        guard let url = URL(string: Constants.transferDomainsURL) else {
            return
        }

        cell?.presentGoogleDomainsWebView(with: url)
        tracker.track(.domainTransferButtonTapped)
    }

    func didTapMore() {
        tracker.track(.domainTransferMoreTapped)
    }
}
