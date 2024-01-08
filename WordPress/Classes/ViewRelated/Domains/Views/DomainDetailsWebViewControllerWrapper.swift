import SwiftUI
import UIKit
import WordPressKit

/// Makes DomainDetailsWebViewController available to SwiftUI
struct DomainDetailsWebViewControllerWrapper: UIViewControllerRepresentable {
    private let domain: String
    private let siteSlug: String
    private let type: DomainType
    private let analyticsSource: String?

    init(domain: String, siteSlug: String, type: DomainType, analyticsSource: String? = nil) {
        self.domain = domain
        self.siteSlug = siteSlug
        self.type = type
        self.analyticsSource = analyticsSource
    }

    func makeUIViewController(context: Context) -> DomainDetailsWebViewController {
        DomainDetailsWebViewController(
            domain: domain,
            siteSlug: siteSlug,
            type: type,
            analyticsSource: analyticsSource
        )
    }

    func updateUIViewController(_ uiViewController: DomainDetailsWebViewController, context: Context) { }
}
