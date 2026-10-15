import Foundation
import WordPressData
import WordPressKit

// MARK: - SiteCreator

// Tracks data state shared between Site Creation Wizard Steps. I am not too fond of the name, but it kind of works for now.
final class SiteCreator {

    // MARK: Properties
    let flow: SiteCreationFlow
    var design: RemoteSiteDesign?
    var vertical: SiteIntentVertical?
    var information: SiteInformation?
    var address: DomainSuggestion?
    var planId: Int?
    /// Users can opt for a free domain name in Plans selection
    var addressFromPlanSelection: String?

    init(flow: SiteCreationFlow = .current) {
        self.flow = flow
    }

    /// Generates the final object that will be posted to the backend
    ///
    /// - Returns: an Encodable object
    ///
    func build() -> SiteCreationRequest {
        let isBlank = flow == .short
        return SiteCreationRequest(
            segmentIdentifier: nil,
            siteDesign: isBlank ? nil : (design?.slug ?? Strings.defaultDesignSlug),
            verticalIdentifier: isBlank ? nil : vertical?.slug,
            title: information?.title ?? "",
            tagline: information?.tagLine ?? "",
            siteURLString: siteURLString,
            isPublic: true,
            siteCreationFlow: requestFlowName,
            findAvailableURL: !(address?.isFree ?? false),
            defaultAnnotationAsPrimaryFallback: isBlank
        )
    }

    /// WordPress.com applies the mobile starter design only to the `mobile` flow, which it assigns to requests
    /// without a name. Any other name skips the design and, with the default annotation fallback, yields what web
    /// onboarding creates: a blank site on the current default theme with its starter content. The short flow sends
    /// its own name instead of `onboarding` because WordPress.com stores the name on the site for attribution.
    private var requestFlowName: String? {
        switch flow {
        case .current: address == nil ? Strings.siteCreationFlowForNoAddress : nil
        case .short: flow.name
        }
    }

    var hasSiteTitle: Bool {
        information?.title != nil
    }

    /// Checks if the Domain Purchasing Feature Flag and AB Experiment are enabled
    var domainPurchasingEnabled: Bool {
        RemoteFeatureFlag.plansInSiteCreation.enabled()
    }

    /// Flag indicating whether the checkout flow should appear or not.
    var shouldShowCheckout: Bool {
        domainPurchasingEnabled && planId != nil
    }

    /// Returns domain name selected in plan seletion
    /// - otherwise the domain suggestion selected in domain view if there's one,
    /// - otherwise a site name if there's one,
    /// - otherwise an empty string.
    private var siteURLString: String {
        guard let domainName = addressFromPlanSelection ?? address?.domainName else {
            return information?.title ?? ""
        }

        return domainName.isWordPress ? domainName.subdomain : domainName
    }

    private enum Strings {
        static let defaultDesignSlug = "default"
        static let siteCreationFlowForNoAddress = "with-design-picker"
    }
}

// MARK: - Helper Extensions

private extension String {
    var subdomain: String {
        return components(separatedBy: ".").first ?? ""
    }

    var isWordPress: Bool {
        return contains("wordpress.com")
    }
}

extension DomainSuggestion {
    var subdomain: String {
        return domainName.subdomain
    }

    var isWordPress: Bool {
        return domainName.isWordPress
    }
}
