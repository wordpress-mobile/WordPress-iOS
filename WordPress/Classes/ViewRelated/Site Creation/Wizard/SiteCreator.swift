
import Foundation

// MARK: - SiteCreatorOutputError

enum SiteCreatorOutputError: Error {
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
    func build() throws -> SiteCreatorOutput {

        guard let segmentIdentifier = segment?.identifier else {
            throw SiteCreatorOutputError.invalidSegmentIdentifier
        }

        guard let verticalIdentifier = vertical?.identifier.description else {
            throw SiteCreatorOutputError.invalidVerticalIdentifier
        }

        guard let domainSuggestion = address else {
            throw SiteCreatorOutputError.invalidDomain
        }

        guard let siteInformation = information else {
            throw SiteCreatorOutputError.invalidSiteInformation
        }

        let output = SiteCreatorOutput(
            segmentIdentifier: segmentIdentifier,
            verticalIdentifier: verticalIdentifier,
            tagline: siteInformation.tagLine ?? "",     // Tagline input can be skipped
            isPublic: true,
            languageIdentifier: WordPressComLanguageDatabase().deviceLanguageIdNumber().stringValue,
            shouldValidate: true,
            siteURLString: domainSuggestion.domainName,
            title: siteInformation.title                // Title input can be skipped
        )

        return output
    }
}
