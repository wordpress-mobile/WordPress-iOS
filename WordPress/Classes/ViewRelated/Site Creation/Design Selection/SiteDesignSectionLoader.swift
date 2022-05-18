import Foundation
import WordPressKit

struct SiteDesignSectionLoader {
    static func fetchSections(vertical: SiteIntentVertical?) async throws -> [SiteDesignSection] {
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

        return try await withCheckedThrowingContinuation { continuation in
            SiteDesignServiceRemote.fetchSiteDesigns(restAPI, request: request) { result in
                switch result {
                case .success(let designs):
                    let sections = assembleSections(remoteDesigns: designs, vertical: vertical)
                    continuation.resume(with: .success(sections))
                case .failure(let error):
                    continuation.resume(with: .failure(error))
                }
            }
        }
    }

    static func getSectionForVerticalSlug(_ vertical: SiteIntentVertical, remoteDesigns: RemoteSiteDesigns) -> SiteDesignSection? {
        let designsForVertical = remoteDesigns.designs.filter({
            $0.groups?
                .map { $0.lowercased() }
                .contains(vertical.slug.lowercased()) ?? false
        })

        guard !designsForVertical.isEmpty else {
            return nil
        }

        return SiteDesignSection(
            designs: designsForVertical,
            thumbnailSize: SiteDesignCategoryThumbnailSize.recommended.value,
            categorySlug: "recommended_" + vertical.slug,
            title: "Best for \(vertical.localizedTitle)" // TODO - localization
        )
    }

    static func assembleSections(remoteDesigns: RemoteSiteDesigns, vertical: SiteIntentVertical?) -> [SiteDesignSection] {
        let categorySections = remoteDesigns.categories.map { category in
            SiteDesignSection(
                category: category,
                designs: remoteDesigns.designs.filter { design in design.categories.map({$0.slug}).contains(category.slug) },
                thumbnailSize: SiteDesignCategoryThumbnailSize.category.value
            )
        }

        if let vertical = vertical, let recommendedVertical = getSectionForVerticalSlug(vertical, remoteDesigns: remoteDesigns) {
            // Recommended designs for the vertical were found
            return [recommendedVertical] + categorySections
        }

        if var recommendedFallback = categorySections.first(where: { $0.categorySlug.lowercased() == "blog" }) {
            // Recommended designs for the vertical weren't found, so we used the fallback category
            recommendedFallback.title = "Best for Blogging" // TODO - localization
            recommendedFallback.thumbnailSize = SiteDesignCategoryThumbnailSize.recommended.value
            return [recommendedFallback] + categorySections.filter { $0 != recommendedFallback }
        }

        // No recommended designs were found
        return categorySections
    }
}
