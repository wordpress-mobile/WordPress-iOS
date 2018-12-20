
import Foundation

/// The final output of the site creation wizard, is an encodable model object that can be submitted to the backend.
/// This is intended for use in conjunction with `EnhancedSiteCreationService`.
///
struct SiteCreatorOutput {

    // MARK: Properties (New / Enhanced)

    /// Maps to `site_segment`
    let segmentIdentifier: Int64

    /// Maps to `site_vertical`
    let verticalIdentifier: Int64

    /// Maps to `site_tagline`
    let tagline: String

    // MARK: Legacy properties

    /// Maps to `public`
    let isPublic: Bool

    /// Maps to `lang_id`
    let languageIdentifier: String

    /// Maps to `validate`
    let shouldValidate: Bool

    /// Maps to `blog_name`
    let siteURLString: String

    /// Maps to `blog_title`
    let title: String
}
