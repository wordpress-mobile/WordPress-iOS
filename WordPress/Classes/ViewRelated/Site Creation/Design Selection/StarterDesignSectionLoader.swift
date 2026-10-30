import Foundation
import WordPressKit

/// Builds the starter design picker's sections from WordPress.com's web starter design catalog.
///
/// This picker deliberately uses a different catalog from the site creation design step. The creation step's mobile
/// catalog (`common-starter-site-designs?type=mobile`) only works at creation time: WordPress.com applies a mobile
/// design through a server-side annotation that writes the home page, front page settings, and theme options, and no
/// endpoint applies that annotation to an existing site. Activating a mobile design's theme alone would give the site
/// a layout that does not match its preview. A web starter design is a block theme whose theme is the design, so
/// activating the theme on an existing site reproduces it, which is how the web applies these designs too.
struct StarterDesignSectionLoader {
    let api: WordPressComRestApi
    /// The site's title, shown in the previews.
    let siteTitle: String?
    /// The site's language slug, for example `en`, used to localize the previews.
    let language: String

    /// - Parameter scale: Unused: the catalog's screenshots come at one fixed size.
    func buildAssembler(
        scale _: CGFloat,
        completion: @escaping (Result<SiteDesignSectionLoader.Assembler, Error>) -> Void
    ) {
        Task { @MainActor in
            do {
                let designs = try await StarterDesignServiceRemote(wordPressComRestApi: api).fetchStarterDesigns()
                let sections = Self.sections(from: designs, siteTitle: siteTitle, language: language)
                // The web catalog has no designs per site intent, so the sections ignore the vertical.
                completion(.success({ _ in sections }))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// One section per catalog category, in the order categories first appear in the catalog.
    ///
    /// Only free designs are offered. Virtual designs are left out: they combine a theme with a pattern recipe, so
    /// activating their theme does not produce what their preview shows.
    static func sections(from designs: [StarterDesign], siteTitle: String?, language: String) -> [SiteDesignSection] {
        var categories: [StarterDesign.Category] = []
        var designsByCategory: [String: [RemoteSiteDesign]] = [:]
        for design in designs where design.themeTier == "free" && !design.isVirtual {
            let siteDesign = siteDesign(from: design, siteTitle: siteTitle, language: language)
            for category in design.categories {
                if designsByCategory[category.slug] == nil {
                    categories.append(category)
                }
                designsByCategory[category.slug, default: []].append(siteDesign)
            }
        }

        return categories.map { category in
            SiteDesignSection(
                designs: designsByCategory[category.slug] ?? [],
                categorySlug: category.slug,
                title: category.name,
                hasLandscapeThumbnails: true
            )
        }
    }

    /// The web catalog only has desktop screenshots, so every preview device uses the same one.
    ///
    /// The sections group designs by category, so the design's own categories go unused and are left empty.
    static func siteDesign(from design: StarterDesign, siteTitle: String?, language: String) -> RemoteSiteDesign {
        RemoteSiteDesign(
            slug: design.slug,
            title: design.title,
            demoURL: previewURL(for: design, siteTitle: siteTitle, language: language),
            screenshot: design.screenshot,
            mobileScreenshot: design.screenshot,
            tabletScreenshot: design.screenshot,
            themeSlug: design.themeID,
            group: nil,
            segmentID: nil,
            categories: []
        )
    }

    /// The web's design preview renderer, which shows the design with the site's title and language.
    static func previewURL(for design: StarterDesign, siteTitle: String?, language: String) -> String {
        var components = URLComponents(string: "https://public-api.wordpress.com/wpcom/v2/block-previews/site")!
        let title = siteTitle.flatMap { $0.isEmpty ? nil : $0 } ?? design.title
        components.queryItems = [
            URLQueryItem(name: "stylesheet", value: design.stylesheet),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "site_title", value: title)
        ]
        return components.url?.absoluteString ?? ""
    }
}
