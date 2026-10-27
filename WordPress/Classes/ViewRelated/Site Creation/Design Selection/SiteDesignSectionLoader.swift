import Foundation
import UIKit
import WordPressKit
import WordPressShared
import WordPressSharedUI

struct SiteDesignSectionLoader {
    /// Lays the fetched designs out for a vertical, at the thumbnail sizes for a window's horizontal
    /// size class. The designs keep the order they were shuffled into when they were fetched.
    typealias Assembler = ((SiteIntentVertical?, UIUserInterfaceSizeClass) -> [SiteDesignSection])

    /// Builds a site design section assembler based on data fetched from the API.
    ///
    /// - Parameters:
    ///   - scale: The native scale of the screen that will display the thumbnails,
    ///     for example `view.window?.windowScene?.screen.nativeScale`.
    ///   - windowSizeClass: The horizontal size class of the window that will display the thumbnails.
    ///     The API renders the previews at the thumbnail size for it.
    ///   - completion: A closure providing an assembler function or an error.
    static func buildAssembler(
        scale: CGFloat,
        windowSizeClass: UIUserInterfaceSizeClass,
        completion: @escaping (Result<Assembler, Error>) -> Void
    ) {
        fetchRemoteDesigns(scale: scale, windowSizeClass: windowSizeClass) { result in
            switch result {
            case .success(let remoteDesigns):
                let categorySections = getCategorySectionsForRemoteSiteDesigns(
                    remoteDesigns,
                    windowSizeClass: windowSizeClass
                )

                completion(
                    .success({ vertical, windowSizeClass in
                        assembleSections(
                            categorySections: categorySections,
                            remoteDesigns: remoteDesigns,
                            vertical: vertical,
                            windowSizeClass: windowSizeClass
                        )
                    })
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Fetches remote designs from the API
    ///
    /// - Parameters:
    ///   - scale: The native scale of the screen that will display the thumbnails,
    ///     for example `view.window?.windowScene?.screen.nativeScale`.
    ///   - windowSizeClass: The horizontal size class of the window that will display the thumbnails.
    ///   - completion: A closure providing remote site designs or an error.
    static func fetchRemoteDesigns(
        scale: CGFloat,
        windowSizeClass: UIUserInterfaceSizeClass,
        completion: @escaping (Result<RemoteSiteDesigns, Error>) -> Void
    ) {
        typealias TemplateGroup = SiteDesignRequest.TemplateGroup
        let templateGroups: [TemplateGroup] = FeatureFlag.betaSiteDesigns.enabled ? [.stable, .beta] : []

        let restAPI = WordPressComRestApi.anonymousApi(
            userAgent: WPUserAgent.wordPress(),
            localeKey: WordPressComRestApi.LocaleKeyV2
        )

        let request = SiteDesignRequest(
            withThumbnailSize: SiteDesignCategoryThumbnailSize.recommended.value(for: windowSizeClass),
            scale: scale,
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
    ///   - windowSizeClass: The horizontal size class of the window that will display the thumbnails.
    /// - Returns: A `SiteDesignSection` if there was a match, otherwise `nil`.
    static func getRecommendedSectionForVertical(
        _ vertical: SiteIntentVertical,
        remoteDesigns: RemoteSiteDesigns,
        windowSizeClass: UIUserInterfaceSizeClass
    ) -> SiteDesignSection? {
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
            thumbnailSize: SiteDesignCategoryThumbnailSize.recommended.value(for: windowSizeClass),
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
    /// - Parameters:
    ///   - remoteDesigns: Remote Site Designs.
    ///   - windowSizeClass: The horizontal size class of the window that will display the thumbnails.
    /// - Returns: Array of Site Design sections with the designs randomized.
    static func getCategorySectionsForRemoteSiteDesigns(
        _ remoteDesigns: RemoteSiteDesigns,
        windowSizeClass: UIUserInterfaceSizeClass
    ) -> [SiteDesignSection] {
        return remoteDesigns.categories.map { category in
            SiteDesignSection(
                category: category,
                designs: remoteDesigns.randomizedDesignsForCategory(category),
                thumbnailSize: SiteDesignCategoryThumbnailSize.category.value(for: windowSizeClass)
            )
        }.filter { !$0.designs.isEmpty }
    }

    /// Assembles Site Design sections by placing a single larger recommended section above category sections.
    ///
    /// - If designs aren't found for a supplied vertical, it will attempt to find designs for a fallback category.
    /// - If designs aren't found for the fallback category, the recommended section won't be included.
    /// - Every section gets the thumbnail size for `windowSizeClass`, whatever size the category sections were
    ///   built with, so the same category sections can be laid out again after the size class changes.
    ///
    /// - Parameters:
    ///   - remoteDesigns: Remote Site Designs.
    ///   - vertical: An optional Site Intent vertical.
    ///   - windowSizeClass: The horizontal size class of the window that will display the thumbnails.
    /// - Returns: An array of Site Design sections.
    static func assembleSections(
        categorySections: [SiteDesignSection],
        remoteDesigns: RemoteSiteDesigns,
        vertical: SiteIntentVertical?,
        windowSizeClass: UIUserInterfaceSizeClass
    ) -> [SiteDesignSection] {
        let categoryThumbnailSize = SiteDesignCategoryThumbnailSize.category.value(for: windowSizeClass)
        let categorySections = categorySections.map { section in
            var section = section
            section.thumbnailSize = categoryThumbnailSize
            return section
        }

        if let vertical,
            let recommendedVertical = getRecommendedSectionForVertical(
                vertical,
                remoteDesigns: remoteDesigns,
                windowSizeClass: windowSizeClass
            )
        {
            // Recommended designs for the vertical were found
            return [recommendedVertical] + categorySections
        }

        if var recommendedFallback = categorySections.first(where: { $0.categorySlug.lowercased() == "blog" }) {
            // Recommended designs for the vertical weren't found, so we used the fallback category
            recommendedFallback.title = String(format: TextContent.recommendedTitle, "Blogging")
            recommendedFallback.thumbnailSize = SiteDesignCategoryThumbnailSize.recommended.value(for: windowSizeClass)
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
