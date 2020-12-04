
import Foundation
import WordPressKit

// MARK: SiteCreationRequest

extension SiteCreationRequest {

    // MARK: Unvalidated

    /// Convenience initializer, which applies sensible defaults for language ID, client ID & client secret.
    /// The request is marked as pending validation.
    ///
    /// - Parameters:
    ///   - segmentIdentifier: the segment ID for the pending site
    ///   - siteDesign: the starter site's slug for the pending site
    ///   - verticalIdentifier: the vertical ID for the pending site
    ///   - title: title of the pending site for the pending site
    ///   - tagline: tagline for the pending site
    ///   - siteURLString: the URL string for the pending site
    ///   - isPublic: whether or not the pending site should be public
    ///
    init(segmentIdentifier: Int64?,
         siteDesign: String?,
         verticalIdentifier: String?,
         title: String,
         tagline: String?,
         siteURLString: String,
         isPublic: Bool) {

        self.init(segmentIdentifier: segmentIdentifier,
                  siteDesign: siteDesign,
                  verticalIdentifier: verticalIdentifier,
                  title: title,
                  tagline: tagline,
                  siteURLString: siteURLString,
                  isPublic: true,
                  languageIdentifier: WordPressComLanguageDatabase().deviceLanguageIdNumber().stringValue,
                  shouldValidate: true,
                  clientIdentifier: ApiCredentials.client(),
                  clientSecret: ApiCredentials.secret()
        )
    }

    // MARK: Validated

    /// Convenience initializer, intended to mark a pending site creation as previously validated.
    ///
    /// - Parameter request: the original request for the pending site
    ///
    init(request: SiteCreationRequest) {
        self.init(segmentIdentifier: request.segmentIdentifier,
                  siteDesign: request.siteDesign,
                  verticalIdentifier: request.verticalIdentifier,
                  title: request.title,
                  tagline: request.tagline,
                  siteURLString: request.siteURLString,
                  isPublic: request.isPublic,
                  languageIdentifier: request.languageIdentifier,
                  shouldValidate: false,
                  clientIdentifier: request.clientIdentifier,
                  clientSecret: request.clientSecret
        )
    }
}
