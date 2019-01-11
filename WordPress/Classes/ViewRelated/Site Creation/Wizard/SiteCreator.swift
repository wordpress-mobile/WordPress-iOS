
import Foundation

// MARK: - SiteCreationRequestAssemblyError

enum SiteCreationRequestAssemblyError: Error {
    case invalidSegmentIdentifier
    case invalidVerticalIdentifier
    case invalidDomain
    case invalidSiteInformation
}

// MARK: - SiteCreator

// Tracks data state shared between Site Creation Wizard Steps. I am not too fond of the name, but it kind of works for now.
final class SiteCreator {

    // MARK: Properties

    var segment: SiteSegment?

    var vertical: SiteVertical?

    var information: SiteInformation?

    var address: DomainSuggestion?

    /// Generates the final object that will be posted to the backend
    ///
    /// - Returns: an Encodable object
    ///
    func build() throws -> SiteCreationRequest {

        guard let segmentIdentifier = segment?.identifier else {
            throw SiteCreationRequestAssemblyError.invalidSegmentIdentifier
        }

        guard let verticalIdentifier = vertical?.identifier.description else {
            throw SiteCreationRequestAssemblyError.invalidVerticalIdentifier
        }

        guard let domainSuggestion = address else {
            throw SiteCreationRequestAssemblyError.invalidDomain
        }
        let siteName = domainSuggestion.domainName

        guard let siteInformation = information else {
            throw SiteCreationRequestAssemblyError.invalidSiteInformation
        }

        let request = SiteCreationRequest(
            segmentIdentifier: segmentIdentifier,
            verticalIdentifier: verticalIdentifier,
            title: siteInformation.title,
            tagline: siteInformation.tagLine,
            siteURLString: siteName,
            isPublic: true
        )

        return request
    }
}
