
import Foundation
import WordPressKit

extension DomainSuggestion {
    var subdomain: String {
        return domainName.components(separatedBy: ".").first ?? ""
    }

    var isWordPress: Bool {
        return domainName.contains("wordpress.com")
    }
}

// MARK: - SiteCreationRequestAssemblyError

enum SiteCreationRequestAssemblyError: Error {
    case invalidSegmentIdentifier
    case invalidVerticalIdentifier
    case invalidDomain
}

// MARK: - SiteCreator

// Tracks data state shared between Site Creation Wizard Steps. I am not too fond of the name, but it kind of works for now.
final class SiteCreator {

    // MARK: Properties
    var segment: SiteSegment?
    var design: RemoteSiteDesign?
    var vertical: SiteIntentVertical?
    var information: SiteInformation?
    var address: DomainSuggestion?

    /// Generates the final object that will be posted to the backend
    ///
    /// - Returns: an Encodable object
    ///
    func build() throws -> SiteCreationRequest {

        guard let siteName = siteName else {
            throw SiteCreationRequestAssemblyError.invalidDomain
        }

        let siteDesign = design?.slug ?? Strings.defaultDesignSlug

        let request = SiteCreationRequest(
            segmentIdentifier: segment?.identifier,
            siteDesign: siteDesign,
            verticalIdentifier: vertical?.slug,
            title: information?.title ?? Strings.defaultSiteTitle,
            tagline: information?.tagLine ?? "",
            siteURLString: siteName,
            isPublic: true,
            siteCreationFlow: address == nil ? Strings.siteCreationFlowForNoAddress : nil,
            findAvailableUrl: address == nil
        )

        return request
    }

    /// Returns the domain suggestion if there's one,
    /// - otherwise a site name if there's one,
    /// - otherwise the account name if there's one,
    /// - otherwise nil.
    private var siteName: String? {

        guard let domainSuggestion = address else {
            let accountService = AccountService(managedObjectContext: ContextManager.shared.mainContext)
            return information?.title ?? accountService.defaultWordPressComAccount()?.displayName
        }

        return domainSuggestion.isWordPress ? domainSuggestion.subdomain : domainSuggestion.domainName
    }

    private enum Strings {
        static let defaultDesignSlug = "default"
        static let defaultSiteTitle = NSLocalizedString("Site Title", comment: "Site info. Title")
        static let siteCreationFlowForNoAddress = "with-design-picker"
    }
}
