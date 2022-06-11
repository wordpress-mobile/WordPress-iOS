import Foundation
import WordPressKit

struct SiteDesignSectionLoader {
    typealias Assembler = ((SiteIntentVertical?) -> [SiteDesignSection])

    /// Builds a site design section assembler based on data fetched from the API.
    ///
    /// - Parameter completion: A closure providing an assembler function or an error.
    static func buildAssembler(completion: @escaping (Result<Assembler, Error>) -> Void) {
        fetchRemoteDesigns { result in
            switch result {
            case .success(let remoteDesigns):
                let categorySections = getCategorySectionsForRemoteSiteDesigns(remoteDesigns)

                completion(.success({ vertical in
                    assembleSections(
                        categorySections: categorySections,
                        remoteDesigns: remoteDesigns,
                        vertical: vertical
                    )
                }))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Fetches remote designs from the API
    ///
    /// - Parameter completion: A closure providing remote site designs or an error.
    static func fetchRemoteDesigns(completion: @escaping (Result<RemoteSiteDesigns, Error>) -> Void) {
        typealias TemplateGroup = SiteDesignRequest.TemplateGroup
        let templateGroups: [TemplateGroup] = FeatureFlag.betaSiteDesigns.enabled ? [.stable, .beta] : []

        let restAPI = WordPressComRestApi.anonymousApi(
            userAgent: WPUserAgent.wordPress(),
            localeKey: WordPressComRestApi.LocaleKeyV2
        )

        let request = SiteDesignRequest(
            withThumbnailSize: SiteDesignCategoryThumbnailSize.category.value,
            withGroups: templateGroups
        )

        SiteDesignServiceRemote.fetchSiteDesigns(restAPI, request: request) { result in
            switch result {
            case .success(let designs):
                completion(.success(designs))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Returns a single recommended section of designs whose `group` property contains a vertical's slug.
    ///
    /// - Parameters:
    ///   - vertical: A Site Intent vertical.
    ///   - remoteDesigns: Remote Site Designs.
    /// - Returns: A `SiteDesignSection` if there was a match, otherwise `nil`.
    static func getRecommendedSectionForVertical(_ vertical: SiteIntentVertical, remoteDesigns: RemoteSiteDesigns) -> SiteDesignSection? {
        let designsForVertical = remoteDesigns.designs.filter({
            $0.group?
                .map { $0.lowercased() }
                .contains(vertical.slug.lowercased()) ?? false
        })

        guard !designsForVertical.isEmpty else {
            return nil
        }

        return SiteDesignSection(
            designs: designsForVertical,
            thumbnailSize: SiteDesignCategoryThumbnailSize.recommended.value,
            caption: TextContent.recommendedCaption,
            categorySlug: "recommended_" + vertical.slug,
            title: String(format: TextContent.recommendedTitle, vertical.localizedTitle),
            sectionType: .recommended
        )
    }

    /// Gets `SiteDesignSection`s for the supplied `RemoteSiteDesigns`
    ///
    /// - If there are no designs for a category, it won't be included.
    /// - Order of designs for each category are randomized, but the order of categories is not.
    ///
    /// - Parameter remoteDesigns: Remote Site Designs.
    /// - Returns: Array of Site Design sections with the designs randomized.
    static func getCategorySectionsForRemoteSiteDesigns(_ remoteDesigns: RemoteSiteDesigns) -> [SiteDesignSection] {
        return remoteDesigns.categories.map { category in
            SiteDesignSection(
                category: category,
                designs: remoteDesigns.randomizedDesignsForCategory(category),
                thumbnailSize: SiteDesignCategoryThumbnailSize.category.value
            )
        }.filter { !$0.designs.isEmpty }
    }

    /// Assembles Site Design sections by placing a single larger recommended section above category sections.
    ///
    /// - If designs aren't found for a supplied vertical, it will attempt to find designs for a fallback category.
    /// - If designs aren't found for the fallback category, the recommended section won't be included.
    ///
    /// - Parameters:
    ///   - remoteDesigns: Remote Site Designs.
    ///   - vertical: An optional Site Intent vertical.
    /// - Returns: An array of Site Design sections.
    static func assembleSections(categorySections: [SiteDesignSection], remoteDesigns: RemoteSiteDesigns, vertical: SiteIntentVertical?) -> [SiteDesignSection] {
        if let vertical = vertical, let recommendedVertical = getRecommendedSectionForVertical(vertical, remoteDesigns: remoteDesigns) {
            // Recommended designs for the vertical were found
            return [recommendedVertical] + categorySections
        }

        if var recommendedFallback = categorySections.first(where: { $0.categorySlug.lowercased() == "blog" }) {
            // Recommended designs for the vertical weren't found, so we used the fallback category
            recommendedFallback.title = String(format: TextContent.recommendedTitle, "Blogging")
            recommendedFallback.thumbnailSize = SiteDesignCategoryThumbnailSize.recommended.value
            recommendedFallback.sectionType = .recommended
            recommendedFallback.caption = TextContent.recommendedCaption
            return [recommendedFallback] + categorySections.filter { $0 != recommendedFallback }
        }

        // No recommended designs were found
        return categorySections
    }
}

private extension SiteDesignSectionLoader {

    enum TextContent {
        static let recommendedTitle = NSLocalizedString("Best for %@",
                                                        comment: "Title for a section of recommended site designs. The %@ will be replaced with the related site intent topic, such as Food or Blogging.")
        static let recommendedCaption = NSLocalizedString("PICKED FOR YOU",
                                                          comment: "Caption for the recommended sections in site designs.")
    }
}
