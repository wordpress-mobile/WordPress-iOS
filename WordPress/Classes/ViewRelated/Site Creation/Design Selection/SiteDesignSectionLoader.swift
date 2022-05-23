import Foundation
import WordPressKit

struct SiteDesignSectionLoader {

    static func fetchSections(vertical: SiteIntentVertical?, completion: @escaping (Result<[SiteDesignSection], Error>) -> Void) {
        typealias TemplateGroup = SiteDesignRequest.TemplateGroup
        let templateGroups: [TemplateGroup] = [.stable, .singlePage]

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
                let sections = assembleSections(remoteDesigns: designs, vertical: vertical)
                completion(.success(sections))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Returns designs whose `group` property contains a vertical's slug.
    /// - Parameters:
    ///   - vertical: `SiteIntentVertical`
    ///   - remoteDesigns: `RemoteSiteDesigns`
    /// - Returns: Optional `SiteDesignSection`
    static func getSectionForVerticalSlug(_ vertical: SiteIntentVertical, remoteDesigns: RemoteSiteDesigns) -> SiteDesignSection? {
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
            title: String(format: TextContent.recommendedTitle, vertical.localizedTitle)
        )
    }


    /// Assembles Site Design sections by placing a single larger recommended section above regular sections.
    ///
    /// - If designs aren't found for a supplied vertical, it will attempt to find designs for a fallback category.
    /// - If designs aren't found for the fallback category, the recommended section won't be included.
    /// - If there are no designs for a category, it won't be included.
    /// - Parameters:
    ///   - remoteDesigns: `RemoteSiteDesigns`
    ///   - vertical: Optional `SiteIntentVertical`
    /// - Returns: Array of `SiteDesignSection`s
    static func assembleSections(remoteDesigns: RemoteSiteDesigns, vertical: SiteIntentVertical?) -> [SiteDesignSection] {
        let categorySections = remoteDesigns.categories.map { category in
            SiteDesignSection(
                category: category,
                designs: remoteDesigns.designs.filter {
                    $0.categories.map { $0.slug }.contains(category.slug)
                },
                thumbnailSize: SiteDesignCategoryThumbnailSize.category.value
            )
        }.filter { !$0.designs.isEmpty }

        if let vertical = vertical, let recommendedVertical = getSectionForVerticalSlug(vertical, remoteDesigns: remoteDesigns) {
            // Recommended designs for the vertical were found
            return [recommendedVertical] + categorySections
        }

        if var recommendedFallback = categorySections.first(where: { $0.categorySlug.lowercased() == "blog" }) {
            // Recommended designs for the vertical weren't found, so we used the fallback category
            recommendedFallback.title = String(format: TextContent.recommendedTitle, "Blogging")
            recommendedFallback.thumbnailSize = SiteDesignCategoryThumbnailSize.recommended.value
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
