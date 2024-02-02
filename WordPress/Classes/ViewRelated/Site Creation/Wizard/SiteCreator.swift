
import Foundation
import WordPressKit

// MARK: - SiteCreator

// Tracks data state shared between Site Creation Wizard Steps. I am not too fond of the name, but it kind of works for now.
final class SiteCreator {

    // MARK: Properties
    var segment: SiteSegment?
    var design: RemoteSiteDesign?
    var vertical: SiteIntentVertical?
    var information: SiteInformation?
    var address: DomainSuggestion?
    var planId: Int?
    /// Users can opt for a free domain name in Plans selection
    var addressFromPlanSelection: String?

    /// Generates the final object that will be posted to the backend
    ///
    /// - Returns: an Encodable object
    ///
    func build() -> SiteCreationRequest {

        let request = SiteCreationRequest(
            segmentIdentifier: segment?.identifier,
            siteDesign: design?.slug ?? Strings.defaultDesignSlug,
            verticalIdentifier: vertical?.slug,
            title: information?.title ?? "",
            tagline: information?.tagLine ?? "",
            siteURLString: siteURLString,
            isPublic: true,
            siteCreationFlow: address == nil ? Strings.siteCreationFlowForNoAddress : nil,
            findAvailableURL: !(address?.isFree ?? false)
        )
        return request
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

extension String {
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
